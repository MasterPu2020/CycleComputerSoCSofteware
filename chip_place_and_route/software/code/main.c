//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  Clark Pu & ChangXin Shen
// Team:    C4 Chip Designed
// Version: 6.3 Use Only 6 ROM cells
// Verification: Not Verified
// Comment: Redesigned by Clark
//------------------------------------------------------------------------------

# define __MAIN_C__
# include <stdint.h>
# include <stdbool.h>

# define    AHB_OLEDR_MANAGER_BASE      0xC0000000
# define    AHB_SEGMENT_MANAGER_BASE    0xA0000000
# define    AHB_TIMER_BASE              0x80000000
# define    AHB_SENSOR_MANAGER_BASE     0x60000000
# define    AHB_BUTTON_MANAGER_BASE     0x40000000

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

//------------------------------------------------------------------------------
// Hardware Address &  Access Functions
//------------------------------------------------------------------------------

// OLED MANAGER
// [0] C000_0000: 1bit | Mode        : 0 for Auto, 1 for Normal.
// [1] C000_0004: 1bit | Normal Mode : 0 for Command 1 for Data.
// [2] C000_0008: 1bit | Normal Mode : 0 for send data.
// [3] C000_000C: 8bit | Normal Mode : 8 bit data.
// [4 + n]        4bit | Pixel Block : 0 ~ n. Write Only
volatile uint32_t* OLED = (volatile uint32_t*) AHB_OLEDR_MANAGER_BASE;

// SEGMENT MANAGER
// [0] A000_0000: 8bit  | Storing BCD code of the fraction part
// [1] A000_0004: 12bit | Storing BCD code of the integer part
// [2] A000_0008: 4bit  | Storing Mode Information
volatile uint32_t* SEGMENT = (volatile uint32_t*) AHB_SEGMENT_MANAGER_BASE;

// TIMER
// [0] 8000_0000: 16bit | Trip timer records less than 18 hours
// [1] 8000_0004: 1bit  | 3 second flag
volatile uint32_t* TIMER = (volatile uint32_t*) AHB_TIMER_BASE;

// SENSOR MANAGER
// [0] 6000_0000: 16bit | Recording triggerd fork cycle number
// [1] 6000_0004: 16bit | Recording triggerd 1 cycle crank time
// [2] 6000_0008: 16bit | Recording triggerd 1 cycle fork time
volatile uint32_t* SENSOR  = (volatile uint32_t*) AHB_SENSOR_MANAGER_BASE;

// BUTTON MANAGER
// [0] 4000_0000: 1bit  | DayNight Switch Flag
// [1] 4000_0004: 4bit  | Mode Switch Times
// [2] 4000_0008: 4bit  | Trip Clear Times
// [3] 4000_000C: 1bit  | Wheel Setting Flag
// [4] 4000_0010: 1bit  | New button pressed Flag
volatile uint32_t* BUTTON  = (volatile uint32_t*) AHB_BUTTON_MANAGER_BASE;

// In Normal mode, send 8 bit data or command to OLED
void  oled_send(uint32_t Data, bool DnC){
  OLED[1] = DnC?1:0; 
  OLED[3] = Data; 
  OLED[2] = 0; 
  return;
}

// In Auto mode, let hardware manage sending a block of a picture to OLED
void oled_block(int BlockID, uint32_t PictureID){
  OLED[BlockID + 4] = PictureID;
  return;
}

// Both integer and fraction must be in a BCD coding style
void display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){
  SEGMENT[0] = Fraction; 
  SEGMENT[1] = Integer; 
  SEGMENT[2] = Mode; 
  return;
}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

// In Auto mode, let hardware manage sending all block with blank picture to OLED
void oled_block_clear(void){
  for (int i = 0; i < 20; i++)
    oled_block(i, IMG_empty);
  return;
}

// In Auto mode, display a 00.00 format number to OLED 
// input : Integer, Fraction, Block ID for 4 digits
void oled_float_display(int num_int, int num_frac, int id1, int id2, int id3, int id4){
  if (num_int < 10)
    oled_block(id1, IMG_empty);
  else
    oled_block(id1, num_int / 10 % 10);
  oled_block(id2, num_int % 10);
  oled_block(id3, num_frac / 10 % 10);
  oled_block(id4, num_frac % 10);
  return;
}

// In Auto mode, display a 000 format number to OLED 
// input : Integer, Block ID for 4 digits
void oled_int_display(int num_int, int id1, int id2, int id3, int id4){
  oled_block(id1, IMG_empty);
  if (num_int < 100)
    oled_block(id2, IMG_empty);
  else
    oled_block(id2, num_int / 100 % 10);
  if (num_int < 10)
    oled_block(id3, IMG_empty);
  else
    oled_block(id3, num_int / 10 % 10);
  oled_block(id4, num_int % 10);
  return;
}

