/*
 * Kinex LEG-L bridge — ESP32-C3 Super Mini (LEFT leg board)
 * ----------------------------------------------------------
 * BLE link between the Kinex Flutter app and the ESP32, used by the EMG
 * installation / MVC-calibration step. This is the LEFT-leg board — its twin,
 * firmware/kinex_leg_R/, is identical except it advertises the "-R" suffix
 * and defaults to leg='R'. Both replace the legacy single-board
 * firmware/kinex_leg/ (kept in place for anything not yet reflashed).
 *
 * MOCK DATA: sends fake per-channel values over BLE (no analogRead) so the app,
 * the realtime graph and the MVC capture can be tested WITHOUT sensors wired.
 * The REAL-sensor build is saved alongside in
 * firmware/kinex_leg_realsensor/ — flash THAT one for real readings.
 * Every value is still sent over BLE AND printed to Serial.
 *
 * ── Sensor wiring (LEFT leg, 4 channels) ────────────────────────────────────
 *   ADC pins {7, 6, 5, 4}  ->  muscles {VL, BF, TA, GCM}
 *   (VL = thigh outer / quad, BF = thigh back / hamstring, TA = shin, GCM = calf)
 *   If your physical wiring differs, just reorder EMG_PINS[] below.
 *
 * ── BLE name (must match the app's suffix contract) ─────────────────────────
 *   Each board derives a unique name from its own chip MAC, with a fixed side
 *   suffix so the app pairs reliably: "Kinex-<HEX>-L" (e.g. "Kinex-3F7A-L").
 *   The app matches on the "-l" suffix (see matchesLegLBoard in
 *   lib/ble/ble_service.dart), not the random hex, so re-flashing is safe.
 *
 * ── Protocol (Nordic UART Service — same UUIDs the app already uses) ─────────
 *   App  -> ESP32 (write):
 *     STREAM:ON   begin the 4-channel realtime stream (the EMG graph page)
 *     STREAM:OFF  stop the realtime stream
 *     START:<leg>:<ch>  begin single-channel MVC capture. <leg>=L|R, <ch>=0..3 =
 *                       which mapped muscle sensor to read (0=VL 1=BF 2=TA 3=GCM).
 *                       "START" with no leg defaults to this board's own side (L).
 *     STOP              stop MVC capture
 *   ESP32 -> App (notify), one message per line:
 *     EMG4:<v0>,<v1>,<v2>,<v3>  one 4-channel sample (VL,BF,TA,GCM raw ADC 0-4095)
 *     EMG:L:<value> / EMG:R:<value>  one MVC sample for the requested channel
 *     END:L / END:R   MVC safety auto-stop fired (max duration reached)
 *     READY           idle heartbeat (link alive, not measuring/streaming)
 *
 * The MVC path is app-driven (START, ~3 s window, STOP). The realtime graph path
 * streams continuously between STREAM:ON and STREAM:OFF.
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
#include "esp_mac.h"

// ── Nordic UART Service UUIDs (must match the Flutter app) ──────────────────
#define NUS_SERVICE   "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define NUS_RX_WRITE  "6e400002-b5a3-f393-e0a9-e50e24dcca9e"  // app -> ESP32
#define NUS_TX_NOTIFY "6e400003-b5a3-f393-e0a9-e50e24dcca9e"  // ESP32 -> app

// Filled in setup() from the chip's own BLE MAC: "Kinex-<HEX>-L", e.g.
// "Kinex-3F7A-L". The app's Leg-L slot matches on the "-l" suffix (see
// matchesLegLBoard in lib/ble/ble_service.dart).
char DEVICE_NAME[24];

// ── EMG sensor channels (LEFT leg) ──────────────────────────────────────────
// ADC pins in channel order 0..3. Reorder to match your physical wiring.
const int         EMG_PINS[4]   = {7, 6, 5, 4};              // VL, BF, TA, GCM
const char* const EMG_LABELS[4] = {"VL", "BF", "TA", "GCM"}; // (for reference)

// ── Timing ──────────────────────────────────────────────────────────────────
const unsigned long SAMPLE_INTERVAL_MS = 50;     // 20 Hz stream (measuring + realtime)
const unsigned long MAX_MEASURE_MS     = 6000;   // MVC safety auto-stop (app stops ~3s)
const unsigned long MAX_STREAM_MS      = 300000; // realtime safety auto-stop (5 min)
const unsigned long HEARTBEAT_MS       = 2000;   // idle "alive" ping

// ── State ────────────────────────────────────────────────────────────────────
BLEServer*         server          = nullptr;
BLECharacteristic* txChar          = nullptr;  // notify (ESP32 -> app)
bool               deviceConnected = false;

bool          measuring     = false;   // single-channel MVC capture (START:<leg>:<ch>)
char          measuringLeg  = 'L';     // this board's side — default when START omits it
int           measuringCh   = 0;       // which EMG_PINS[] channel the MVC step reads
bool          streaming     = false;   // 4-channel realtime graph (STREAM:ON)
unsigned long windowStart   = 0;       // start of the active measure/stream window
unsigned long lastSample    = 0;
unsigned long lastHeartbeat = 0;

// ── Send one line up to the app over BLE notify ─────────────────────────────
void notifyApp(const String& line) {
  if (!deviceConnected || txChar == nullptr) return;
  txChar->setValue((uint8_t*)line.c_str(), line.length());
  txChar->notify();
}

// ── EMG read (MOCK) ──────────────────────────────────────────────────────────
// Fake per-channel value: baseline + noise, so the 4 traces look distinct and
// the min/mean/max come out sensible. NO analogRead here — this is the mock
// build. The real build (firmware/kinex_leg_realsensor/) does
// `return analogRead(EMG_PINS[channel]);` instead. Channel 0..3 = VL,BF,TA,GCM.
int readEmg(int channel) {
  static const int base[4] = {280, 340, 220, 380};  // VL, BF, TA, GCM baselines
  int v = base[channel] + random(-90, 130);
  if (v < 0) v = 0;
  return v;
}

// ── Measurement control ──────────────────────────────────────────────────────
void startMeasure(char leg, int ch) {
  if (ch < 0 || ch > 3) ch = 0;
  streaming    = false;         // MVC and realtime are mutually exclusive
  measuring    = true;
  measuringLeg = leg;
  measuringCh  = ch;
  windowStart  = millis();
  lastSample   = 0;
  Serial.print("[MEASURE] start leg=");
  Serial.print(leg);
  Serial.print(" ch=");
  Serial.print(ch);
  Serial.print(" (");
  Serial.print(EMG_LABELS[ch]);
  Serial.println(")");
}

void stopMeasure() {
  if (!measuring) return;
  measuring = false;
  Serial.print("[MEASURE] stop leg=");
  Serial.println(measuringLeg);
}

void startStream() {
  measuring   = false;
  streaming   = true;
  windowStart = millis();
  lastSample  = 0;
  Serial.println("[STREAM] on (4-channel realtime)");
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
  else if (cmd.startsWith("START:")) {
    // START:<leg>[:<ch>] — <leg>=L/R, <ch>=0..3 = which mapped muscle sensor.
    char leg = cmd.length() > 6 ? cmd.charAt(6) : 'L';
    int  ch  = 0;
    int  c2  = cmd.indexOf(':', 6);          // second colon (before the channel)
    if (c2 > 0 && c2 + 1 < (int)cmd.length()) ch = cmd.substring(c2 + 1).toInt();
    startMeasure(leg, ch);
  }
  else if (cmd == "STOP")       stopMeasure();
  else                          notifyApp("echo:" + cmd);  // unknown -> echo for debug
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
  Serial.println("\nKinex LEG-L bridge (ESP32-C3) starting…");

  // ADC config kept (harmless) so switching to the real-sensor build is trivial.
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  for (int i = 0; i < 4; i++) pinMode(EMG_PINS[i], INPUT);
  randomSeed(esp_random());   // distinct mock streams per boot

  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_BLE);
  snprintf(DEVICE_NAME, sizeof(DEVICE_NAME), "Kinex-%02X%02X-L", mac[4], mac[5]);

  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(80);   // allow the ~24-byte "EMG4:..." notify to fit in one packet
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

  if (streaming) {
    // 4-channel realtime stream: EMG4:<VL>,<BF>,<TA>,<GCM> every interval.
    if (now - lastSample >= SAMPLE_INTERVAL_MS) {
      lastSample = now;
      String line = String("EMG4:") + readEmg(0) + "," + readEmg(1) + "," +
                    readEmg(2) + "," + readEmg(3);
      notifyApp(line);
      Serial.print("[TX] ");
      Serial.println(line);
    }
    // Safety auto-stop if the app never sends STREAM:OFF (e.g. crash/kill).
    if (now - windowStart >= MAX_STREAM_MS) {
      stopStream();
      notifyApp("END:STREAM");
    }
  } else if (measuring) {
    // Single-channel MVC sample every interval (the requested muscle's sensor).
    if (now - lastSample >= SAMPLE_INTERVAL_MS) {
      lastSample = now;
      int v = readEmg(measuringCh);
      String line = String("EMG:") + measuringLeg + ":" + String(v);
      notifyApp(line);
      Serial.print("[TX] ");
      Serial.println(line);
    }
    // Safety auto-stop if the app never sends STOP.
    if (now - windowStart >= MAX_MEASURE_MS) {
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
