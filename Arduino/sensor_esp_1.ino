#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "AdafruitIO_WiFi.h"
#include <time.h>
#include <esp_now.h>

#define IO_USERNAME "DineshKarthik23"
#define IO_KEY ""

#define WIFI_SSID "pi12"
#define WIFI_PASS "raspberry12"

AdafruitIO_WiFi io(IO_USERNAME, IO_KEY, WIFI_SSID, WIFI_PASS);

AdafruitIO_Feed *accxFeed = io.feed("crash-acc-x");
AdafruitIO_Feed *accyFeed = io.feed("crash-acc-y");
AdafruitIO_Feed *acczFeed = io.feed("crash-acc-z");

AdafruitIO_Feed *gforceFeed = io.feed("g-force");
AdafruitIO_Feed *brakeFeed = io.feed("brake-status");
AdafruitIO_Feed *indicatorFeed = io.feed("indicator-status");

AdafruitIO_Feed *latFeed = io.feed("crash-lat");
AdafruitIO_Feed *lonFeed = io.feed("crash-lon");

AdafruitIO_Feed *speedFeed = io.feed("crash-speed");
AdafruitIO_Feed *timeFeed = io.feed("crash-time");

String apiKey = "AIzaSyAgHxAy5aYds_vcWLh1uhxH-aMMdVbxz1k";

float latitude = 0;
float longitude = 0;

unsigned long lastLocationUpdate = 0;
const unsigned long locationInterval = 5000;

const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 19800;
const int daylightOffset_sec = 0;

#define SDA_PIN 21
#define SCL_PIN 22
#define MPU_ADDR 0x68

#define ACCEL_XOUT_H 0x3B
#define TEMP_OUT_H   0x41
#define PWR_MGMT_1   0x6B

#define SD_CS 5
#define SPI_MOSI 23
#define SPI_MISO 19
#define SPI_SCK 18

File logFile;
bool crashDetected = false;

#define HALL_PIN 34
#define MAGNETS 1
#define WHEEL_RADIUS 0.03

volatile unsigned long pulseCount = 0;

unsigned long lastSpeedTime = 0;
float speed_kmph = 0;

float ax_offset=0, ay_offset=0, az_offset=0;
float ax_f=0, ay_f=0, az_f=0;
float alpha = 0.2;

int brakeStatus = 0;
int indicatorStatus = 0;

typedef struct struct_message {
  int brake;
  int indicator;
} struct_message;

struct_message incomingData;

void OnDataRecv(const esp_now_recv_info *info, const uint8_t *data, int len) {

  memcpy(&incomingData, data, sizeof(incomingData));

  brakeStatus = incomingData.brake;
  indicatorStatus = incomingData.indicator;

  Serial.print("Brake: ");
  Serial.println(brakeStatus);

  Serial.print("Indicator: ");
  Serial.println(indicatorStatus);
}

void writeRegister(uint8_t reg, uint8_t val){
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

int16_t read16(uint8_t reg){
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR,2);
  return (Wire.read()<<8) | Wire.read();
}

void IRAM_ATTR countPulse(){
  pulseCount++;
}

void calibrateMPU(){

  Serial.println("Calibrating MPU... Keep system still");

  int samples = 200;

  float ax=0, ay=0, az=0;

  for(int i=0;i<samples;i++){

    ax += read16(ACCEL_XOUT_H);
    ay += read16(ACCEL_XOUT_H+2);
    az += read16(ACCEL_XOUT_H+4);

    delay(10);
  }

  ax_offset = (ax/samples)/16384.0;
  ay_offset = ((ay/samples)/16384.0) - 1.0;
  az_offset = (az/samples)/16384.0;

  Serial.println("MPU Calibration Done");
}

void getLocation() {

  int networks = WiFi.scanNetworks();

  if(networks == 0) return;

  String json = "{ \"wifiAccessPoints\":[";

  for(int i=0;i<networks;i++){

    json += "{";
    json += "\"macAddress\":\""+WiFi.BSSIDstr(i)+"\",";
    json += "\"signalStrength\":"+String(WiFi.RSSI(i));
    json += "}";

    if(i < networks-1) json += ",";
  }

  json += "]}";

  HTTPClient http;

  String url = "https://www.googleapis.com/geolocation/v1/geolocate?key="+apiKey;

  http.begin(url);
  http.addHeader("Content-Type","application/json");

  int httpCode = http.POST(json);

  if(httpCode > 0){

    String payload = http.getString();

    StaticJsonDocument<1024> doc;
    deserializeJson(doc,payload);

    latitude = doc["location"]["lat"];
    longitude = doc["location"]["lng"];
  }

  http.end();
}

