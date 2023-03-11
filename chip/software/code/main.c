//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  ChangXin Shen & Clark Pu
// Team:    C4 Chip Designed
// Version: 5.3
// Verification: Verified SoC.
// Comment: This is a test of hardware functions
//------------------------------------------------------------------------------

#define __MAIN_C__
#include <stdint.h>
#include <stdbool.h>

//------------------------------------------------------------------------------
// Hardware Address
//------------------------------------------------------------------------------

#define AHB_SOFTWARE_DEBUG       0xD0000000
#define AHB_OLEDR_MANAGER_BASE   0xC0000000
#define AHB_SEGMENT_MANAGER_BASE 0xA0000000
#define AHB_TIMER_BASE           0x80000000
#define AHB_SENSOR_MANAGER_BASE  0x60000000
#define AHB_BUTTON_MANAGER_BASE  0x40000000
volatile uint32_t* DEBUG   = (volatile uint32_t*) AHB_SOFTWARE_DEBUG;
// DEBUG[n]                      This is software a debug address
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
// Globle Variables
//------------------------------------------------------------------------------

bool speed_red, isNight, switchDisplay;
float distance, speed, max_speed, total_distance, post_distance;
uint32_t mode, wheel, wheel_d;
uint32_t time, now_time, post_time, time_h, time_m, time_h_bcd, time_m_bcd;
uint32_t crank, bike_fork;
uint32_t speed_f, speed_b, speed_f_bcd, speed_b_bcd;
uint32_t total_distance_f, total_distance_b, total_distance_f_bcd, total_distance_b_bcd;
uint32_t cadence, cadence_bcd;
uint32_t stop_time_mode, post_fork, fork_equal, now_stop_time, post_stop_time, stop_time, store_stop_time;

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
void    clear_timer_long(void){TIMER[0] = 0; post_time = 0; return;}
void     display_segment(uint32_t Mode, uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; SEGMENT[2] = Mode; return;}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

uint32_t int2bcd(uint32_t value){

    uint32_t bcd = 0;
    uint32_t shift = 0;

    while (value != 0) {

      uint32_t num = value % 10;
      bcd = bcd | (num << shift);
      value = value / 10;
      shift = shift + 4;

    }

    return bcd;

}

void check_time_stop(void) {

  bike_fork = read_fork();

  if (stop_time_mode == 0) {

    if (bike_fork == post_fork) {

      fork_equal = fork_equal + 1;
      now_stop_time = read_time_long();

      if (fork_equal == 1) {

        post_stop_time = now_stop_time;
        store_stop_time = now_stop_time;

      }

      stop_time = now_stop_time - post_stop_time;

      if (stop_time >= 6) {

        stop_time_mode = 1;

      }

      post_stop_time = now_stop_time;

    } else {

      fork_equal = 0;
      store_stop_time = 0;

    }

  } else {

    if (bike_fork != post_fork) {

      stop_time_mode = 0;
      TIMER[0] = store_stop_time;

    }

  }

  post_fork = bike_fork;

  return;

}

bool wait_for_press(void){

  // 若三秒内没有按下，则返回假
  while(1) {

    check_time_stop();

    if (check_button())

      return true;

    else if (time_up()) {

      read_time_short();

      return false;

    }

  }

}

void wait_for_setting(void) {

  uint32_t press_times = 0;
  uint32_t wheel_1, wheel_2, wheel_3;
  uint32_t wheel_f_bcd;

  check_time_stop();

  wheel_f_bcd = int2bcd(wheel);
  display_segment(0xE, wheel_f_bcd, 0);

  while (1){

    wheel_3 = wheel / 100;
    wheel_2 = (wheel - wheel_3 * 100) / 10;
    wheel_1 = (wheel - wheel_3 * 100) - (wheel_2 * 10);

    if (check_button()) {
          
      if (press_mode()) {

        press_times ++;
        if (press_times == 3) {

          return;
             
        }

      } else if(press_trip()) {

        if (press_times == 0) {
            
            wheel_3 = (wheel_3 + 1) % 10;
                
        } else if (press_times == 1) {
               
            wheel_2 = (wheel_2 + 1) % 10;               

        } else if (press_times == 2) {                
                
            wheel_1 = (wheel_1 + 1) % 10;
                
        }
            
        wheel = wheel_3 * 100 + wheel_2 * 10 + wheel_1;
        wheel_f_bcd = int2bcd(wheel);
        display_segment(0xE, wheel_f_bcd, 0);
          //get_setting_image();
          //display_oled();

      }

    }

  }  

}

void check_speed(void){

  if (max_speed < speed)
      max_speed = speed;
  if (max_speed > 40)
      speed_red = true;
  else
      speed_red = false;
  return;

}

float get_distance(uint32_t bike_fork, uint32_t wheel){

  float f_distance, f_distance_mm, f_distance_m;

  f_distance_mm = bike_fork * wheel;
  f_distance_m = f_distance_mm / 1000;
  f_distance = f_distance_m / 1000 + 0.01;

  if (f_distance > 99.99) {

    return f_distance = 99.99;

  } else {

    return f_distance;

  }

}

