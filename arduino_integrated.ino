#include <SPI.h>
#include <MFRC522.h>
#include <FastLED.h>
#include <SoftwareSerial.h>

// ========== 핀 정의 ==========
#define SS_PIN 10           // RFID SS
#define RST_PIN 9           // RFID RST
#define LED_PIN 6           // WS2812B LED Data
#define NUM_LEDS 16         // LED 개수 (4x4)
#define BUTTON_PIN 4        // 버튼 핀 (풀업)
#define BT_RX 8             // HC-06 RX (아두이노 TX → HC-06 RX)
#define BT_TX 7             // HC-06 TX (아두이노 RX ← HC-06 TX)

// ========== 객체 초기화 ==========
MFRC522 rfid(SS_PIN, RST_PIN);
CRGB leds[NUM_LEDS];
SoftwareSerial BT(BT_RX, BT_TX);  // (RX, TX)

// ========== 버튼 디바운싱 ==========
bool lastButtonState = HIGH;
bool buttonState = HIGH;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;

void setup() {
  Serial.begin(115200);    // 디버그용
  BT.begin(9600);          // HC-06 기본 통신속도

  SPI.begin();
  rfid.PCD_Init();

  FastLED.addLeds<WS2812B, LED_PIN, GRB>(leds, NUM_LEDS);
  FastLED.clear();
  FastLED.show();

  pinMode(BUTTON_PIN, INPUT_PULLUP);  // 버튼 핀 (풀업 저항)

  Serial.println("=== System Ready ===");
  BT.println("READY");
}

void loop() {
  // ========== 1. 버튼 입력 처리 ==========
  checkButton();

  // ========== 2. RFID 태그 감지 ==========
  checkRFID();

  // ========== 3. Bluetooth 명령 수신 ==========
  if (BT.available()) {
    String cmd = BT.readStringUntil('\n');
    cmd.trim();
    handleCommand(cmd);
  }

  delay(10);
}

// ========================================
// 버튼 감지 (디바운싱 포함)
// ========================================
void checkButton() {
  bool reading = digitalRead(BUTTON_PIN);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;

      // 버튼이 눌렸을 때 (LOW, 풀업 저항 사용)
      if (buttonState == LOW) {
        Serial.println("[BUTTON] Pressed!");
        BT.println("BUTTON:PRESSED");

        // 버튼 피드백 LED (빠르게 깜빡임)
        blinkLED(CRGB::Green, 1, 200);
      }
    }
  }
  lastButtonState = reading;
}

// ========================================
// RFID 태그 감지
// ========================================
void checkRFID() {
  rfid.PCD_Init();
  delay(10);

  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  // UID 읽기
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();

  // Bluetooth로 UID 전송
  Serial.print("[RFID] UID: ");
  Serial.println(uid);
  BT.print("TAG:");
  BT.println(uid);

  // RFID 감지 피드백 LED
  lightMatrix(CRGB::DarkBlue);
  delay(600);
  clearLED();

  rfid.PICC_HaltA();
}

// ========================================
// Bluetooth 명령 처리
// ========================================
void handleCommand(String cmd) {
  Serial.print("[BT CMD] ");
  Serial.println(cmd);

  // LED 색상 제어: LED:R,G,B
  if (cmd.startsWith("LED:")) {
    cmd.remove(0, 4);  // "LED:" 제거

    int r = cmd.substring(0, cmd.indexOf(',')).toInt();
    cmd = cmd.substring(cmd.indexOf(',') + 1);

    int g = cmd.substring(0, cmd.indexOf(',')).toInt();
    cmd = cmd.substring(cmd.indexOf(',') + 1);

    int b = cmd.toInt();

    lightMatrix(CRGB(r, g, b));
    return;
  }

  // LED 깜빡임: BLINK:횟수
  if (cmd.startsWith("BLINK:")) {
    int count = cmd.substring(6).toInt();
    blinkLED(CRGB::Green, count, 300);
    return;
  }

  // LED 끄기
  if (cmd == "CLEAR") {
    clearLED();
    return;
  }

  // PING-PONG 테스트
  if (cmd == "PING") {
    BT.println("PONG");
    return;
  }
}

// ========================================
// LED 제어 함수
// ========================================
void lightMatrix(CRGB color) {
  for (int i = 0; i < NUM_LEDS; i++) {
    leds[i] = color;
  }
  FastLED.show();
}

void clearLED() {
  FastLED.clear();
  FastLED.show();
}

void blinkLED(CRGB color, int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    lightMatrix(color);
    delay(delayMs);
    clearLED();
    delay(delayMs);
  }
}
