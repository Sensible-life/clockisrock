#include <SPI.h>
#include <MFRC522.h>
#include <FastLED.h>

#define SS_PIN 10
#define RST_PIN 9
#define LED_PIN 6
#define NUM_LEDS 16
#define BUTTON_PIN 2   // 버튼 핀 추가

MFRC522 rfid(SS_PIN, RST_PIN);
CRGB leds[NUM_LEDS];

bool lastButtonState = HIGH;
bool buttonState = HIGH;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;

void setup() {
  Serial.begin(9600);        // HC-06 기본 통신속도 9600
  SPI.begin();
  rfid.PCD_Init();

  FastLED.addLeds<WS2812B, LED_PIN, GRB>(leds, NUM_LEDS);
  FastLED.clear();
  FastLED.show();

  pinMode(BUTTON_PIN, INPUT_PULLUP);  // 버튼 핀 설정 (풀업 저항 사용)

  Serial.println("READY");   // 폰 앱이 연결되었는지 확인용
}

void loop() {
  rfid.PCD_Init();
  delay(50);

  // -----------------------------
  // ① 버튼 입력 감지 → 폰으로 분석 시작 신호 전송
  // -----------------------------
  bool reading = digitalRead(BUTTON_PIN);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;

      // 버튼이 눌렸을 때 (LOW, 풀업 저항 사용)
      if (buttonState == LOW) {
        Serial.println("BUTTON:PRESSED");

        // 버튼 피드백 LED
        lightMatrix(CRGB::Green);
        delay(200);
        clearLED();
      }
    }
  }
  lastButtonState = reading;

  // -----------------------------
  // ② RFID 태그 감지 → 폰으로 UID 전송
  // -----------------------------
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String uid = getUID();

    // 폰으로 메시지 전송 → "TAG:xxxxxx"
    Serial.print("TAG:");
    Serial.println(uid);

    // 기본 LED 반응 (선택 사항)
    lightMatrix(CRGB::DarkBlue);
    delay(600);
    clearLED();

    rfid.PICC_HaltA();
  }

  // -----------------------------
  // ③ 폰 → LED 명령 수신
  // -----------------------------
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    handleCommand(cmd);
  }
}

// ==================================================
// RFID UID 추출 함수
// ==================================================
String getUID() {
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}

// ==================================================
// 폰으로부터 받은 명령 처리
// LED: R,G,B 형식
// ex) LED:255,0,100
// CLEAR: LED 끄기
// ==================================================
void handleCommand(String cmd) {
  if (cmd.startsWith("LED:")) {
    // 문자열 파싱
    cmd.remove(0, 4);  // "LED:" 제거
    int r = cmd.substring(0, cmd.indexOf(',')).toInt();

    cmd = cmd.substring(cmd.indexOf(',') + 1);
    int g = cmd.substring(0, cmd.indexOf(',')).toInt();

    cmd = cmd.substring(cmd.indexOf(',') + 1);
    int b = cmd.toInt();

    lightMatrix(CRGB(r, g, b));
    return;
  }

  if (cmd == "CLEAR") {
    clearLED();
    return;
  }

  // ACK 응답
  if (cmd == "PING") {
    Serial.println("PONG");
    return;
  }
}

// ==================================================
// LED 점등
// ==================================================
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
