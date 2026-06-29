/*
 * Kinex EMG bridge — ESP32-C3 Super Mini
 * ----------------------------------------
 * BLE link between the Kinex Flutter app and the ESP32, used by the EMG
 * installation / MVC-calibration step.
 *
 * MOCK DATA stage: the sensor values are random for now (no analogRead yet) so
 * the 2-device workflow can be built and verified end-to-end. Every value is
 * sent over BLE AND printed to Serial, so you can confirm both ends match.
 *
 * ── Protocol (Nordic UART Service — same UUIDs the app already uses) ─────────
 *   App  -> ESP32 (write):
 *     START:L   begin streaming samples for the LEFT leg
 *     START:R   begin streaming samples for the RIGHT leg
 *     STOP      stop streaming
 *   ESP32 -> App (notify), one message per line:
 *     EMG:L:<value>   one sample for the left leg  (value ~ µV envelope)
 *     EMG:R:<value>   one sample for the right leg
 *     END:L / END:R   safety auto-stop fired (max duration reached)
 *     READY           idle heartbeat (link alive, not measuring)
 *
 * The app drives timing: it sends START, collects samples for a fixed window
 * (~3 s), then sends STOP and computes the real min / mean / max of the stream.
 *
 * Board:  ESP32-C3 (e.g. "ESP32C3 Dev Module" / Super Mini) — Arduino-ESP32 core.
 * Library: built-in "BLE" (BLEDevice.h). No extra library install needed.
 *
 * ── Serial Monitor not printing? ────────────────────────────────────────────
 *   On the ESP32-C3 the Serial Monitor only shows output when the IDE setting
 *   Tools -> "USB CDC On Boot" is set to ENABLED. With it Disabled, Serial goes
 *   to hardware UART0 (a GPIO pin), not USB, so the monitor stays blank even
 *   though BLE works. Enable it, re-upload, open the monitor at 115200.
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ── Nordic UART Service UUIDs (must match the Flutter app) ──────────────────
#define NUS_SERVICE   "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define NUS_RX_WRITE  "6e400002-b5a3-f393-e0a9-e50e24dcca9e"  // app -> ESP32
#define NUS_TX_NOTIFY "6e400003-b5a3-f393-e0a9-e50e24dcca9e"  // ESP32 -> app

const char* DEVICE_NAME = "Kinex-EMG";   // app quick-connect matches "Kinex"

// ── Timing ──────────────────────────────────────────────────────────────────
const unsigned long SAMPLE_INTERVAL_MS = 50;    // 20 Hz stream while measuring
const unsigned long MAX_MEASURE_MS     = 6000;  // safety auto-stop (app stops ~3s)
const unsigned long HEARTBEAT_MS       = 2000;  // idle "alive" ping

// ── State ────────────────────────────────────────────────────────────────────
BLEServer*         server          = nullptr;
BLECharacteristic* txChar          = nullptr;  // notify (ESP32 -> app)
bool               deviceConnected = false;

bool          measuring     = false;
char          measuringLeg  = 'L';
unsigned long measureStart  = 0;
unsigned long lastSample    = 0;
unsigned long lastHeartbeat = 0;

// ── Send one line up to the app over BLE notify ─────────────────────────────
void notifyApp(const String& line) {
  if (!deviceConnected || txChar == nullptr) return;
  txChar->setValue((uint8_t*)line.c_str(), line.length());
  txChar->notify();
}

// ── Mock EMG sample (µV-ish envelope during a sustained hold) ───────────────
// Per-leg baseline plus noise, so min / mean / max come out distinct. This is
// the ONLY place to swap in a real analogRead() of the EMG sensor later.
int mockEmgSample(char leg) {
  int center = (leg == 'L') ? 280 : 300;
  int v = center + random(-90, 130);   // -90..+129 noise
  if (v < 0) v = 0;
  return v;
}

// ── Measurement control ──────────────────────────────────────────────────────
void startMeasure(char leg) {
  measuring    = true;
  measuringLeg = leg;
  measureStart = millis();
  lastSample   = 0;
  Serial.print("[MEASURE] start leg=");
  Serial.println(leg);
}

void stopMeasure() {
  if (!measuring) return;
  measuring = false;
  Serial.print("[MEASURE] stop leg=");
  Serial.println(measuringLeg);
}

// ── Command parsing (app -> ESP32) ──────────────────────────────────────────
void handleCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;
  Serial.print("[RX] ");
  Serial.println(cmd);

  if (cmd == "START:L")      startMeasure('L');
  else if (cmd == "START:R") startMeasure('R');
  else if (cmd == "STOP")    stopMeasure();
  else                       notifyApp("echo:" + cmd);  // unknown -> echo for debug
}

// ── BLE callbacks ────────────────────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override {
    deviceConnected = true;
    Serial.println("[BLE] app connected");
  }
  void onDisconnect(BLEServer* s) override {
    deviceConnected = false;
    measuring = false;
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
  Serial.println("\nKinex EMG bridge (ESP32-C3) starting…");

  randomSeed(esp_random());   // distinct mock streams per boot

  BLEDevice::init(DEVICE_NAME);
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
  Serial.println("\" — connect from the app, then start a leg measurement.");
}

void loop() {
  const unsigned long now = millis();

  if (measuring) {
    // Stream one mock sample every interval.
    if (now - lastSample >= SAMPLE_INTERVAL_MS) {
      lastSample = now;
      int v = mockEmgSample(measuringLeg);
      String line = String("EMG:") + measuringLeg + ":" + String(v);
      notifyApp(line);
      Serial.print("[TX] ");
      Serial.println(line);
    }
    // Safety auto-stop if the app never sends STOP.
    if (now - measureStart >= MAX_MEASURE_MS) {
      String leg = String(measuringLeg);
      stopMeasure();
      notifyApp("END:" + leg);
    }
  } else if (deviceConnected && now - lastHeartbeat >= HEARTBEAT_MS) {
    // Idle heartbeat so both the app AND the Serial Monitor show the link alive.
    lastHeartbeat = now;
    notifyApp("READY");
    Serial.println("[HB] READY");
  }
}
