
//------------------------------------------------------------------------------
//   Title: System module - 2022/2023 SubFile: Stimulus
//  Author: Clark Pu, Paiyun Chen (Circle)
//    Team: C4 Chip Designed
// Version: 3.0 Behavioural Simulation
//------------------------------------------------------------------------------

 `define ingore_read_flag

//------------------------------------------------------------------------------
// Macros for Enabling Test
// Comments:  The priority of macros is as follows: from top to the bottom.
//            Priority of macros doesn't stand for the importance of tests;
//            It's just used to avoid conflicts between tests.
//------------------------------------------------------------------------------

// `define TripTimeClearTest
// `define TripTimeStopTest
// `define TripTimeClearTest
//  `define CadenceMeterTest
// `define OdometerTest
`define SimpleBasicTest

`include "../system2/display.sv"
// `include "../system2/monitor.sv"

//------------------------------------------------------------------------------
// Initiate, Clock Ticks and Reset
//------------------------------------------------------------------------------

initial begin
  Clock = 0;
  forever
    #(`clock_period/2) Clock = ~ Clock;
end
initial begin
  nReset = 0;
  #(`clock_period/4) nReset = 1;
end

//------------------------------------------------------------------------------
// AHB Signals
//------------------------------------------------------------------------------

  wire [31:0] ahb_addr;
  wire [31:0] write_data;
  wire write;
  wire sel_timer, sel_segment, sel_sensor, sel_button, sel_oled;
  wire [31:0] data_timer, data_segment, data_sensor, data_button, data_oled;

  assign ahb_addr     = COMPUTER.COMP_core.HADDR;
  assign sel_timer    = COMPUTER.COMP_core.HSEL_TIMER;
  assign sel_segment  = COMPUTER.COMP_core.HSEL_SEG;
  assign sel_sensor   = COMPUTER.COMP_core.HSEL_SENM;
  assign sel_button   = COMPUTER.COMP_core.HSEL_BM;
  assign sel_oled     = COMPUTER.COMP_core.HSEL_OLEDM;
  assign data_timer   = COMPUTER.COMP_core.HRDATA_TIMER;
  assign data_segment = COMPUTER.COMP_core.HRDATA_SEG;
  assign data_sensor  = COMPUTER.COMP_core.HRDATA_SENM;
  assign data_button  = COMPUTER.COMP_core.HRDATA_BM;
  assign data_oled    = COMPUTER.COMP_core.HRDATA_OLEDM;
  assign write        = COMPUTER.COMP_core.HWRITE;
  assign write_data   = COMPUTER.COMP_core.HWDATA;

  initial $timeformat(0, 2, "s", 10);

//------------------------------------------------------------------------------
// Real Environment Simulation
//------------------------------------------------------------------------------

// Tested real variable
integer
  error = 0,
  wheel_size = 2.136,
  crank_cycle = 1200, // ms
  fork_cycle = 800,  // ms
  noise = 24; //ms

// Tested real value
integer
  odometer = 0,
  cadence = 0,
  segment_odometer = 0,
  segment_speed = 0,
  segment_cadence = 0,
  segment_time = 0,
  crank_times = 0,
  last_crank_times = 0,
  fork_times = 0,
  last_fork_times = 0,
  trip_time = 0,
  last_trip_time = 0,
  speed = 0,
  ave_speed = 0,
  ave_cadence = 0;

initial begin  // Crank will keep rolling
  start_up_delay();
  crank_times = 0;
  forever begin
    #(crank_cycle * 1000_000) -> trigger_crank_sensor;
    crank_times ++;
  end
end

initial begin // Fork will keep rolling
  start_up_delay();
  fork_times = 0;
  forever begin
    #(fork_cycle * 1000_000) -> trigger_fork_sensor;
    fork_times ++;
  end
end

initial begin // Trip will keep counting
  start_up_delay();
  trip_time = 0;
  forever
    #1s trip_time ++;
end

