#include <SoftwareSerial.h>

// ====================== Configuration ======================
SoftwareSerial lightSerial(11, 12);  // RX from Li-Fi receiver

const int analogPin = A0;
const int maxSamples = 100;
const unsigned long timeout = 50;   // ms
const int N = 1024;                 // Number of subcarriers (OFDM parameter)

// ====================== Variables ======================
String lightMessage = "";
String wireMessage  = "";

unsigned long lastLightTime = 0;
unsigned long lastWireTime  = 0;

int readings[maxSamples];
int sampleIndex = 0;

// ====================== Function: Bit Error Count ======================
int countBitErrors(char a, char b) {
  int errors = 0;
  byte diff = (byte)a ^ (byte)b;

  for (int i = 0; i < 8; i++) {
    if (diff & (1 << i)) errors++;
  }
  return errors;
}

// ====================== Setup ======================
void setup() {
  Serial.begin(9600);
  lightSerial.begin(9600);

  // CSV Header
  Serial.println("Mean,Min,Max,Std,BER,Bias,N,LightMsg,WireMsg");
}

// ====================== Main Loop ======================
void loop() {

  // -------- Read Li-Fi Data --------
  if (lightSerial.available()) {
    char c = lightSerial.read();
    lightMessage += c;
    lastLightTime = millis();

    // Store analog samples
    if (sampleIndex < maxSamples) {
      readings[sampleIndex++] = analogRead(analogPin);
    }
  }

  // -------- Read Reference (Wired) Data --------
  if (Serial.available()) {
    char c = Serial.read();
    wireMessage += c;
    lastWireTime = millis();
  }

  // -------- Process Data After Timeout --------
  if ((millis() - lastLightTime > timeout) && lightMessage.length() > 0 &&
      (millis() - lastWireTime > timeout) && wireMessage.length() > 0) {

    // Safety check
    if (sampleIndex == 0) {
      lightMessage = "";
      wireMessage  = "";
      return;
    }

    // ================= BER Calculation =================
    int len = min(lightMessage.length(), wireMessage.length());
    int totalBits = len * 8;
    int errors = 0;

    for (int i = 0; i < len; i++) {
      errors += countBitErrors(lightMessage[i], wireMessage[i]);
    }

    float ber = (totalBits > 0) ? (float)errors / totalBits : 0;

    // ================= Voltage Conversion =================
    float voltages[maxSamples];

    for (int i = 0; i < sampleIndex; i++) {
      voltages[i] = readings[i] * 5.0 / 1023.0;
    }

    // ================= Statistical Features =================
    float sum = 0;
    float minV = voltages[0];
    float maxV = voltages[0];

    for (int i = 0; i < sampleIndex; i++) {
      sum += voltages[i];

      if (voltages[i] < minV) minV = voltages[i];
      if (voltages[i] > maxV) maxV = voltages[i];
    }

    float mean = sum / sampleIndex;

    // Standard Deviation
    float variance = 0;
    for (int i = 0; i < sampleIndex; i++) {
      variance += pow(voltages[i] - mean, 2);
    }

    float std = (sampleIndex > 1) ? sqrt(variance / (sampleIndex - 1)) : 0;

    // Bias = Mean (DC component)
    float bias = mean;

    // ================= Output CSV =================
    Serial.print(mean, 6); Serial.print(",");
    Serial.print(minV, 6); Serial.print(",");
    Serial.print(maxV, 6); Serial.print(",");
    Serial.print(std, 6); Serial.print(",");
    Serial.print(ber, 6); Serial.print(",");
    Serial.print(bias, 6); Serial.print(",");
    Serial.print(N); Serial.print(",");
    Serial.print(lightMessage); Serial.print(",");
    Serial.println(wireMessage);

    // ================= Reset =================
    lightMessage = "";
    wireMessage  = "";
    sampleIndex  = 0;
  }
}