/*
 * Kinex HAND bridge — ESP32-S3 (Mini)
 * -----------------------------------
 * Second Kinex board (alongside the Leg board "Kinex-EMG"). Reads an MPU6050
 * over I2C and streams the HAND TILT ANGLES on all three axes (X/Y/Z) to the
 * Kinex app over BLE — view them live in the app's BLE Debug console. Every
 * value is also printed to Serial (tab-separated) for the Arduino Serial Plotter.
 * Angles only: raw acceleration is never sent.
 *
 * The app can hold this board AND the Leg board connected at the same time:
 * this one advertises as "Kinex-Hand", the Leg board as "Kinex-EMG", so the
 * app's two device slots each connect to their own board.
 *
 * ── MPU6050 wiring (I2C) ─────────────────────────────────────────────────────
 *   MPU6050 VCC -> 3V3        MPU6050 GND -> GND
 *   MPU6050 SDA -> GPIO SDA_PIN   MPU6050 SCL -> GPIO SCL_PIN   (set below)
 *   AD0 left unconnected/low  -> I2C address 0x68.
 *   NOTE: ESP32-S3 has no fixed I2C pins — set SDA_PIN/SCL_PIN to whatever you
 *   wired. Defaults below (8/9) are common on S3 Mini boards; change if needed.
 *
 * ── Protocol (Nordic UART Service — same UUIDs the app already uses) ─────────
 *   App  -> ESP32 (write):
 *     STREAM:ON   begin the tilt stream            STREAM:OFF  stop it
 *     ZERO        set the current Z (yaw) angle as 0
 *     (the board also auto-starts the stream on connect, so the debugger shows
 *      tilt immediately without typing anything.)
 *   ESP32 -> App (notify), one message per line:
 *     TILT:<x>,<y>,<z>   one sample, degrees, 1 decimal (e.g. TILT:-3.4,12.7,88.2)
 *                        x = roll  — tilt left/right      (from gravity)
 *                        y = pitch — tilt forward/back    (from gravity)
 *                        z = yaw   — rotation about vertical (from gyro)
 *     READY              idle heartbeat (link alive, not streaming)
 *     ERR:MPU            MPU6050 not responding on I2C
 *
 * ── Why Z behaves differently ───────────────────────────────────────────────
 *   X and Y are absolute: they are measured against gravity, so they never
 *   drift and are correct the instant the board powers on. Gravity gives no
 *   reference for rotation ABOUT the vertical axis, and the MPU6050 has no
 *   magnetometer, so Z is integrated from the gyro instead. That makes Z
 *   RELATIVE (0 = wherever the board was at boot / at the last ZERO) and it
 *   creeps by roughly a degree per minute even while held still. Gyro bias is
 *   measured at boot to keep that small — hold the board STILL for the first
 *   second after power-up. Send ZERO to re-datum it at any time.
 *
 * Board:  ESP32-S3 (e.g. "ESP32S3 Dev Module" / S3 Mini) — Arduino-ESP32 core.
 * Library: built-in "BLE" (BLEDevice.h) + built-in Wire.h. No extra install.
 *
 * ── Serial Monitor blank on ESP32-S3? ───────────────────────────────────────
 *   Set Tools -> "USB CDC On Boot" = ENABLED, re-upload, open monitor @115200.
 */

#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ── Nordic UART Service UUIDs (must match the Flutter app) ──────────────────
#define NUS_SERVICE   "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define NUS_RX_WRITE  "6e400002-b5a3-f393-e0a9-e50e24dcca9e"  // app -> ESP32
#define NUS_TX_NOTIFY "6e400003-b5a3-f393-e0a9-e50e24dcca9e"  // ESP32 -> app

const char* DEVICE_NAME = "Kinex-Hand";   // app Hand-slot matches "Kinex-Hand"

// ── MPU6050 (I2C) ────────────────────────────────────────────────────────────
const int  SDA_PIN     = 8;      // <-- set to your wiring
const int  SCL_PIN     = 9;      // <-- set to your wiring
const uint8_t MPU_ADDR = 0x68;   // AD0 low. Use 0x69 if AD0 tied high.