initial begin // Speed will keep measuring
  start_up_delay();
  forever begin
    last_trip_time = trip_time;
    last_fork_times = fork_times;
    #3s;
    speed = (wheel_size * (fork_times - last_fork_times))/(trip_time - last_trip_time); // m/s
    ave_speed = wheel_size * fork_times / trip_time;
  end
end

initial begin // Cadence will keep measuring
  start_up_delay();
  forever begin
    last_crank_times = crank_times;
    #3s;
    cadence = (crank_times - last_crank_times) * 20;
    ave_cadence = crank_times * 60 / trip_time;
  end
end

//------------------------------------------------------------------------------
// Tasks
//------------------------------------------------------------------------------

  //--------------------------------------------------------------
  // Initialization Task
  //--------------------------------------------------------------
  task StartUp;
    $display("\n Start Up.\n");
    $display("------------------------------------------------------------------------------");
    wheel_size = 2.136;
    Crank = 0;
    Fork = 0;
    Mode = 0;
    Trip = 0;
    DisplayRefresh_Seg = 0;
    start_up_delay();
    $display("\n Simulation Start.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Odometer Verification
  //--------------------------------------------------------------

  task OdometerVerification; // This will test if the recoreded odometer matchs the real odometer
    $display("\n Odometer verification start.");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    odometer = (2.136 * fork_times);
    DisplaySegment;
    $display("\n Real Odometer is %fkm. Segment display is %fkm (fork_times = %d). (%t)", odometer/1000.0, seg_value, fork_times, $time);
    assert (seg_value*1000 - odometer <= 100 && odometer - seg_value*1000 <= 100) else begin
      $display(" *** WARNING ***: Odometer result error more than 100m.");
      error = error + 1;
    end
    $display("\n Odometer verification end.");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Speed Verification
  //--------------------------------------------------------------

  task SpeedVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Speed verification start.");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    DisplaySegment;
    $display("\n Real Speed is %f km/h. Segment display is %f km/h (ave speed = %dkm/h). (%t)", (speed * 3.6), seg_value, ave_speed*3.6, $time);
    assert (seg_value - (speed * 3.6) < 2 && (speed * 3.6) - seg_value < 2) else begin
      $display(" *** WARNING ***: Speed result error more than 1km/h.");
      error = error + 1;
    end
    $display("\n Speed verification end.");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Cadence Verification
  //--------------------------------------------------------------

  task CadenceVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Cadence verification start.");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    DisplaySegment;
    $display("\n Real Cadence is %d rpm. Segment display is %d rpm (ave cadence = %d). (%t)", cadence, seg_value, ave_cadence, $time);
    assert (seg_value - cadence < 5 && cadence - seg_value < 5) else begin
      $display(" *** WARNING ***: Cadence result error more than 5 rpm.");
      error = error + 1;
    end
    $display("\n Cadence verification end.");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Trip Time Verification
  //--------------------------------------------------------------

  task TripTimeVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Trip time verification start.");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    DisplaySegment;
    $display("\n Real trip time is %fs. Segment display is %fs. (%t)", trip_time, seg_value*6000, $time);
    assert (seg_value*6000 - trip_time < 60 && trip_time - seg_value*6000 < 60) else begin
      $display(" *** WARNING ***: Trip time result error more than 1 min.");
      error = error + 1;
    end
    $display("\n Trip time verification end.");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Button Manager Tasks
  //--------------------------------------------------------------

  task ButtonNoiseTest; // This will test if the button will debaunce 
    $display("\n Noise test start.");
    Trip = 1;
    Mode = 1;
    for (int i = 0; i < 10 ; i ++) begin
      Trip = 1;
      #(noise * 1000_000); // 24ms
      Trip = 0;
      for (int j = 0; j < 10; j ++) begin
        @(posedge Clock);
          assert (COMPUTER.COMP_core.button_manager_1.NewData == 0)  else begin
            $display(" *** WARNING ***: Button is triggered by noise.");
            error = error + 1;
          end
      end
      #(noise * 1000_000); // 24ms
      Mode = 1;
      #(noise * 1000_000); // 24ms
      Mode = 0;
      for (int j = 0; j < 10; j ++) begin
        @(posedge Clock);
          assert (COMPUTER.COMP_core.button_manager_1.NewData == 0)  else begin
            $display(" *** WARNING ***: Button is triggered by noise.");
            error = error + 1;
          end
      end
      #(noise * 1000_000); // 24ms
    end
    $display("\n Noise test end.");
    $display("------------------------------------------------------------------------------");
  endtask

  task PressModeButtonTest; // This will test if the press of the mode button will be detected
    $display("\n Press Mode 1 times test start.");
    #1s -> press_mode_button;
    $display("\n Wait for the software to check to the button.");
    while (!(sel_button && (ahb_addr[4:2] == 1))) // AHB read mode command
      @(posedge Clock);
    #(`clock_period/2); // AHB read mode data
    if (data_button == 1)
      $display(" Button mode is pressed. (%t)", $time);
    assert (data_button == 1) else begin
      $display(" *** WARNING ***: Button mode is NOT pressed. (%t)", $time);
      error = error + 1;
    end
    $display("\n Press Mode 1 times test end.");
    $display("------------------------------------------------------------------------------");
  endtask

  task PressTripButtonTest; // This will test if the press of the trip button will be detected
    $display("\n Press Trip 1 time test start.");
    #1s -> press_trip_button;
    $display("\n Wait for the software to check to the button.");
    while (!(sel_button && (ahb_addr[4:2] == 2))) // AHB read mode command
      @(posedge Clock);
    #(`clock_period/2); // AHB read mode data
    if (data_button == 1) begin
      $display(" Button trip is pressed. (%t)", $time);
      odometer = 0;
      trip_time = 0;
    end
    assert (data_button == 1) else begin
      $display(" *** WARNING ***: Button trip is NOT pressed. (%t)", $time);
      error = error + 1;
    end
      $display("\n Press Trip 1 time test end.");
    $display("------------------------------------------------------------------------------");
  endtask

  task SettingModeTest; // This will test if the press of the mode button twice will be detected
    $display("\n Setting mode test start.\n");
    #1s   -> press_mode_button;
    #1ns  -> press_trip_button;
    for(int i=0;i<3;i++) begin
      #1s -> press_mode_button;
      for(int j=0;j<2;j++)
        #0.5s -> press_trip_button;
    end
    $display("\n Setting mode test end.\n");
  endtask

  task NightModeTest; // This will test if the button will be debounced
    $display("\n Night mode test start.\n");
    $display("------------------------------------------------------------------------------");
    for(int i=0;i<2;i++)
      #0.4s -> press_mode_button;
    $display("\n Wait for the software to check to the button.\n");
    while (!(sel_button && (ahb_addr[4:2] == 0))) // AHB read mode command
      @(posedge Clock);
    #(`clock_period/2); // AHB read mode data
    if (data_button == 1) begin
      $display("\n Night/Day Mode is Activated. (%t)\n", $time);
    end
    assert (data_button == 1) else begin
      $display("\n *** WARNING ***:  Night/Day Mode activate signal NOT detected. (%t)\n", $time);
      error = error + 1;
    end
    $display("\n Night mode test end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Seven Segment Manager Tasks
  //--------------------------------------------------------------
  task WheelSizeSwitchTest;
    $display("\n Wheel size switch test start.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_mode_button;
    #17ms -> press_trip_button;
    for (int j=0;j<3;j++) begin
      for (int i=0;i<0;i++) begin
        #1s -> press_trip_button;
      end
      #1s -> press_mode_button;
      @(posedge Clock);
      DisplayRefresh_Seg = 0;
      @(posedge Clock);
      DisplayRefresh_Seg = 1;
      @(posedge Clock);
      DisplayRefresh_Seg = 0;
      $stop;
    end
  endtask

  //--------------------------------------------------------------
  // Speed Options
  //--------------------------------------------------------------

  task SuperManSpeed;
    $display("\n Watch out! Super Man is riding the bicycle!\n");
    crank_cycle = 4; // ms
    fork_cycle = 3;  // ms
  endtask

  task FastSpeedTest;
    $display("\n Change to fast speed.\n");
    crank_cycle = 190; // ms
    fork_cycle = 300;  // ms
  endtask

  task LowSpeedTest;
    $display("\n Change to Low speed.\n");
    crank_cycle = 1600; // ms
    fork_cycle = 1100;  // ms
  endtask

  task ZeroSpeedTest;
    $display("\n Bicycle stopped.\n");
    crank_cycle = 10000; // ms
    fork_cycle = 10000;  // ms
  endtask

  //--------------------------------------------------------------
  // Customization Intended Task
  //--------------------------------------------------------------

  task CustomWheelSizeSwitch(int digit2, int digit1, int digit0);
    $display("\n Custom wheel size switch start.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_mode_button;
    #17ms -> press_trip_button;

    for (int i=0;i<digit0;i++) begin
      #1s -> press_trip_button;
    end
    #1s -> press_mode_button;

    for (int i=0;i<digit1;i++) begin
        #1s -> press_trip_button;
      end
    #1s -> press_mode_button;

    for (int i=0;i<(digit2+3);i++) begin
        #1s -> press_trip_button;
    end
    #1s -> press_mode_button;
    DisplayRefresh_Seg = 0;
    @(posedge Clock);
    DisplayRefresh_Seg = 1;
    @(posedge Clock);
    DisplayRefresh_Seg = 0;
    #1s;  // Response time
  endtask

  task SinglePressModeButton;
    $display("\n Mode button will be pressed once.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_mode_button;
  endtask

  task SinglePressTripButton;
    $display("\n Trip button will be pressed once.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_trip_button;
  endtask

//------------------------------------------------------------------------------
// Custom Stimulus & Verification
// Comment: Use marco to enable
//------------------------------------------------------------------------------

  //--------------------------------------------------------------
  // Trip Time Clear Test
  //--------------------------------------------------------------
  `ifdef TripTimeClearTest
    initial begin
      StartUp;

      FastSpeedTest;
      $display("\n Wait for 70s...");
      PressModeButtonTest;
      #70s;

      TripTimeVerification;
      #0.5s;
      PressTripButtonTest;

      #0.5s;
      TripTimeVerification;

      #0.5s;
      $finish;
      
    end

  //--------------------------------------------------------------
  // Trip Time Stop Test
  //--------------------------------------------------------------
  `elsif TripTimeStopTest
    initial begin
      StartUp;

      FastSpeedTest;
      $display("\n Wait for 70s...");
      PressModeButtonTest;
      #70s;

      TripTimeVerification;

      ZeroSpeedTest;
      #70s;

      trip_time = 76;
      
      TripTimeVerification;

      $stop;
      $finish;
    end
  
  //--------------------------------------------------------------
  // Cadence Meter Test
  //--------------------------------------------------------------
  `elsif CadenceMeterTest
    initial begin
      StartUp;

      FastSpeedTest;
      SinglePressModeButton;
      SinglePressModeButton;
      SinglePressModeButton;


      for (int i=0; i<5; i++) begin
        #3s;
        CadenceVerification;
      end

      $stop;
      $finish;
    end

  //--------------------------------------------------------------
  // Odometer Test
  //--------------------------------------------------------------
  `elsif OdometerTest
    initial begin
      StartUp;

      FastSpeedTest;

      for (int i=0;i<10;i++) begin
        #5s;
        OdometerVerification;
      end    

      $stop;
      $finish;
    end

  //--------------------------------------------------------------
  // Software Self Submmit Verification Test
  //--------------------------------------------------------------

  `elsif SimpleBasicTest
    initial begin
      StartUp;

      // FastSpeedTest;

      #20s;
      OdometerVerification;

      #20s;
      OdometerVerification;

      PressModeButtonTest;
      #25s;
      TripTimeVerification;

      PressModeButtonTest;
      #5s;
      SpeedVerification;

      PressModeButtonTest;
      #5s;
      CadenceVerification;

      PressModeButtonTest;
      #5s;
      OdometerVerification;

      $finish;
    end
    
  `endif