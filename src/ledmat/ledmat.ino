#include <SoftwareSerial.h>
extern "C" {
#include "processor.h"
}
#include <simple_matrix.h>
/*
#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>

#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 4
#define DATA_PIN 10
#define CLK_PIN 12
#define CS_PIN 11
*/
//MD_Parola myDisplay = MD_Parola(HARDWARE_TYPE, DATA_PIN, CLK_PIN, CS_PIN, MAX_DEVICES);
//MD_Parola myDisplay = MD_Parola(HARDWARE_TYPE, CS_PIN, MAX_DEVICES);

char bytes[10]; // remember to make it compatible with 9 byte packages
int i = 0;
simpleMatrix disp(12);

SoftwareSerial speedstacks(7, NULL, false);   // RX, TX
void setup() {
  disp.begin();
  disp.clearDisplay();
  //myDisplay.begin();
  /*
  myDisplay.setIntensity(0);
  myDisplay.displayClear();
  myDisplay.setTextAlignment(PA_LEFT);
  myDisplay.print("abracm");
  */
  Serial.begin(115200);
  speedstacks.begin(1200);

  if (speedstacks.available() > 0) {
    while (speedstacks.read() != '\r'); //check if its \n followed by \r - TO AVOID accidentelly starting after checksum
  }
}

static void
status_format (struct Status s,char *line[]) {
  sprintf(
      *line,
      "%c_%hu:%hu%hu.%hu%hu",
      s.state,
      s.minutes,
      s.decaseconds,
      s.seconds,
      s.deciseconds,
      s.centiseconds
    );
}

void loop() {
  struct Status status;
  while (speedstacks.available() > 0) {
    char inByte = speedstacks.read();
      //TODO deal with null/random characters at the start of bitstream
    Serial.write(inByte);
    bytes[i] = inByte;
    i++;
    if (i >= 10) {
      //Serial.print(bytes[0]);
      i = 0;
      int rc = decode_status(bytes, &status);
      //Serial.println(rc);
      
      if (false && decode_status(bytes, &status)) {
        Serial.println("rc deu ruim");
      } else {
        char line[10];
        status_format(status, (char **)&line);
        line[9] = '\0';
        //myDisplay.displayClear();
        disp.print(line);
      }
    }
  }
}