float get_speed(float distance, uint32_t time){

  float f_speed;

  if (time == 0) {

    f_speed = 0;

  } else {

    f_speed = (distance * 3600) / time;

  }
  
  if (f_speed > 99.99) {

    return f_speed = 99.99;

  } else {

    return f_speed;

  }

}

uint32_t get_cadence(uint32_t crank, uint32_t time){

  float cadence, cadence_5;

  if (time == 0) {

    cadence = 0;

  } else {

    cadence = (crank * 60) / time;
    cadence_5 = cadence / 5;
    cadence = (uint32_t) (5 * cadence_5);

  }

  if (cadence > 999) {

    return cadence = 999;

  } else {

    return cadence;

  }

}

void refresh_segment(void) {

  if (mode == 0xA){

    display_segment(mode, total_distance_f_bcd, total_distance_b_bcd);

  } else if (mode == 0xB) {

    display_segment(mode, time_h_bcd, time_m_bcd);
    

  } else if (mode == 0xC) {

    display_segment(mode, speed_f_bcd, speed_b_bcd);
    

  } else if (mode == 0xD){

    display_segment(mode, cadence_bcd, 0);

  }

}

void initiate(void) {

  post_time = 0;
  wheel = 700;
  wheel_d = 2136;
  speed_red = false;
  isNight = false;
  switchDisplay = false;
  distance = 0;
  speed_f = 0;
  speed_b = 0;
  max_speed = 0;
  total_distance_f = 0;
  total_distance_b = 0;
  post_distance = 0;
  mode = 0xA;
  stop_time_mode = 0;
  post_fork = 0;

  display_segment(mode, total_distance_f, total_distance_b);
  //display_oled();

  return;
    
}

//------------------------------------------------------------------------------
// Main Function
//------------------------------------------------------------------------------

int main(void) {

  initiate();

    // repeat forever (embedded programs generally do not terminate)
  while(1) {

    check_time_stop();

    if (wait_for_press()) { // 等待三秒或等待按钮按下后

    // 按钮按下后，处理按钮操作
      if (setting()) {
        
        // 设置操作，更改wheel 
        wait_for_setting();

      } else {

        if (press_trip()) {

          total_distance = 0;
          clear_fork();
          post_time = 0;
          clear_timer_long();

          if (mode == 0xA){    

            display_segment(mode, 0, 0);

          } else if (mode == 0xB) {           
 
            display_segment(mode, 0, 0);

          }
               
        } else if (press_mode()) {     // A里程  B时间  C速度  D踏频  E设置

          if (mode == 0xA){

            mode = 0xB;
            display_segment(mode, time_h_bcd, time_m_bcd);

          } else if (mode == 0xB) {

            mode = 0xC;
            display_segment(mode, speed_f_bcd, speed_b_bcd);

          } else if (mode == 0xC) {

            mode = 0xD;
            display_segment(mode, cadence_bcd, 0);

          } else if (mode == 0xD){

            mode = 0xA;
            display_segment(mode, total_distance_f_bcd, total_distance_b_bcd);

          }
            switchDisplay = true;

        } else if (press_d_mode()) {

          isNight = ~ isNight;

        }

      }

    }
    // 按钮按下则在处理完按钮操作后立即刷新，没有按下则三秒刷新一次
    
    crank = read_crank();

    check_time_stop();
    
    total_distance = get_distance(bike_fork, wheel_d);
    distance = total_distance - post_distance;
    post_distance = total_distance;
    total_distance_f = (uint32_t) total_distance;
    total_distance_b = (uint32_t) ((total_distance - total_distance_f) * 100);
    total_distance_f_bcd = int2bcd(total_distance_f);
    total_distance_b_bcd = int2bcd(total_distance_b);

    if (stop_time_mode == 1) {

      now_time = store_stop_time;

    } else {

      now_time = read_time_long();

    }
    
    time = now_time - post_time;
    speed = get_speed(distance, time);
    post_time = now_time;

    time_h = now_time / 3600;
    time_m = (now_time % 3600) / 60;
    time_h_bcd = int2bcd(time_h);
    time_m_bcd = int2bcd(time_m);
    
    speed_f = (uint32_t) speed;
    speed_b = (uint32_t) ((speed - speed_f) * 100);
    speed_f_bcd = int2bcd(speed_f);
    speed_b_bcd = int2bcd(speed_b);

    cadence = get_cadence(crank, time);
    cadence_bcd = int2bcd(cadence);

    check_speed();

    refresh_segment();

    //display_segment(total_distance_f, total_distance_b);

    //get_oled_image(distance, speed, ave_speed, energe, max_speed, time, crank, switchDisplay, isNight);
    //display_oled();

    switchDisplay = false;
  }
}

