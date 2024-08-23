#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>
#include <Wire.h>
#include <SoftwareSerial.h>
#include <StackmatTimer.h>
#include <Fonts/FreeSans18pt7b.h>
#include "xantofont.h"
#include "config.h"

#define HARDWARE_TYPE MD_MAX72XX::FC16_HW

MD_Parola LED_DISPLAY = MD_Parola(HARDWARE_TYPE, DATA_PIN, CLK_PIN, CS_PIN, MAX_DEVICES);
Adafruit_SSD1306 oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);


char display_time[7]; // Time format M:SS.CC
int minutes;
int seconds;
int centiseconds;


SoftwareSerial timerSerial(RX_PIN, 255, true);
StackmatTimer cronometro(&timerSerial);
StackmatTimerState lastState;

void setup() {
  Serial.begin(19200);

  if (!LED_DISPLAY.begin()) {
    Serial.println("LED Display initialization failed!");
    while (true);
  }
  LED_DISPLAY.setIntensity(INITIAL_BRIGHTNESS);
  LED_DISPLAY.setFont(xantofont);

  Wire.begin(SDA_PIN, SCL_PIN);
  if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    while (true);
  }

  oled.clearDisplay();
  oled.setTextColor(WHITE);
  timerSerial.begin(STACKMAT_TIMER_BAUD_RATE);
}

void loop() {
  cronometro.Update();

  if (!cronometro.IsConnected()) {
    Serial.println("Timer is not connected");
    clearAndUpdateOLED("0:00.00");
    LED_DISPLAY.setIntensity(RUNNING_BRIGHTNESS);
    LED_DISPLAY.print(display_time);
    delay(1000);
    return;
  }

  if (cronometro.GetState() != lastState) {
    handleStateChange(cronometro.GetState());
  }

  if (cronometro.GetState() == ST_Running) {
    minutes = cronometro.GetInterpolatedDisplayMinutes();
    seconds = cronometro.GetInterpolatedDisplaySeconds();
    centiseconds = cronometro.GetInterpolatedDisplayMilliseconds();
    centiseconds = (centiseconds / 10);
    sprintf(display_time, "%01d:%02d.%02d", minutes, seconds, centiseconds);
    Serial.println(display_time);

    LED_DISPLAY.setIntensity(RUNNING_BRIGHTNESS);
    LED_DISPLAY.print(display_time);

    clearAndUpdateOLED(display_time);
  }

  lastState = cronometro.GetState();
  delay(10);
}

void clearAndUpdateOLED(const char* message) {
  oled.clearDisplay();
  oled.setFont(&FreeSans18pt7b);
  oled.setTextSize(OLED_TEXT_SIZE);
  oled.setCursor(INITIAL_OLED_X, INITIAL_OLED_Y);
  oled.print(message);
  oled.display();
}

void handleStateChange(StackmatTimerState state) {
  switch (state) {
    case ST_Stopped:
      minutes = cronometro.GetInterpolatedDisplayMinutes();
      seconds = cronometro.GetInterpolatedDisplaySeconds();
      centiseconds = cronometro.GetInterpolatedDisplayMilliseconds();
      centiseconds = (centiseconds / 10);
      sprintf(display_time, "%01d:%02d.%02d", minutes, seconds, centiseconds);

      LED_DISPLAY.setIntensity(STOPPED_BRIGHTNESS);
      LED_DISPLAY.print(display_time);

      clearAndUpdateOLED(display_time);
      break;
    case ST_Reset:
      minutes = 0;
      seconds = 0;
      centiseconds = 0;
      sprintf(display_time, "%01d:%02d.%02d", minutes, seconds, centiseconds);

      LED_DISPLAY.setIntensity(RESET_BRIGHTNESS);
      LED_DISPLAY.print(display_time);

      clearAndUpdateOLED("0:00.00");
      break;
    case ST_Running:
      Serial.println("GO!");
      break;
    case ST_LeftHandOnTimer:
      Serial.println("Left hand on timer!");
      break;
    case ST_RightHandOnTimer:
      Serial.println("Right hand on timer!");
      break;
    case ST_BothHandsOnTimer:
      Serial.println("Both hands on timer!");
      break;
    case ST_ReadyToStart:
      Serial.println("Ready to start!");
      LED_DISPLAY.setIntensity(2);
      break;
    default:
      Serial.println("Unknown state!");
      Serial.println(cronometro.GetState());
      break;
  }
}