// MPU6050 registers
const uint8_t REG_PWR_MGMT_1 = 0x6B;
const uint8_t REG_ACCEL_XOUT = 0x3B;
const uint8_t REG_GYRO_ZOUT  = 0x47;
const float   ACCEL_LSB_PER_G   = 16384.0f;  // ±2g   default full-scale range
const float   GYRO_LSB_PER_DPS  = 131.0f;    // ±250 °/s default full-scale range

// ── Timing ──────────────────────────────────────────────────────────────────
const unsigned long SAMPLE_INTERVAL_MS = 33;    // 30 Hz tilt stream
const unsigned long HEARTBEAT_MS       = 2000;  // idle "alive" ping

// ── State ────────────────────────────────────────────────────────────────────
BLEServer*         server          = nullptr;
BLECharacteristic* txChar          = nullptr;   // notify (ESP32 -> app)
bool               deviceConnected = false;
bool               streaming       = false;      // sending TILT samples
bool               mpuOk           = false;
unsigned long      lastSample      = 0;
unsigned long      lastHeartbeat   = 0;

// Z (yaw) is integrated from the gyro, so it needs its own running state.
float         yaw          = 0.0f;   // degrees since boot / last ZERO
float         gyroZBias    = 0.0f;   // LSB offset measured while still at boot
unsigned long lastYawMicros = 0;     // 0 = no previous sample to integrate over

// ── Send one line up to the app over BLE notify ─────────────────────────────
void notifyApp(const String& line) {
  if (!deviceConnected || txChar == nullptr) return;
  txChar->setValue((uint8_t*)line.c_str(), line.length());
  txChar->notify();
}

// ── MPU6050 helpers (raw I2C, no external library) ──────────────────────────
bool mpuWrite(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  return Wire.endTransmission() == 0;
}

bool mpuWake() {
  // Clear SLEEP bit in PWR_MGMT_1 so the sensor starts sampling.
  return mpuWrite(REG_PWR_MGMT_1, 0x00);
}

// Read the 3 accelerometer axes (raw 16-bit signed). Returns false on I2C error.
bool readAccel(int16_t& ax, int16_t& ay, int16_t& az) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(REG_ACCEL_XOUT);
  if (Wire.endTransmission(false) != 0) return false;   // repeated start
  if (Wire.requestFrom((int)MPU_ADDR, 6) != 6) return false;
  ax = (int16_t)((Wire.read() << 8) | Wire.read());
  ay = (int16_t)((Wire.read() << 8) | Wire.read());
  az = (int16_t)((Wire.read() << 8) | Wire.read());
  return true;
}

// Read the raw Z gyro axis (16-bit signed). Returns false on I2C error.
bool readGyroZ(int16_t& gz) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(REG_GYRO_ZOUT);
  if (Wire.endTransmission(false) != 0) return false;   // repeated start
  if (Wire.requestFrom((int)MPU_ADDR, 2) != 2) return false;
  gz = (int16_t)((Wire.read() << 8) | Wire.read());
  return true;
}

// Average the Z gyro while the board sits still, so the resting reading can be
// subtracted before integrating. Without this the yaw angle would run away by
// tens of degrees a minute.
void calibrateGyroZ() {
  const int samples = 200;
  long sum = 0;
  int  got = 0;
  for (int i = 0; i < samples; i++) {
    int16_t gz;
    if (readGyroZ(gz)) { sum += gz; got++; }
    delay(5);
  }
  gyroZBias = got > 0 ? (float)sum / got : 0.0f;
  Serial.print("[MPU] gyro Z bias = ");
  Serial.println(gyroZBias, 1);
}

// All three tilt angles in degrees.
//   x (roll) / y (pitch) — absolute, straight off the gravity vector, no drift.
//   z (yaw)              — gravity says nothing about rotation about the
//                          vertical, so it is integrated from the gyro and is
//                          therefore relative to boot / the last ZERO.
bool readTilt(float& x, float& y, float& z) {
  int16_t rax, ray, raz, rgz;
  if (!readAccel(rax, ray, raz)) return false;
  if (!readGyroZ(rgz))           return false;

  const float ax = rax / ACCEL_LSB_PER_G;
  const float ay = ray / ACCEL_LSB_PER_G;
  const float az = raz / ACCEL_LSB_PER_G;
  x = atan2f(ay, az) * 180.0f / PI;
  y = atan2f(-ax, sqrtf(ay * ay + az * az)) * 180.0f / PI;

  // Integrate yaw over the real elapsed time, not the nominal sample interval,
  // so a hiccup in the loop doesn't quietly bend the angle.
  const unsigned long nowUs = micros();
  if (lastYawMicros != 0) {
    const float dt = (nowUs - lastYawMicros) / 1000000.0f;   // seconds
    yaw += ((rgz - gyroZBias) / GYRO_LSB_PER_DPS) * dt;
    // Keep it in -180..180 so the number stays readable over a long session.
    while (yaw >  180.0f) yaw -= 360.0f;
    while (yaw < -180.0f) yaw += 360.0f;
  }
  lastYawMicros = nowUs;
  z = yaw;
  return true;
}

