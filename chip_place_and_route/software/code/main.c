//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  Clark Pu & ChangXin Shen
// Team:    C4 Chip Designed
// Version: 6.2 New OLED Manager
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

// OLED MANAGER
// Memory Map:
// C[0]:     | Mode       : 0: Auto, 1: Normal
// C[1]:     | Normal Mode: 2 bit D/C: 1/0 2: self update
// C[2]:     | Normal Mode: 1 bit Ready flag.
// C[3]:     | Normal Mode: 8 bit data.
// C[4 + n]: | Pixel Block: 0 ~ n. Write Only
volatile uint32_t* OLED = (volatile uint32_t*) AHB_OLEDR_MANAGER_BASE;
bool oled_ready(void){return OLED[2]?true:false;}
void  oled_mode(bool IsNormal){OLED[0] = IsNormal?1:0; return;}
void  oled_send(uint32_t Data, bool DnC){while(!oled_ready()); OLED[1] = DnC?1:0; OLED[3] = Data; OLED[2] = 0; return;}
void oled_block(int BlockID, uint32_t ResourceID){OLED[BlockID + 4] = ResourceID; return;}

// SEGMENT MANAGER
// SEGMENT[0]     Fraction       0xA0000000
// SEGMENT[1]     Integer        0xA0000004
// SEGMENT[2]     Mode           0xA0000008
volatile uint32_t* SEGMENT = (volatile uint32_t*) AHB_SEGMENT_MANAGER_BASE;
void display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; SEGMENT[2] = Mode; return;}

// TIMER
// 8000_0000: 32bit | Trip timer records less than 18 hours
// 8000_0004: 32bit | 3 second flag
volatile uint32_t* TIMER = (volatile uint32_t*) AHB_TIMER_BASE;
bool            time_up(void){return  TIMER[1]?true:false;}
uint32_t read_trip_time(void){return  TIMER[0];}
void       claim_update(void){TIMER[1] = 0; return;}
void   clear_trip_timer(void){TIMER[0] = 0; return;}

// SENSOR MANAGER
// 6000_0000: 32bit | Recording triggerd fork cycle number
// 6000_0004: 32bit | Recording triggerd 1 cycle crank time
// 6000_0008: 32bit | Recording triggerd 1 cycle fork time
volatile uint32_t* SENSOR  = (volatile uint32_t*) AHB_SENSOR_MANAGER_BASE;
uint32_t          read_fork(void){return SENSOR[0];}
void             clear_fork(void){SENSOR[0] = 0; return;}
float  read_delta_fork_time(void){return (float)(SENSOR[2]);}
float read_delta_crank_time(void){return (float)(SENSOR[1]);}

// BUTTON MANAGER
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
    present_fork, 
    present_cadence;
  float 
    delta_crank_time,
    delta_fork_time,
    present_distance, 
    present_speed;

  // general initiate
  wheel_girth = 2136; // setting
  is_night = false;
  last_time = 0;
  mode = 0xA;
  display_segment(mode, 0, 0);

  // oled initiate
  int test_change = 1;
  oled_mode(true);
  oled_send(0xAA, true);
  for (int i = 0; i < 32; i++)
    oled_block(i, test_change);
  oled_mode(false);

  // process start
  while(1) {

    // I. Button interrupted 3 seconds wait

    if (wait_for_press()){
      if (setting())
        wheel_girth = wait_for_wheel_girth(wheel_girth);
      else if (check_trip() != 0){
        clear_fork();
        clear_trip_timer();
        last_time = 0;
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
    present_time     = read_trip_time();
    present_fork     = read_fork();
    delta_fork_time  = read_delta_fork_time();
    delta_crank_time = read_delta_crank_time();
    claim_update();

    // 2. Calculate

    // Get present distance (unit: km) present_distance < 99.99;
    present_distance = (float)(present_fork * wheel_girth) / 1e6 + 0.01; // Number 0.01 is a bias.
    
    // Get speed (unit: km/h) : present_speed < 99.99
    if (delta_fork_time < 2990)
      present_speed = 3.6 * wheel_girth / delta_fork_time;
    else
      present_speed = 0;

    // Get cadence (unit: round/second) : present_cadence < 999
    if (delta_crank_time < 2990)
      present_cadence = (uint32_t)(12 / (delta_crank_time / 1000)) * 5; // Precision: 5 round
    else
      present_cadence = 0;

    // Get present time (unit: second)
    if (delta_fork_time > 2990) // if bicycle stopped
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
    // Over than 3s Test
    if (test_change > 8)
      test_change = 0;
    else
      test_change ++;
    for (int i = 0; i < 32; i++)
        oled_block(i, test_change);
  }
}
