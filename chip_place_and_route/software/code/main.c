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

# define    IMG_candence1    10
# define    IMG_candence2    11
# define    IMG_colo         12
# define    IMG_distance1    13
# define    IMG_distance2    14
# define    IMG_dot          15
# define    IMG_empty        16
# define    IMG_h            17
# define    IMG_k            18
# define    IMG_m            19
# define    IMG_rpm1         20
# define    IMG_rpm2         21
# define    IMG_setting1     22
# define    IMG_setting2     23
# define    IMG_speed1       24
# define    IMG_speed2       25
# define    IMG_timer1       26
# define    IMG_timer2       27
# define    IMG_underline    28

# define    ODOMETER         0xA
# define    DURATION         0xB
# define    SPEED            0xC
# define    CADENCE          0xD
# define    SETTING          0xE

// OLED MANAGER
// C[0]:     | Mode       : 0: Auto, 1: Normal
// C[1]:     | Normal Mode: 2 bit D/C: 1/0 2: self update
// C[2]:     | Normal Mode: 1 bit Ready flag.
// C[3]:     | Normal Mode: 8 bit data.
// C[4 + n]: | Pixel Block: 0 ~ n. Write Only
volatile uint32_t* OLED = (volatile uint32_t*) AHB_OLEDR_MANAGER_BASE;
bool oled_ready(void){return OLED[2]?true:false;}
void  oled_mode(bool IsNormal){OLED[0] = IsNormal?1:0; return;}
void  oled_send(uint32_t Data, bool DnC){OLED[1] = DnC?1:0; OLED[3] = Data; OLED[2] = 0; return;}
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
void   write_trip_timer(int new_time){TIMER[0] = new_time; return;}

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
bool       press_ui(void){return BUTTON[0]?true:false;}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

void oled_float_display(int num_int, int num_frac, int num1, int num2, int num3, int num4){
  if (num_int > 9)
    oled_block(num1, num_int / 10 % 10);
  else
    oled_block(num1, IMG_empty);
  oled_block(num2, num_int % 10);
  oled_block(num3, num_frac / 10 % 10);
  oled_block(num4, num_frac % 10);
}

void oled_cadence_display(int present_cadence, int num1, int num2, int num3, int num4){
  oled_block(num1, IMG_empty);
  if (present_cadence > 99){
    oled_block(num2, present_cadence / 100 % 10);
    oled_block(num3, present_cadence / 10 % 10);
    oled_block(num4, present_cadence % 10);
  }
  else if (present_cadence > 9){
    oled_block(num2, IMG_empty);
    oled_block(num3, present_cadence / 10 % 10);
    oled_block(num4, present_cadence % 10);
  }
  else{
    oled_block(num2, IMG_empty);
    oled_block(num3, IMG_empty);
    oled_block(num4, present_cadence % 10);
  }
}

void oled_icon_display(int pic1, int pic2, int pic3, int pic4, int pic5, int pic6,int pic7, int pic8, int pic9){
  // main icon 
  oled_block(0, pic1);
  oled_block(1, pic2);
  oled_block(12, pic3);
  // sub icon 
  oled_block(13, pic4);
  oled_block(14, pic5);
  oled_block(19, pic6);
  // main unit
  oled_block(9, pic7);
  oled_block(10, pic8);
  oled_block(11, pic9);
}

