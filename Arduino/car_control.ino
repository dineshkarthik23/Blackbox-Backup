#include <WiFi.h>
#include <WebServer.h>
#include <esp_now.h>

const char* ssid = "pi12";
const char* password = "";

#define ENA 25
#define IN1 26
#define IN2 27

#define ENB 14
#define IN3 12
#define IN4 13

#define BUZZER 33
#define LEFT_LED 32
#define RIGHT_LED 15 

WebServer server(80);

typedef struct struct_message {
  int brake;
  int indicator;
} struct_message;

struct_message data;

uint8_t sensorAddress[] = {0xEC,0x62,0x60,0x9A,0x08,0x90};

void sendStatus() {
  esp_now_send(sensorAddress, (uint8_t *) &data, sizeof(data));
}

void stopCar() {

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);

  data.brake = 1;
  data.indicator = 0;

  sendStatus();
}

void forward() {

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);

  data.brake = 0;

  sendStatus();
}

void backward() {

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);

  data.brake = 0;

  sendStatus();
}

void left() {

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);

  data.brake = 0;

  sendStatus();
}

void right() {

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);

  data.brake = 0;

  sendStatus();
}

void handleIndicatorLeft() {

  digitalWrite(LEFT_LED, HIGH);
  digitalWrite(RIGHT_LED, LOW);

  data.indicator = 2;
  data.brake = 0;

  sendStatus();

  server.send(200, "text/plain", "LEFT INDICATOR");
}

void handleIndicatorRight() {

  digitalWrite(RIGHT_LED, HIGH);
  digitalWrite(LEFT_LED, LOW);

  data.indicator = 1;
  data.brake = 0;

  sendStatus();

  server.send(200, "text/plain", "RIGHT INDICATOR");
}

void handleIndicatorOff() {

  digitalWrite(LEFT_LED, LOW);
  digitalWrite(RIGHT_LED, LOW);

  data.indicator = 0;

  sendStatus();

  server.send(200, "text/plain", "INDICATORS OFF");
}

void handleHorn() {

  digitalWrite(BUZZER, HIGH);
  delay(200);
  digitalWrite(BUZZER, LOW);

  server.send(200, "text/plain", "HORN");
}

void handleForward() {
  forward();
  server.send(200, "text/plain", "FORWARD");
}

void handleBackward() {
  backward();
  server.send(200, "text/plain", "BACKWARD");
}

void handleLeft() {
  left();
  server.send(200, "text/plain", "LEFT");
}

void handleRight() {
  right();
  server.send(200, "text/plain", "RIGHT");
}

void handleStop() {
  stopCar();
  server.send(200, "text/plain", "STOP");
}

void handleRoot() {
  server.send(200, "text/plain", "ESP32 Car Control Ready");
}

void setup() {

  Serial.begin(115200);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  pinMode(BUZZER, OUTPUT);
  pinMode(LEFT_LED, OUTPUT);
  pinMode(RIGHT_LED, OUTPUT);

  ledcAttach(ENA, 2000, 8);
  ledcAttach(ENB, 2000, 8);

  ledcWrite(ENA, 180);
  ledcWrite(ENB, 180);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected");

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    return;
  }

  esp_now_peer_info_t peerInfo = {};
  memcpy(peerInfo.peer_addr, sensorAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  esp_now_add_peer(&peerInfo);

  stopCar();

  Serial.print("Car Control IP: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.on("/forward", handleForward);
  server.on("/backward", handleBackward);
  server.on("/left", handleLeft);
  server.on("/right", handleRight);
  server.on("/stop", handleStop);

  server.on("/indicator_left", handleIndicatorLeft);
  server.on("/indicator_right", handleIndicatorRight);
  server.on("/indicator_off", handleIndicatorOff);

  server.on("/horn", handleHorn);

  server.begin();

  Serial.println("Web Server Started");
}

void loop() {
  server.handleClient();
}