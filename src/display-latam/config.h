#ifndef CONFIG_H
#define CONFIG_H

// Define constants
#define MAX_DEVICES 4
#define CLK_PIN 2
#define DATA_PIN 4
#define CS_PIN 3
#define SDA_PIN 6
#define SCL_PIN 8
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
#define OLED_ADDRESS 0x3c
#define INITIAL_BRIGHTNESS 0
#define RESET_BRIGHTNESS 0
#define RUNNING_BRIGHTNESS 5
#define STOPPED_BRIGHTNESS 8
#define RX_PIN 20

const float OLED_TEXT_SIZE = 1;
const int INITIAL_OLED_X = 10;
const int INITIAL_OLED_Y = 30;

#endif