//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  ChangXin Shen & Clark Pu
// Team:    C4 Chip Designed
// Version: 5.6
// Verification: Not Verified
// Comment: Initial OLED version by Clark.
// Furture Suggestion: Add simple GPU functino to oled manager
// Using UTF-8
//------------------------------------------------------------------------------

#define __MAIN_C__
#include <stdint.h>
#include <stdbool.h>

//------------------------------------------------------------------------------
// Hardware Address
//------------------------------------------------------------------------------

#define AHB_OLEDR_MANAGER_BASE   0xC0000000
#define AHB_SEGMENT_MANAGER_BASE 0xA0000000
#define AHB_TIMER_BASE           0x80000000
#define AHB_SENSOR_MANAGER_BASE  0x60000000
#define AHB_BUTTON_MANAGER_BASE  0x40000000
volatile uint32_t* OLED    = (volatile uint32_t*) AHB_OLEDR_MANAGER_BASE;
// OLED[0]        DnC            0xC0000000
// OLED[1]        Ready flag     0xC0000004
// OLED[2]        8 bit data     0xC0000008
volatile uint32_t* SEGMENT = (volatile uint32_t*) AHB_SEGMENT_MANAGER_BASE;
// SEGMENT[0]     Fraction       0xA0000000
// SEGMENT[1]     Integer        0xA0000004
// SEGMENT[2]     Mode           0xA0000008
volatile uint32_t* TIMER   = (volatile uint32_t*) AHB_TIMER_BASE;
// TIMER[0]       Long           0x80000000 
// TIMER[1]       Short          0x80000004 
// TIMER[2]       Flag           0x80000008 
volatile uint32_t* SENSOR  = (volatile uint32_t*) AHB_SENSOR_MANAGER_BASE;
// SENSOR[0]      Fork           0x60000000           
// SENSOR[1]      Crank          0x60000004       
volatile uint32_t* BUTTON  = (volatile uint32_t*) AHB_BUTTON_MANAGER_BASE;
// BUTTON[0]      DayNight       0x40000000
// BUTTON[1]      Mode           0x40000004
// BUTTON[2]      Trip           0x40000008
// BUTTON[3]      Setting        0x4000000A
// BUTTON[4]      NewData        0x40000010

//------------------------------------------------------------------------------
// Hardware Access Functions
//------------------------------------------------------------------------------

bool             setting(void){return BUTTON[3]?true:false;}
bool          press_trip(void){return BUTTON[2]?true:false;}
bool          press_mode(void){return BUTTON[1]?true:false;}
bool        press_d_mode(void){return BUTTON[0]?true:false;}
bool        check_button(void){return BUTTON[4]?true:false;}
bool             time_up(void){return  TIMER[2]?true:false;}
bool          oled_ready(void){return   OLED[1]?true:false;}
uint32_t read_time_short(void){return  TIMER[1];}
uint32_t  read_time_long(void){return  TIMER[0];}
uint32_t      read_crank(void){return SENSOR[1];}
uint32_t       read_fork(void){return SENSOR[0];}
void          clear_fork(void){SENSOR[0] = 0; return;}
void    clear_timer_long(void){TIMER[0]  = 0; return;}
void           oled_send(uint32_t Data, bool DnC){while(OLED[1]==0); OLED[0] = DnC?1:0; OLED[2] = Data; OLED[1] = 0; return;}
void     display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; SEGMENT[2] = Mode; return;}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

// start value must less than end value!
void oled_fill_area(uint8_t x_start, uint8_t y_start, uint8_t x_end, uint8_t y_end, bool clear){
  uint8_t colour_0 = 0x06, colour_1 = 0x3C;
  if (clear){
    colour_0 = 0xFF;
    colour_1 = 0xFF;
  }
  oled_send(0x15,  false); // setting column
  oled_send(x_start,true);
  oled_send(x_end,  true);
  oled_send(0x75,  false); // setting row
  oled_send(y_start,true);
  oled_send(y_end,  true);
  // Fill the area with blue colour
  oled_send(0x5C,  false); // setting pixels
  for (int i = x_start; i <= x_end; i++){
    for (int j = y_start; j <= y_end; j++){
      oled_send(colour_0, true);
      oled_send(colour_1, true);
    }
  }
  return;
}

uint32_t int2bcd(uint32_t value){
    uint32_t bcd = 0, shift = 0;
    while (value != 0) {
      bcd = bcd | ((value % 10) << shift);
      value = value / 10;
      shift = shift + 4;
    }
    return bcd;
}

bool wait_for_press(void){
  while(1)
    if (check_button())
      return true;
    else if (time_up())
      return false;
}

uint32_t wait_for_wheel_girth(uint32_t wheel_girth) {
  int press_times = 0;
  int wheel_3 = wheel_girth / 100 % 10;
  int wheel_2 = wheel_girth / 10 % 10;
  int wheel_1 = wheel_girth % 10;
  display_segment(0xE, int2bcd(wheel_girth % 1000), 0);
  while (1){
    if (check_button()) {
      if (press_mode()) {
        press_times ++;
        if (press_times == 3)
          return wheel_girth;
      }
      else if(press_trip()) {
        if (press_times == 0)
          wheel_3 = (wheel_3 + 1) % 10;
        else if (press_times == 1)
          wheel_2 = (wheel_2 + 1) % 10;
        else if (press_times == 2)
          wheel_1 = (wheel_1 + 1) % 10;
        wheel_girth = 2000 + wheel_3 * 100 + wheel_2 * 10 + wheel_1;
        display_segment(0xE, int2bcd(wheel_girth % 1000), 0);
        // get_setting_image();
        // display_oled();
      }
    }
  }
}