void oled_update_icon(int mode){
  // 0xA: Odometer  0xB: Duration  0xC: Speed  0xD: Cadence
  if (mode == ODOMETER)
    oled_icon_display(IMG_distance1, IMG_distance2, IMG_dot, IMG_timer1, IMG_timer2, IMG_colo, IMG_k, IMG_m, IMG_empty);
  else if (mode == DURATION)
    oled_icon_display(IMG_timer1, IMG_timer2, IMG_colo, IMG_speed1, IMG_speed2, IMG_dot, IMG_empty, IMG_empty, IMG_empty);
  else if(mode == SPEED)
    oled_icon_display(IMG_speed1, IMG_speed2, IMG_dot, IMG_candence1, IMG_candence2, IMG_empty, IMG_k, IMG_m, IMG_h);
  else
    oled_icon_display(IMG_candence1, IMG_candence2, IMG_empty, IMG_distance1, IMG_distance2, IMG_dot, IMG_rpm1, IMG_rpm2, IMG_m);
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
  for (int i = 0; i < 20; i++)
    oled_block(i, IMG_empty);
  oled_block(0, IMG_setting1);
  oled_block(1, IMG_setting2);
  oled_block(3, IMG_underline);
  oled_block(9, IMG_m);
  oled_block(10, IMG_m);
  oled_block(2, 2);
  oled_block(4, wheel_3);
  oled_block(6, wheel_2);
  oled_block(8, wheel_1);
  display_segment(0xE, int2bcd(wheel_girth % 1000), 0);
  while (1){
    if (check_button()) {
      press_times += check_mode();
      if (press_times > 2){
        oled_block(7, IMG_empty);
        return wheel_girth;
      }
      if (press_times == 0){
        wheel_3 = (wheel_3 + check_trip()) % 10;
      }
      else if (press_times == 1){
        wheel_2 = (wheel_2 + check_trip()) % 10;
        oled_block(3, IMG_empty);
        oled_block(5, IMG_underline);
      }
      else if (press_times == 2){
        wheel_1 = (wheel_1 + check_trip()) % 10;
        oled_block(5, IMG_empty);
        oled_block(7, IMG_underline);
      }
      wheel_girth = 2000 + wheel_3 * 100 + wheel_2 * 10 + wheel_1;
      display_segment(SETTING, int2bcd(wheel_girth % 1000), 0); // 0xE: Setting
      oled_block(4, wheel_3);
      oled_block(6, wheel_2);
      oled_block(8, wheel_1);
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
  mode = ODOMETER;  // 0xA: Odometer  0xB: Duration  0xC: Speed  0xD: Cadence
  display_segment(mode, 0, 0);

  // oled software initiate
  oled_mode(true); // normal 8 bit sending mode
  oled_send(0xFD, false); // CMD: unlock all commands
  oled_send(0xB1, true);
  oled_send(0xCA, false); // CMD: set MUX ratio to fit 128*96 OLED screen
  oled_send(0x5F, true);
  oled_send(0xA2, false); // CMD: set start row
  oled_send(0x00, true); 
  oled_send(0xA0, false); // CMD: set colour format
  oled_send(0x74, true);
  oled_send(0xC1, false); // CMD: set colour contrast
  oled_send(0xC8, true);
  oled_send(0x80, true);
  oled_send(0xC8, true);
  oled_send(0xAF, false); // CMD: display on (Debug)
  oled_send(0x15, false); // CMD: set col (Debug)
  oled_send(0x00, true);  // (Debug)
  oled_send(0x7F, true);  // (Debug)
  oled_send(0x75, false); // CMD: set row (Debug)
  oled_send(0x00, true);  // (Debug)
  oled_send(0x5F, true);  // (Debug)
  oled_send(0x5C, false); // CMD: send pixels
  // for (int i = 0; i < 128 * 96 * 2; i++)
  //   oled_send(0xFF, true); // DATA: white colour0, colour1
  
  // oled auto initiate
  oled_mode(false); // auto block update mode
  for (int i = 0; i < 20; i++)
    oled_block(i, IMG_empty);
  oled_icon_display(IMG_distance1, IMG_distance2, IMG_dot, IMG_timer1, IMG_timer2, IMG_colo, IMG_k, IMG_m, IMG_empty);
  
  // process start
  while(1) {

    // I. Button interrupted 3 seconds wait

    if (wait_for_press()){
      if (setting()){
        wheel_girth = wait_for_wheel_girth(wheel_girth);
        mode = ODOMETER;
        oled_update_icon(mode);
      }
      else if (check_trip() != 0){
        clear_fork();
        write_trip_timer(0);
        last_time = 0;
      } 
      else if (press_ui()){
        is_night = ! is_night;
        is_night ? oled_send(0xA7, false) : oled_send(0xA6, false); // night mode : day mode
      }
      else{
        mode = mode + check_mode() % 4;
        if (mode > CADENCE)
          mode = mode - 4;
        oled_update_icon(mode);
      }
    }

    // II. Update Time, Speed, Distance, Cadence.
    
    // 1. Time Stamp Data Read

    present_time     = read_trip_time();
    present_fork     = read_fork();
    delta_fork_time  = read_delta_fork_time();
    delta_crank_time = read_delta_crank_time();
    claim_update();

    // 2. Calculate

    // Get present distance (unit: km) present_distance < 99.99;
    present_distance = (float)(present_fork * wheel_girth) / 1e6 + 0.01; // Number 0.01 is a bias.
    if (present_distance < 0.02)
      present_distance = 0;
    
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
    if (delta_fork_time > 2990){ // if bicycle stopped
      present_time = last_time;
      write_trip_timer(last_time);
    }
    last_time = present_time;

    // 3. Refresh Segment & OLED

    uint32_t main_int, main_frac, sub_int, sub_frac;

    if (mode == ODOMETER){
      main_int  = (uint32_t) present_distance; // km
      main_frac = (uint32_t) ((present_distance - main_int) * 100); // km
      sub_int  = present_time / 3600; // hour
      sub_frac = (present_time % 3600) / 60; // minute
      oled_float_display(main_int, main_frac, 2, 4, 6, 8);
      oled_float_display(sub_int, sub_frac, 15, 16, 17, 18);
    }
    else if (mode == DURATION){
      main_int  = present_time / 3600; // hour
      main_frac = (present_time % 3600) / 60; // minute
      sub_int  = (uint32_t) present_speed; // km/h
      sub_frac = (uint32_t) ((present_speed - sub_int) * 100); // km/h
      oled_float_display(main_int, main_frac, 2, 4, 6, 8);
      oled_float_display(sub_int, sub_frac, 15, 16, 17, 18);
    }
    else if (mode == SPEED){
      main_int  = (uint32_t) present_speed; // km/h
      main_frac = (uint32_t) ((present_speed - main_int) * 100); // km/h
      oled_float_display(main_int, main_frac, 2, 4, 6, 8);
      oled_cadence_display(present_cadence, 15, 16, 17, 18);
    }
    else if (mode == CADENCE){
      main_int  = present_cadence; // r/s
      main_frac = 0; // nothing to show
      sub_int  = (uint32_t) present_distance; // km
      sub_frac = (uint32_t) ((present_distance - sub_int) * 100); // km
      oled_cadence_display(present_cadence, 2, 4, 6, 8);
      oled_float_display(sub_int, sub_frac, 15, 16, 17, 18);
    }

    display_segment(mode, int2bcd(main_int), int2bcd(main_frac));

  }
}