// In Auto mode, display main and subsidiary icons and main unit to OLED
// input : 
//   3 picture ID for main icon
//   3 picture ID for subsidiary icon 
//   3 picture ID for main unit
void oled_icon_display(
  int pic1, int pic2, int pic3, 
  int pic4, int pic5, int pic6,
  int pic7, int pic8, int pic9){
  // main icon 
  oled_block(0, pic1);
  oled_block(1, pic2);
  oled_block(12, pic3);
  // subsidiary icon 
  oled_block(13, pic4);
  oled_block(14, pic5);
  oled_block(19, pic6);
  // main unit
  oled_block(9, pic7);
  oled_block(10, pic8);
  oled_block(11, pic9);
  return;
}

// In Auto mode, display main and subsidiary icons and main unit to OLED
void oled_update_icon(int mode){
  if (mode == ODOMETER)
    oled_icon_display(
      IMG_distance1, IMG_distance2, IMG_dot, 
      IMG_timer1,    IMG_timer2,    IMG_colo, 
      IMG_k,         IMG_m,         IMG_empty);
  else if (mode == DURATION)
    oled_icon_display( 
      IMG_timer1,    IMG_timer2,    IMG_colo, 
      IMG_speed1,    IMG_speed2,    IMG_dot, 
      IMG_empty,     IMG_empty,     IMG_empty);
  else if(mode == SPEED)
    oled_icon_display( 
      IMG_speed1,    IMG_speed2,    IMG_dot, 
      IMG_candence1, IMG_candence2, IMG_empty, 
      IMG_k,         IMG_m,         IMG_h);
  else
    oled_icon_display( 
      IMG_candence1, IMG_candence2, IMG_empty, 
      IMG_distance1, IMG_distance2, IMG_dot, 
      IMG_rpm1,      IMG_rpm2,      IMG_m);
  return;
}

// Encode integer with BCD style
uint32_t int2bcd(uint32_t value){
    uint32_t bcd = 0, shift = 0;
    while (value != 0) {
      bcd = bcd | ((value % 10) << shift);
      value = value / 10;
      shift = shift + 4;
    }
    return bcd;
}

// Busily waiting for button press until timer flag raises
bool wait_for_press(void){
  while(1)
    if (BUTTON[4])
      return true;
    else if (TIMER[1])
      return false;
}

// Busily waiting and dealing with setting operation and displays
uint32_t wait_for_wheel_girth(uint32_t wheel_girth) {
  int press_times = 0;
  int wheel_3 = wheel_girth / 100 % 10;
  int wheel_2 = wheel_girth / 10 % 10;
  int wheel_1 = wheel_girth % 10;
  oled_block_clear();
  oled_block(0, IMG_setting1);
  oled_block(1, IMG_setting2);
  oled_block(3, IMG_underline);
  oled_block(9, IMG_m);
  oled_block(10, IMG_m);
  oled_block(2, 2);
  while (1){
    oled_block(4, wheel_3);
    oled_block(6, wheel_2);
    oled_block(8, wheel_1);
    display_segment(SETTING, int2bcd(wheel_girth % 1000), 0);
    if (BUTTON[4]) {
      press_times += BUTTON[1];
      if (press_times > 2){
        oled_block(7, IMG_empty);
        return wheel_girth;
      }
      if (press_times == 0){
        wheel_3 = (wheel_3 + BUTTON[2]) % 10;
      }
      else if (press_times == 1){
        wheel_2 = (wheel_2 + BUTTON[2]) % 10;
        oled_block(3, IMG_empty);
        oled_block(5, IMG_underline);
      }
      else if (press_times == 2){
        wheel_1 = (wheel_1 + BUTTON[2]) % 10;
        oled_block(5, IMG_empty);
        oled_block(7, IMG_underline);
      }
      wheel_girth = 2000 + wheel_3 * 100 + wheel_2 * 10 + wheel_1;
    }
  }
}

//------------------------------------------------------------------------------
// Main Function
//------------------------------------------------------------------------------