//------------------------------------------------------------------------------
// Main Function
//------------------------------------------------------------------------------

int main(void) {

  // variables
  bool is_night;
  uint32_t mode, wheel_girth;
  uint32_t 
    present_time, last_time, 
    delta_crank, long_delta_crank,
    present_fork, 
    present_cadence;
  int last_cadence_1, last_cadence_2;
  float 
    delta_distance, present_distance, last_distance, 
    delta_time, long_delta_time,
    present_speed, last_speed_1, last_speed_2;

  // general initiate
  wheel_girth = 2136; // setting
  is_night = false;
  long_delta_time = 0;
  long_delta_crank = 0;
  last_distance = 0;
  last_time = 0;
  last_speed_1 = 0;
  last_speed_2 = 0;
  last_cadence_1 = 0;
  last_cadence_2 = 0;
  present_cadence = 0;
  mode = 0xA;
  display_segment(mode, 0, 0);

  // oled initiate
  oled_send(0xAE,false); // fill white
  oled_send(0xAF,false); // light up
  oled_fill_area(10,10,20,20,false); // fill a blue square

  // process start
  while(1) {

    // I. Button interrupted 3 seconds wait

    if (wait_for_press()){
      if (setting())
        wheel_girth = wait_for_wheel_girth(wheel_girth);
      else {
        if (press_trip()) { // Don't clear short here, it's not necessary and may cause a divide-zero error.
          clear_fork();
          clear_timer_long(); 
        } 
        else if (press_mode()) // A: Odometer  B: Duration  C: Speed  D: Cadence  E: Setting
          if (mode >= 0xD)
            mode = 0xA;
          else
            mode ++; // Furture Design: switchDisplay will be judged by mode，removed.
        else if (press_d_mode())
          is_night = ~ is_night;
      }
    }

    // II. Refresh Time, Speed, Distance, Cadence.
    
    // 1. Time Stamp Data Read

    delta_crank  = read_crank();
    present_time = read_time_long();
    present_fork = read_fork();
    delta_time   = (float)(read_time_short()) / 1000;

    // 2. Calculate

    // Get present distance (unit: km)
    present_distance = (float)(present_fork * wheel_girth) / 1000000 + 0.01; // Number 0.01 is a bias. (unit: km)
    if (present_distance > 99.99)
      present_distance = 99.99;
    delta_distance = present_distance - last_distance;
    last_distance = present_distance;
    
    // Get present time (unit: second)
    if (delta_distance == 0) // if bicycle stopped
      present_time = last_time;
    last_time = present_time;
    
    // Get speed (unit: km/h)
    bool present_speed_valid = true;
    present_speed = (delta_distance * 3600) / (delta_time + 0.070); // (unit: km/h)
    if (present_speed > 99.99)
      present_speed =  99.99;
    // ingore unwanted jitter of speed
    if ((uint32_t)last_speed_1 == (uint32_t)last_speed_2){
      if ((uint32_t)present_speed != (uint32_t)last_speed_1)
        present_speed_valid = false;
    }
    else if ((uint32_t)present_speed == (uint32_t)last_speed_2)
      last_speed_1 = present_speed;
    last_speed_2 = last_speed_1;
    last_speed_1 = present_speed;
    if (!present_speed_valid)
      present_speed = last_speed_2;

    // Get cadence (unit: round/second)
    long_delta_time = long_delta_time + delta_time;
    long_delta_crank = long_delta_crank + delta_crank;
    if (long_delta_time > 5){
      present_cadence = (uint32_t) (long_delta_crank * 60 / long_delta_time);
      present_cadence = ((present_cadence + 2) / 5) * 5; // Precision: 5 round (unit: round/second)
      if (present_cadence > 999)
        present_cadence = 999;
      long_delta_time = 0;
      long_delta_crank = 0;
      // ingore unwanted jitter of speed
      bool present_cadence_valid = true;
      if (last_cadence_1 == last_cadence_2){
        if (present_cadence != last_cadence_1)
          present_cadence_valid = false;
      }
      else if (present_cadence == last_cadence_2)
        last_cadence_1 = present_cadence;
      last_cadence_2 = last_cadence_1;
      last_cadence_1 = present_cadence;
      if (!present_cadence_valid)
        present_cadence = last_cadence_2;
    }

    // 3. Refresh Segment

    uint32_t display_int, display_frac; //  This coding is to save more energy
    if (mode == 0xA){
      display_int  = (uint32_t) present_distance; // km
      display_frac = (uint32_t) ((present_distance - display_int) * 100); // km
    }
    else if (mode == 0xB){
      display_int  = present_time / 3600; // hour
      display_frac = (present_time % 3600) / 60; // minute
    }
    else if (mode == 0xC){
      display_int  = (uint32_t) present_speed; // km/h
      display_frac = (uint32_t) ((present_speed - display_int) * 100); // km/h
    }
    else if (mode == 0xD){
      display_int  = present_cadence; // r/s
      display_frac = 0; // nothing to show
    }

    display_segment(mode, int2bcd(display_int), int2bcd(display_frac));

    // 4. OLED test 50 pixels: Speed is 50 pixels/second
    oled_fill_area(5,5,10,10,true);  // clear square
    oled_fill_area(5,5,10,10,false); // fill a blue square

  }
}

