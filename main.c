//------------------------------------------------------------------------------
// Titile:  Cortex M0 Software Main C File
// Author:  ChangXin Shen & Clark Pu & Chen Paiyun
// Team:    C4 Chip Designed
// Version: 1.3
// Verification: Verified with SoC.
// Comment: 
//   This is a SoC software main function.
//   Using UTF-8.
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

bool     speed_red, isNight, switchDisplay;
float    distance, speed, max_speed, total_distance, post_distance;
uint32_t mode, wheel;
uint32_t time, now_time, post_time, time_h, time_m;
uint32_t crank, bike_fork;
uint32_t speed_f, speed_b;
uint32_t total_distance_f, total_distance_b;
uint32_t cadence;

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
void     display_segment(uint32_t Integer, uint32_t Fraction){SEGMENT[0] = Fraction; SEGMENT[1] = Integer; return;}

//------------------------------------------------------------------------------
// Compound Functions
//------------------------------------------------------------------------------

bool wait_for_press(void){
  // 若三秒内没有按下，则返回假
  while(1){
    if(check_button())
      return true;
    else if (time_up()) {
      read_time_short();
      return false;
    }
  }
}

void wait_for_setting(void){

    uint32_t press_times = 0;
    uint32_t wheel_1, wheel_2, wheel_3;

    while (1){

        wheel_3 = wheel / 100;
        wheel_2 = (wheel - wheel_3 * 100)/10;
        wheel_1 = (wheel - wheel_3 * 100) - (wheel_2 * 10);

        if(check_button()){
          
          if(press_mode()){

            press_times ++;
            if (press_times == 3){

              return;
             
            }

          } else if(press_trip()){

            if(press_times == 0){
            
                wheel_1 = (wheel_1 + 1) % 10;
                
            } else if(press_times == 1){
               
                wheel_2 = (wheel_2 + 1) % 10;               

            } else if(press_times == 2){                
                
                wheel_3 = (wheel_3 + 1) % 10;
                
            }
            
            wheel = wheel_3 * 100 + wheel_2 * 10 + wheel_1;
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

  float f_distance;
  const float PI = 3.14;

  return f_distance = bike_fork * ( PI * wheel/1000)/1000;

}

float get_speed(float distance, uint32_t time){

  float f_speed;

  return f_speed = (distance * 3600)/time;

}

uint32_t get_cadence(uint32_t crank, uint32_t time){

  uint32_t cadence, cadence_5;

  cadence = (crank * 60)/time;
  cadence_5 = cadence / 5;
  return cadence = 5 * cadence_5;

}

void initiate(void){

  post_time = 0;
  wheel = 700;
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

  display_segment(total_distance_f, total_distance_b);
  //display_oled();

  return;
    
}

//------------------------------------------------------------------------------
// Main Function
//------------------------------------------------------------------------------

int main(void) {

    initiate();

    // repeat forever (embedded programs generally do not terminate)
  while(1){
    if(wait_for_press()){ // 等待三秒或等待按钮按下后
    // 按钮按下后，处理按钮操作
      if(setting()){
        // 设置操作，更改wheel 
        wait_for_setting();
      }
      else{
        if (press_trip()){
          //根据模式清零
          if (mode == 0){    //里程
            total_distance = 0;
            clear_fork();
          }else if (mode == 1) {           //时间
            post_time = 0;
            clear_timer_long(); 
            clear_fork();
          }     
        }
        else if(press_mode()){     // 0里程  1时间  2速度  3踏频
          if (mode == 0){
            mode = 1;
          } else if (mode == 1){
            mode = 2;
          } else if (mode == 2){
            mode = 3;
          } else {
            mode = 0;
          }
          switchDisplay = true;
        }
        else if(press_d_mode()){
          isNight = ~ isNight;
        }
      }
    }
    // 按钮按下则在处理完按钮操作后立即刷新，没有按下则三秒刷新一次
    crank = read_crank();

    bike_fork = read_fork();

    total_distance = get_distance(bike_fork, wheel);
    distance = total_distance - post_distance;
    post_distance = total_distance;
    total_distance_f = (uint32_t) total_distance;
    total_distance_b = (uint32_t) ((total_distance - total_distance_f) * 100);

    now_time = read_time_long();
    time = now_time - post_time;
    speed = get_speed(distance, time);
    post_time = now_time;

    time_h = now_time/3600;
    time_m = (now_time%3600)/60;
    
    speed_f = (uint32_t) speed;
    speed_b = (uint32_t) ((speed - speed_f) * 100);
    

    cadence = get_cadence(crank, time);

    check_speed();

    display_segment(total_distance_f, total_distance_b);

    //get_oled_image(distance, speed, ave_speed, energe, max_speed, time, crank, switchDisplay, isNight);
    //display_oled();

    switchDisplay = false;
  }
}