int main(void) {

  // general initiate
  bool is_night_mode = false;
  uint32_t 
    mode = ODOMETER,
    wheel_girth = 2136;
  uint32_t 
    distance_int, distance_frac,
    time_int, time_frac,
    speed_int, speed_frac;
  uint32_t 
    present_time, 
    last_time = 0,
    present_fork,
    present_cadence;
  float 
    delta_crank_time,
    delta_fork_time,
    present_distance, 
    present_speed;
  display_segment(mode, 0, 0);

  // oled software initiate
  OLED[0] = 1;
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
  oled_send(0xAF, false); // CMD: display on
  oled_send(0x5C, false); // CMD: send pixels
  for (int i = 0; i < 128 * 96 * 2; i++)
    oled_send(0xFF, true); // DATA: white colour0, colour1
  
  // oled hardware auto initiate
  OLED[0] = 0;
  oled_block_clear();
  TIMER[1] = 0;
  oled_update_icon(mode);
  
  // process start
  while(1) {

    //------------------------------------------------------------------------------
    // I. Button interrupted 3 seconds wait
    //------------------------------------------------------------------------------

    if (wait_for_press()){
      if (BUTTON[3]){
        wheel_girth = wait_for_wheel_girth(wheel_girth);
        mode = ODOMETER;
        oled_update_icon(mode);
      }
      else if (BUTTON[2]){
        SENSOR[0] = 0;
        TIMER[0] = 0;
        last_time = 0;
      } 
      else if (BUTTON[0]){
        is_night_mode = ! is_night_mode;
        OLED[0] = 1;
        is_night_mode ? oled_send(0xA7, false) : oled_send(0xA6, false); // night mode : day mode
        OLED[0] = 0;
      }
      else{
        mode += BUTTON[1];
        if (mode > CADENCE)
          mode = mode - 4;
        oled_update_icon(mode);
      }
    }

    //------------------------------------------------------------------------------
    // II. Update Time, Speed, Distance, Cadence.
    //------------------------------------------------------------------------------
    
    // 1. Time Stamp Data Read

    present_time     = TIMER[0];
    present_fork     = SENSOR[0];
    delta_fork_time  = (float) SENSOR[2];
    delta_crank_time = (float) SENSOR[1];
    TIMER[1] = 0; // claim update

    // 2. Calculate

    // Get present distance (unit: km) present_distance < 99.99;
    present_distance = (float)(present_fork * wheel_girth) / 1e6 + 0.01; // Number 0.01 is a bias.
    if (present_distance < 0.02) // Bias will make zero distance always output 0.01. This is to show a zero.
      present_distance = 0;
    
    // Get speed (unit: km/h) : present_speed < 99.99
    if (delta_fork_time < 2990) // If the fork rolls for more than three seconds, it is considered stationary.
      present_speed = 3.6 * wheel_girth / delta_fork_time;
    else
      present_speed = 0;

    // Get cadence (unit: round/second) : present_cadence < 999
    if (delta_crank_time < 2990) // If the crank rolls for more than three seconds, it is considered stationary.
      present_cadence = (uint32_t)(12 / (delta_crank_time / 1000)) * 5; // Precision: 5 round
    else
      present_cadence = 0;

    // Get present time (unit: second)
    if (delta_fork_time > 2990){ // if bicycle stopped
      present_time = last_time;
      TIMER[0] = last_time;
    }
    last_time = present_time;

    //------------------------------------------------------------------------------
    // III. Refresh Segment & OLED
    //------------------------------------------------------------------------------

    distance_int = (uint32_t) present_distance; // km
    distance_frac = (uint32_t) ((present_distance - distance_int) * 100); // km
    time_int = present_time / 3600; // hour
    time_frac = (present_time % 3600) / 60; // minute
    speed_int = (uint32_t) present_speed; // km/h
    speed_frac = (uint32_t) ((present_speed - speed_int) * 100); // km/h

    if (mode == ODOMETER){
      display_segment(mode, int2bcd(distance_int), int2bcd(distance_frac));
      oled_float_display(distance_int, distance_frac, 2, 4, 6, 8);
      oled_float_display(time_int, time_frac, 15, 16, 17, 18);
    }
    else if (mode == DURATION){
      display_segment(mode, int2bcd(time_int), int2bcd(time_frac));
      oled_float_display(time_int, time_frac, 2, 4, 6, 8);
      oled_float_display(speed_int, speed_frac, 15, 16, 17, 18);
    }
    else if (mode == SPEED){
      display_segment(mode, int2bcd(speed_int), int2bcd(speed_frac));
      oled_float_display(speed_int, speed_frac, 2, 4, 6, 8);
      oled_int_display(present_cadence, 15, 16, 17, 18);
    }
    else{
      display_segment(mode, int2bcd(present_cadence), int2bcd(0));
      oled_int_display(present_cadence, 2, 4, 6, 8);
      oled_float_display(distance_int, distance_frac, 15, 16, 17, 18);
    }

  }
}