void setup(){

  Serial.begin(115200);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID,WIFI_PASS);

  while(WiFi.status()!=WL_CONNECTED){
    delay(500);
    Serial.print(".");
  }

  Serial.println("WiFi Connected");

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW Init Failed");
    return;
  }

  esp_now_register_recv_cb(OnDataRecv);

  Wire.begin(SDA_PIN,SCL_PIN);
  writeRegister(PWR_MGMT_1,0x00);

  delay(2000);
  calibrateMPU();

  pinMode(HALL_PIN,INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(HALL_PIN),countPulse,FALLING);

  SPI.begin(SPI_SCK,SPI_MISO,SPI_MOSI,SD_CS);

  if(!SD.begin(SD_CS)){
    Serial.println("SD FAIL");
    while(1);
  }

  logFile=SD.open("/vehicle_log.csv",FILE_WRITE);

  if(logFile){
    logFile.println("timestamp,ax,ay,az,temp,speed,lat,lon,gforce,brake,indicator,crash");
    logFile.close();
  }

  io.connect();

  while(io.status() < AIO_CONNECTED){
    delay(500);
  }

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

void loop(){

  io.run();

  struct tm timeinfo;
  char timestamp[25];

  if(getLocalTime(&timeinfo)){
    strftime(timestamp,sizeof(timestamp),"%Y-%m-%d %H:%M:%S",&timeinfo);
  }

  if(millis()-lastLocationUpdate > locationInterval){
    getLocation();
    lastLocationUpdate = millis();
  }

  int16_t ax=read16(ACCEL_XOUT_H);
  int16_t ay=read16(ACCEL_XOUT_H+2);
  int16_t az=read16(ACCEL_XOUT_H+4);

  int16_t tempRaw=read16(TEMP_OUT_H);

  float ax_g=(ax/16384.0)-ax_offset;
  float ay_g=(ay/16384.0)-ay_offset;
  float az_g=(az/16384.0)-az_offset;

  float tempC=(tempRaw/340.0)+36.53;

  ax_f = alpha*ax_g + (1-alpha)*ax_f;
  ay_f = alpha*ay_g + (1-alpha)*ay_f;
  az_f = alpha*az_g + (1-alpha)*az_f;

  float g_force = sqrt(ax_f*ax_f + ay_f*ay_f + az_f*az_f);

  if(millis()-lastSpeedTime>=1000){

    noInterrupts();
    unsigned long pulses=pulseCount;
    pulseCount=0;
    interrupts();

    float rotations=(float)pulses/MAGNETS;
    float rpm=rotations*60;

    float circumference=2*PI*WHEEL_RADIUS;
    float speed_mps=(rpm*circumference)/60;

    speed_kmph=speed_mps*3.6;

    lastSpeedTime=millis();
  }

  bool crash = false;

  if(g_force > 1.2 && !crashDetected){

    crash = true;
    crashDetected = true;

    accxFeed->save(ax_f);
    accyFeed->save(ay_f);
    acczFeed->save(az_f);

    gforceFeed->save(g_force);
    brakeFeed->save(brakeStatus);
    indicatorFeed->save(indicatorStatus);

    latFeed->save(latitude);
    lonFeed->save(longitude);

    speedFeed->save(speed_kmph);

    timeFeed->save(timestamp);
  }

  if(!crashDetected){

    logFile = SD.open("/vehicle_log.csv",FILE_APPEND);

    if(logFile){

      logFile.print(timestamp); logFile.print(",");
      logFile.print(ax_f,3); logFile.print(",");
      logFile.print(ay_f,3); logFile.print(",");
      logFile.print(az_f,3); logFile.print(",");
      logFile.print(tempC,2); logFile.print(",");
      logFile.print(speed_kmph); logFile.print(",");
      logFile.print(latitude,6); logFile.print(",");
      logFile.print(longitude,6); logFile.print(",");
      logFile.print(g_force); logFile.print(",");
      logFile.print(brakeStatus); logFile.print(",");
      logFile.print(indicatorStatus); logFile.print(",");
      logFile.println(crash);

      logFile.close();
    }
  }

  delay(200);
}