// ── Stream control ───────────────────────────────────────────────────────────
void startStream() {
  streaming     = true;
  lastSample    = 0;
  lastYawMicros = 0;   // don't integrate across the idle gap
  Serial.println("[STREAM] on (tilt x/y/z)");
}

void stopStream() {
  if (!streaming) return;
  streaming = false;
  Serial.println("[STREAM] off");
}

// ── Command parsing (app -> ESP32) ──────────────────────────────────────────
void handleCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;
  Serial.print("[RX] ");
  Serial.println(cmd);

  if (cmd == "STREAM:ON")       startStream();
  else if (cmd == "STREAM:OFF") stopStream();
  else if (cmd == "ZERO") {
    yaw = 0.0f;                     // re-datum the drifting Z axis
    Serial.println("[YAW] zeroed");
  }
  else                          notifyApp("echo:" + cmd);  // unknown -> echo for debug
}

// ── BLE callbacks ────────────────────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override {
    deviceConnected = true;
    Serial.println("[BLE] app connected");
    startStream();   // auto-stream so the debugger shows tilt immediately
  }
  void onDisconnect(BLEServer* s) override {
    deviceConnected = false;
    streaming = false;
    Serial.println("[BLE] app disconnected — re-advertising");
    BLEDevice::startAdvertising();
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    handleCommand(String(c->getValue().c_str()));
  }
};

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("\nKinex HAND bridge (ESP32-S3) starting…");

  // I2C + MPU6050
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000);
  mpuOk = mpuWake();
  Serial.println(mpuOk ? "[MPU] MPU6050 awake" : "[MPU] MPU6050 NOT found — check wiring/pins");
  if (mpuOk) {
    Serial.println("[MPU] hold the board STILL — measuring gyro bias…");
    calibrateGyroZ();
  }
  Serial.println("x_roll\ty_pitch\tz_yaw");   // Serial Plotter header

  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(80);
  server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* svc = server->createService(NUS_SERVICE);

  txChar = svc->createCharacteristic(
      NUS_TX_NOTIFY, BLECharacteristic::PROPERTY_NOTIFY);
  txChar->addDescriptor(new BLE2902());

  BLECharacteristic* rxChar = svc->createCharacteristic(
      NUS_RX_WRITE,
      BLECharacteristic::PROPERTY_WRITE |
          BLECharacteristic::PROPERTY_WRITE_NR);
  rxChar->setCallbacks(new RxCallbacks());

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(NUS_SERVICE);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.print("[BLE] advertising as \"");
  Serial.print(DEVICE_NAME);
  Serial.println("\" — connect the Hand slot in the app.");
}

void loop() {
  const unsigned long now = millis();

  if (streaming) {
    if (now - lastSample >= SAMPLE_INTERVAL_MS) {
      lastSample = now;
      float x, y, z;
      if (readTilt(x, y, z)) {
        String line = "TILT:" + String(x, 1) + "," + String(y, 1) + "," +
                      String(z, 1);
        notifyApp(line);
        // Tab-separated for the Serial Plotter (3 traces: x, y, z).
        Serial.print(x, 1);
        Serial.print('\t');
        Serial.print(y, 1);
        Serial.print('\t');
        Serial.println(z, 1);
      } else if (deviceConnected) {
        notifyApp("ERR:MPU");
        Serial.println("[ERR] MPU read failed");
        // Try to re-wake in case it browned out / was re-plugged.
        mpuOk         = mpuWake();
        lastYawMicros = 0;   // drop the stale timestamp so yaw doesn't jump
      }
    }
  } else if (deviceConnected && now - lastHeartbeat >= HEARTBEAT_MS) {
    lastHeartbeat = now;
    notifyApp("READY");
    Serial.println("[HB] READY");
  }
}
