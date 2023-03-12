//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  ChangXin Shen & Clark Pu
// Team:    C4 Chip Designed
// Version: 5.3.1
// Verification: Not Verified
// Comment: Optimizition on code writing and ROM comsuption by Clark. Using UTF-8
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
// OLED[0]        X              0xC0000000
// OLED[1]        Y              0xC0000004
// OLED[2]        Colour         0xC0000008
// OLED[3]        Flag           0xC000000A
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
uint32_t read_time_short(void){return  TIMER[1];}
uint32_t  read_time_long(void){return  TIMER[0];}
uint32_t      read_crank(void){return SENSOR[1];}
uint32_t       read_fork(void){return SENSOR[0];}
void          clear_fork(void){SENSOR[0] = 0; return;}
void    clear_timer_long(void){TIMER[0] = 0; return;}
void     display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; SEGMENT[2] = Mode; return;}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

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

uint32_t wait_for_setting(uint32_t wheel_iso) {
  uint32_t press_times = 0;
  uint32_t wheel_1, wheel_2, wheel_3;
  uint32_t wheel_f_bcd;
  wheel_f_bcd = int2bcd(wheel_iso);
  display_segment(0xE, wheel_f_bcd, 0);
  while (1){
    wheel_3 = wheel_iso / 100;
    wheel_2 = (wheel_iso - wheel_3 * 100) / 10;
    wheel_1 = (wheel_iso - wheel_3 * 100) - (wheel_2 * 10);
    if (check_button()) {
      if (press_mode()) {
        press_times ++;
        if (press_times == 3)
          return wheel_iso;
      } else if(press_trip()) {
        if (press_times == 0) 
          wheel_3 = (wheel_3 + 1) % 10;
        else if (press_times == 1)
          wheel_2 = (wheel_2 + 1) % 10;               
        else if (press_times == 2)            
          wheel_1 = (wheel_1 + 1) % 10;
        wheel_iso = wheel_3 * 100 + wheel_2 * 10 + wheel_1;
        wheel_f_bcd = int2bcd(wheel_iso);
        display_segment(0xE, wheel_f_bcd, 0);
          //get_setting_image();
          //display_oled();
      }
    }
  }  
}

//------------------------------------------------------------------------------
// Main Function
//------------------------------------------------------------------------------

int main(void) {

  // initiate
  bool is_night;
  float delta_distance, distance, last_distance, delta_time, speed;
  uint32_t mode, wheel_iso, wheel_girth;
  uint32_t present_time, last_time, present_crank, present_fork, cadence;
  wheel_iso = 700;
  wheel_girth = 2136; // prepare a look up table
  is_night = false;
  last_distance = 0;
  last_time = 0;
  mode = 0xA;

  display_segment(mode, 0, 0);
  // display_oled();

  while(1) {

    // I. Button interrupted 3 seconds wait

    if (wait_for_press()) {
      if (setting())
        wheel_iso = wait_for_setting(wheel_iso);
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
    present_crank = read_crank();
    present_time = read_time_long();
    present_fork = read_fork();
    delta_time = ((float)read_time_short())/1000.0; // 考虑是否可能等于零? : 按钮的消抖是25ms, 所以其中的值一定大于25.

    // 2. Calculate

    // Get distance (unit: km)
    distance = (float)(present_fork * wheel_girth) / 1000000 + 0.01; // Number 0.01 is a bias. (unit: km)
    if (distance > 99.99)
      distance = 99.99;
    delta_distance = distance - last_distance;
    last_distance = distance;

    // Get present time (unit: second)
    if (delta_distance == 0) // if bicycle stopped
      present_time = last_time;
    last_time = present_time;
    
    // Get speed (unit: km/h)
    speed = (delta_distance * 3600) / delta_time; // (unit: km/h)
    if (speed > 99.99)
      speed =  99.99;

    // Get cadence (unit: round/second)
    cadence = (uint32_t) (present_crank * 60 / delta_time);
    int cadence_5 = cadence / 5;
    if (cadence % 10 >= 5)
      cadence_5 ++;
    cadence = cadence_5 * 5; // Precision: 5 round (unit: round/second)
    if (cadence > 999)
      cadence = 999;

    // 3. Refresh Segment
    uint32_t display_int, display_frac; //  This coding is to save more energy
    if (mode == 0xA){ 
      display_int  = (uint32_t) distance; // km
      display_frac = (uint32_t) ((distance - display_int) * 100); // km
    }
    else if (mode == 0xB){
      display_int  = present_time / 3600; // hour
      display_frac = (present_time % 3600) / 60; // minute
    }
    else if (mode == 0xC){
      display_int  = (uint32_t) speed; // km/h
      display_frac = (uint32_t) ((speed - display_int) * 100); // km/h
    }
    else if (mode == 0xD){
      display_int  = cadence; // r/s
      display_frac = 0; // nothing to show
    }

    display_segment(mode, int2bcd(display_int), int2bcd(display_frac));

    // 4. Furture Design
    // check_speed();
    // get_oled_image(delta_distance, speed, ave_speed, energe, max_speed, delta_time, present_crank, switchDisplay, is_night);
    // display_oled();

  }
}

