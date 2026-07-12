/*
 * Kinex EMG — raw serial test (ESP32-C3)
 * --------------------------------------
 * NO BLE. Just reads the 4 right-leg EMG sensors and prints their raw ADC
 * values (0-4095) to the Serial Monitor, tab-separated so the Arduino
 * Serial Plotter draws all 4 traces at once. Use this to sanity-check the
 * sensors / wiring before running the real BLE firmware.
 *
 * Pins -> muscles (match your wiring; same order as the main firmware):
 *   GPIO 7 = VL   (thigh outer / quad)
 *   GPIO 6 = BF   (thigh back / hamstring)
 *   GPIO 5 = TA   (shin)
 *   GPIO 4 = GCM  (calf)
 *
 * Serial Monitor blank on ESP32-C3? Set Tools -> "USB CDC On Boot" = ENABLED,
 * re-upload, then open the Monitor / Plotter at 115200 baud.
 */

const int   EMG_PINS[4]   = {7, 6, 5, 4};
const char* EMG_LABELS[4] = {"VL", "BF", "TA", "GCM"};

void setup() {
  Serial.begin(115200);

  // 12-bit resolution (0-4095) and full 0-3.3 V range.
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  for (int i = 0; i < 4; i++) pinMode(EMG_PINS[i], INPUT);

  // Header line — the Serial Plotter uses it to label the 4 traces.
  Serial.println("VL\tBF\tTA\tGCM");
}

void loop() {
  for (int i = 0; i < 4; i++) {
    Serial.print(analogRead(EMG_PINS[i]));
    Serial.print(i < 3 ? '\t' : '\n');   // tab between values, newline at the end
  }
  delay(10);   // ~100 Hz
}
