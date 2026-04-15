#include <SoftwareSerial.h>

// ====================== Configuration ======================
SoftwareSerial lightSerial(11, 12);  // TX to Li-Fi transmitter

const int numMessages = 3;

// QAM Orders and corresponding OFDM sizes
int M_list[numMessages] = {4, 16, 64};
int N_list[numMessages] = {128, 256, 512};

const unsigned long interval = 3000; // Transmission interval (ms)

// ====================== Variables ======================
unsigned long previousMillis = 0;
int currentIndex = 0;

// ====================== Setup ======================
void setup() {
  Serial.begin(9600);
  lightSerial.begin(9600);

  // Initialize random seed for message generation
  randomSeed(analogRead(0));

  Serial.println("Li-Fi Transmitter Initialized...");
}

// ====================== Main Loop ======================
void loop() {

  unsigned long currentMillis = millis();

  // Send new message periodically
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // -------- Get Current Parameters --------
    int M = M_list[currentIndex];
    int N = N_list[currentIndex];

    // -------- Calculate bits per symbol (k = log2(M)) --------
    int k = 0;
    int temp = M;
    while (temp >>= 1) k++;

    // -------- Determine message length --------
    int totalBits = N * k;
    int numChars = totalBits / 8;

    // -------- Generate Random Message --------
    String generatedMsg = "";

    for (int i = 0; i < numChars; i++) {
      char c = char(random(65, 91)); // A-Z characters
      generatedMsg += c;
    }

    // -------- Format Message --------
    String fullMessage = "M:" + String(M) +
                         ";N:" + String(N) +
                         ";MSG:" + generatedMsg;

    // -------- Debug Output --------
    Serial.print("Transmitting: ");
    Serial.println(fullMessage);

    // -------- Send via Li-Fi Channel --------
    lightSerial.println(fullMessage);

    // -------- Move to Next Configuration --------
    currentIndex++;
    if (currentIndex >= numMessages) {
      currentIndex = 0;
    }
  }
}