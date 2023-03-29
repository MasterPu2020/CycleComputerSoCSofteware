//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  Clark Pu & ChangXin Shen
// Team:    C4 Chip Designed
// Version: 6.0
// Verification: Not Verified
// Comment: Redesigned by Clark
//------------------------------------------------------------------------------

#define __MAIN_C__
#include <stdint.h>
#include <stdbool.h>

//------------------------------------------------------------------------------
// Hardware Address &  Access Functions
//------------------------------------------------------------------------------
#define AHB_OLEDR_MANAGER_BASE   0xC0000000
#define AHB_SEGMENT_MANAGER_BASE 0xA0000000
#define AHB_TIMER_BASE           0x80000000
#define AHB_SENSOR_MANAGER_BASE  0x60000000
#define AHB_BUTTON_MANAGER_BASE  0x40000000
//------------------------------------------------------------------------------
// OLED[0]        DnC            0xC0000000
// OLED[1]        Ready flag     0xC0000004
// OLED[2]        8 bit data     0xC0000008
volatile uint32_t* OLED    = (volatile uint32_t*) AHB_OLEDR_MANAGER_BASE;
bool oled_ready(void){return   OLED[1]?true:false;}
void  oled_send(uint32_t Data, bool DnC){while(!oled_ready()); OLED[0] = DnC?1:0; OLED[2] = Data; OLED[1] = 0; return;}
//------------------------------------------------------------------------------
// SEGMENT[0]     Fraction       0xA0000000
// SEGMENT[1]     Integer        0xA0000004
// SEGMENT[2]     Mode           0xA0000008
volatile uint32_t* SEGMENT = (volatile uint32_t*) AHB_SEGMENT_MANAGER_BASE;
void display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; SEGMENT[2] = Mode; return;}
//------------------------------------------------------------------------------
// TIMER[0]       Long           0x80000000 
// TIMER[1]       Flag           0x80000004 
volatile uint32_t* TIMER   = (volatile uint32_t*) AHB_TIMER_BASE;
bool             time_up(void){return  TIMER[1]?true:false;}
uint32_t  read_trip_time(void){return  TIMER[0];}
void        claim_update(void){TIMER[1] = 0; return;}
void    clear_trip_timer(void){TIMER[0] = 0; return;}
//------------------------------------------------------------------------------
// SENSOR[0]      Fork           0x60000000
// SENSOR[1]      Delta Crank    0x60000004
// SENSOR[2]      Delta Fork     0x60000008
// SENSOR[3]      Crank Time     0x6000000A
// SENSOR[4]      Fork  Time     0x60000010
volatile uint32_t* SENSOR  = (volatile uint32_t*) AHB_SENSOR_MANAGER_BASE;
uint32_t  read_delta_fork(void){return SENSOR[2];}
uint32_t read_delta_crank(void){return SENSOR[1];}
uint32_t        read_fork(void){return SENSOR[0];}
void           clear_fork(void){SENSOR[0] = 0; return;}
float     delta_fork_time(void){return (float)(SENSOR[4]) / 1000;}
float    delta_crank_time(void){return (float)(SENSOR[3]) / 1000;}
//------------------------------------------------------------------------------
// BUTTON[0]      DayNight       0x40000000
// BUTTON[1]      Mode           0x40000004
// BUTTON[2]      Trip           0x40000008
// BUTTON[3]      Setting        0x4000000A
// BUTTON[4]      NewData        0x40000010
volatile uint32_t* BUTTON  = (volatile uint32_t*) AHB_BUTTON_MANAGER_BASE;
bool   check_button(void){return BUTTON[4]?true:false;}
bool        setting(void){return BUTTON[3]?true:false;}
uint32_t check_trip(void){return BUTTON[2];}
uint32_t check_mode(void){return BUTTON[1];}
bool   press_d_mode(void){return BUTTON[0]?true:false;}

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
      press_times += check_mode();
      if (press_times == 3)
        return wheel_girth;
      if (press_times == 0)
        wheel_3 = (wheel_3 + check_trip()) % 10;
      else if (press_times == 1)
        wheel_2 = (wheel_2 + check_trip()) % 10;
      else if (press_times == 2)
        wheel_1 = (wheel_1 + check_trip()) % 10;
      wheel_girth = 2000 + wheel_3 * 100 + wheel_2 * 10 + wheel_1;
      display_segment(0xE, int2bcd(wheel_girth % 1000), 0); // 0xE: Setting
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
    delta_crank,
    delta_fork,
    present_fork, 
    present_cadence;
  float 
    delta_distance, present_distance, 
    present_speed;

  // general initiate
  wheel_girth = 2136; // setting
  is_night = false;
  last_time = 0;
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
      else if (check_trip() != 0){
        clear_fork();
        clear_trip_timer(); 
      } 
      else if (press_d_mode())
        is_night = ~ is_night;
      else{
        mode = mode + check_mode() % 4; // 0xA: Odometer  0xB: Duration  0xC: Speed  0xD: Cadence
        if (mode > 0xD)
          mode = mode - 4;
      }
    }

    // II. Refresh Time, Speed, Distance, Cadence.
    
    // 1. Time Stamp Data Read
    present_time = read_trip_time();
    present_fork = read_fork();
    delta_fork   = read_delta_fork();
    delta_crank  = read_delta_crank();
    claim_update();

    // 2. Calculate

    // Get present distance (unit: km) present_distance < 99.99;
    present_distance = (float)(present_fork * wheel_girth) / 1e6 + 0.01; // Number 0.01 is a bias.
    
    // Get speed (unit: km/h) : present_speed < 99.99
    delta_distance = (float)(delta_fork * wheel_girth) / 1e6;
    present_speed = (delta_distance * 3600) / delta_fork_time();

    // Get cadence (unit: round/second) : present_cadence < 999
    present_cadence = (uint32_t)(delta_crank * 12 / delta_crank_time()) * 5; // Precision: 5 round

    // Get present time (unit: second)
    if (delta_distance == 0) // if bicycle stopped
      present_time = last_time;
    last_time = present_time;

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

    // 4. Refresh OLED
    // Test with 100 pixels
    oled_fill_area(0,0,10,10,false); // fill a square

  }
}
