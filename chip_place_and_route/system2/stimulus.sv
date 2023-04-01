
//------------------------------------------------------------------------------
//   Title: System module - 2022/2023 SubFile: Stimulus
//  Author: Clark Pu, Paiyun Chen (Circle)
//    Team: C4 Chip Designed
// Version: 3.0 Gate Level Simulation
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Gate Level Verison Macros
//------------------------------------------------------------------------------

// 1. Test Mission: Enable only one mission each time!
//    Mission Status: ----- Passed, Failed, Not Verified.
//    Verifing with software version 5.5
//  `define OdometerVerification      // Not Verified
//  `define TripTimeVerification      // Not Verified
//  `define TimeStopVerification      // Not verified
//  `define SpeedVerification         // Not Verified
//  `define CadenceVerification       // Behavioural Passed
//  `define ModeSwitchVerification    // Gate Level Passed
  `define SimpleVerification        // Behavioural Passed 
//  `define FullVerification          // Not Verified
//  `define MacroCellVerification     // Not Verified

// 2. Monitor enable:
`include "../system2/display.sv"

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
// Real Environment Simulation
//------------------------------------------------------------------------------

// Tested real variable
real
  wheel_size = 2.136,
  crank_cycle = 1200, // ms
  fork_cycle = 800,  // ms
  noise = 25, //ms
  ave_speed = 0,
  ave_cadence = 0;

integer
  error_sum = 0,
  error_odometer = 0,
  error_time = 0,
  error_speed = 0,
  error_cadence = 0,
  time_label60;

logic [25:0][99:0]
  error_odometer_value,
  ref_odometer_value,
  error_time_value,
  ref_time_value,
  error_speed_value,
  ref_speed_value,
  error_cadence_value,
  ref_cadence_value;

// Tested real value
integer
  odometer = 0,
  segment_odometer = 0,
  segment_speed = 0,
  segment_cadence = 0,
  segment_time = 0,
  crank_times = 0,
  fork_times = 0,
  trip_time = 0,
  cadence = 0,
  speed = 0,
  clock_count = 0,
  wheelsize_ref_dig2 = 0,
  wheelsize_ref_dig1 = 0,
  wheelsize_ref_dig0 = 0;

initial $timeformat(0, 2, "s", 10);

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

initial begin // Trip time will keep counting
  start_up_delay();
  trip_time = 0;
  forever
    #1s trip_time ++;
end

initial begin // Average speed will keep measuring
  start_up_delay();
  forever begin
    #3s;
    ave_speed = wheel_size * fork_times / trip_time;
  end
end

initial begin // Average cadence will keep measuring
  start_up_delay();
  forever begin
    #3s;
    ave_cadence = crank_times * 60 / trip_time;
  end
end

initial begin
  @(posedge SDI);
  forever begin
    @(posedge Clock);
    clock_count ++;
  end
end

//------------------------------------------------------------------------------
// Gate Level Tasks
//------------------------------------------------------------------------------
  //--------------------------------------------------------------
  // Initialization & Completion Tasks
  //--------------------------------------------------------------
  task StartUp;
    $display("\n Start Up.\n");
    $display("------------------------------------------------------------------------------");
    wheel_size = 2.136;
    Crank = 0;
    Fork = 0;
    Mode = 0;
    Trip = 0;
    ScanEnable = 0;
    Test = 0;
    SDI = 0;
    DisplayRefresh_Seg = 0;
    start_up_delay();
    $display("\n Simulation Start.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  task EndSimulation;
    #1s;
    if (error_sum == 0)
      $display("--------------------------------Simulation Passed--------------------------------");
    else begin
      $display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXSimulation FailedXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
      $display("\n Error Report: \n");
      for (integer i=0;i<error_odometer;i++) begin
        $display(" Real odometer = %fkm. Error odometer = %fkm. Odometer error number: %d.", real'(ref_odometer_value[i])/1000.0, real'(error_odometer_value[i])/1000.0, i);
      end
      for (integer i=0;i<error_time;i++) begin
        $display(" Real trip time = %ds. Error trip time = %ds. Trip time error number: %d.", ref_time_value[i], error_time_value[i], i);
      end
      for (integer i=0;i<error_speed;i++) begin
        $display(" Real speed = %fkmh. Error speed = %fkmh. Speed error number: %d.", real'(ref_speed_value[i])/100.0, real'(error_speed_value[i])/100.0, i);
      end
      for (integer i=0;i<error_cadence;i++) begin
        $display(" Real cadence = %drpm. Error cadence = %drpm. Cadence error number: %d.", ref_cadence_value[i], error_speed_value[i]/100.0, i);
      end
    end
    $finish;
  endtask

  //--------------------------------------------------------------
  // Gate Level Verification Task
  //--------------------------------------------------------------
  task OdometerTest;
    $display("\n This is odometer:");
    odometer = (2.136 * fork_times);
    DisplaySegment;
    DisplayOLED;
    $display("\n Real Odometer is %fkm. Segment display is %fkm (fork_times = %d). (%t)", odometer/1000.0, seg_value, fork_times, $time);
    $display("------------------------------------------------------------------------------");
    assert ((((odometer/1000.0) - seg_value) < 0.1) && ((seg_value - (odometer/1000.0)) < 0.1)) else begin
      error_sum       = error_sum       + 1;
      error_odometer  = error_odometer  + 1;
      error_odometer_value[error_odometer] = int'(seg_value*1000);
      ref_odometer_value  [error_odometer] = int'(      odometer);
      $display("Odometer test failed. Odometer error number: %d. Summary error number: %d.", error_odometer, error_sum);
    end
    $display("------------------------------------------------------------------------------");
  endtask

  task TripTimeTest;
    $display("\n This is Trip time:");
    DisplaySegment;
    DisplayOLED;
    $display("\n Real trip time is %fs. Segment display is %fs. (%t)", trip_time, seg_value*6000, $time);
    $display("------------------------------------------------------------------------------");
    assert (((trip_time - seg_value*6000) < 60) && ((seg_value*6000 - trip_time) < 60)) else begin
      error_sum       = error_sum       + 1;
      error_time      = error_time      + 1;
      error_time_value[error_time] = int'(seg_value*6000);
      ref_time_value  [error_time] = int'(      odometer);
      $display("Trip Time test failed. Trip Time error number: %d. Summary error number: %d.", error_time, error_sum);
    end
  endtask

  task SpeedTest;
    $display("\n This is speed:");
    DisplaySegment;
    DisplayOLED;
    $display("\n Real Speed is %fkm/h. Segment display is %fkm/h (ave speed = %dkm/h). (%t)", speed, seg_value, ave_speed*3.6, $time);
    $display("------------------------------------------------------------------------------");
    assert (((speed - seg_value) <= 0.1) && ((seg_value - speed) <= 0.1)) else begin
      error_sum       = error_sum       + 1;
      error_speed     = error_speed     + 1;
      error_speed_value[error_speed] = int'(seg_value*100);
      ref_speed_value  [error_speed] = int'(    speed*100);
      $display("Speed test failed. Speed error number: %d. Summary error number: %d.", error_speed, error_sum);
    end
  endtask

  task CadenceTest;
    $display("\n This is cadence:");
    DisplaySegment;
    DisplayOLED;
    $display("\n Real Cadence is %drpm. Segment display is %drpm (ave cadence = %d). (%t)", cadence, seg_value, ave_cadence, $time);
    $display("------------------------------------------------------------------------------");
    assert (((cadence - seg_value) <= 5) && ((seg_value - cadence) <= 5)) else begin
      error_sum       = error_sum       + 1;
      error_cadence   = error_cadence   + 1;
      error_cadence_value[error_cadence] = int'(seg_value);
      ref_cadence_value  [error_cadence] = int'(  cadence);
      $display("Cadence test failed. Cadence error number: %d. Summary error number: %d.", error_cadence, error_sum);
    end
  endtask

  //--------------------------------------------------------------
  // Button Press Select
  //--------------------------------------------------------------
  task PressModeButton;
    $display("\n Mode button will be pressed once.\n");
    #1s -> press_mode_button;
  endtask

  task PressTripButton;
    $display("\n Trip button will be pressed once.\n");
    #1s -> press_trip_button;
  endtask

  task PressSettingButton;
    $display("\n Setting mode will be entered.");
    #1s   ->  press_mode_button;
    #0.3s ->  press_trip_button;
  endtask

  //--------------------------------------------------------------
  // Customization Task
  //--------------------------------------------------------------
  task CustomizeWheelSize(int wheelsize_ref);
    $display("\n Customize wheel size switch start.\n");
    $display("------------------------------------------------------------------------------");

    wheel_size = (real'(wheelsize_ref)/1000.0);

    wheelsize_ref_dig2 = (wheelsize_ref/100)%10;
    wheelsize_ref_dig1 = (wheelsize_ref/ 10)%10;
    wheelsize_ref_dig0 =  wheelsize_ref     %10;
    
    PressSettingButton;
    DisplaySegment;
    DisplayOLED;
    
    while (seg_digit_value2 != wheelsize_ref_dig2) begin
      PressTripButton;
      DisplaySegment;
      DisplayOLED;
    end
    PressModeButton;

    while (seg_digit_value1 != wheelsize_ref_dig1) begin
      PressTripButton;
      DisplaySegment;
      DisplayOLED;
    end
    PressModeButton;

    while (seg_digit_value0 != wheelsize_ref_dig0) begin
      PressTripButton;
      DisplaySegment;
      DisplayOLED;
    end
  endtask

  task CustomizeSpeedCadence(int speed_ref, int cadence_ref);   // unit: speed km/h, cadence rpm.
    $display("\n Change to speed: %dkm/h. Change to Cadence %drpm. (%t)\n", speed_ref, cadence_ref, $time);
    if (speed_ref == 0)
      fork_cycle = 100_000;
    else
      fork_cycle = (3600*wheel_size)/speed_ref;

    if (cadence_ref == 0)
      crank_cycle = 100_000;
    else
      crank_cycle = 60000/cadence_ref;
    
    speed = speed_ref;
    cadence = cadence_ref;
  endtask

  task CustomizeMode(int mode_num);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c)
    $display("\n Customize Mode switch start.\n");
    if ((mode_num != 0) && (mode_num != 1) && (mode_num != 2) && (mode_num != 3)) begin
      $display("\n Wrong Mode Number! Mode button will not be pressed. Please go back to correct your testbench.\n");
      $display("------------------------------------------------------------------------------");
      $stop;
    end
    else begin
      case(mode_num)
        0: $display("\n Switch to odometer mode.\n");
        1: $display("\n Switch to trip time mode.\n");
        2: $display("\n Switch to speed mode.\n");
        3: $display("\n Switch to cadence mode.\n");
      endcase
      $display("------------------------------------------------------------------------------");
      while (seg_digit_value3 != mode_num) begin
        PressModeButton;
        DisplaySegment;
        DisplayOLED;
      end
    end
  endtask

  //------------------------------------------------------------------------------
  // Display Tasks
  //------------------------------------------------------------------------------
  task DisplaySegment;
    #1s;
    for (int i=0;i<7;i++)
      @(posedge Clock);
    DisplayRefresh_Seg = 0;
    @(posedge Clock);
    DisplayRefresh_Seg = 1;
    @(posedge Clock);
    DisplayRefresh_Seg = 0;
  endtask

  task DisplayOLED;
    #1s;
    @(posedge Clock);
    DisplayRefresh = ~DisplayRefresh;
  endtask

//------------------------------------------------------------------------------
// Gate Level Custom Stimulus & Verification
// Comment: Use marco to enable
//------------------------------------------------------------------------------
  //--------------------------------------------------------------
  // Gate Level Odometer Verification
  //--------------------------------------------------------------
  `ifdef OdometerVerification
    initial begin
      StartUp;

      CustomizeMode(0);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      CustomizeSpeedCadence(20,150);
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      CustomizeSpeedCadence(10,100);
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      CustomizeSpeedCadence(0,0);
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Trip Time Verification
  //--------------------------------------------------------------
  `elsif TripTimeVerification
    initial begin
      StartUp;

      CustomizeMode(1);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      CustomizeSpeedCadence(20,150);
      #60s;
      for (int i=0;i<3;i++)
        #3s TripTimeTest;

      CustomizeSpeedCadence(0,0);
      #60s;
      trip_time = trip_time - 60;
      for (int i=0;i<3;i++) begin
        #3s;
        trip_time = trip_time - 3;
        TripTimeTest;
      end

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Time Stop Verification
  //--------------------------------------------------------------
  `elsif TimeStopVerification
    initial begin
      StartUp;

      CustomizeMode(1);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      #65s;

      CustomizeSpeedCadence(0,0);
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);

      for (int i=0;i<150;i++) begin
        #0.5s;
        DisplaySegment;
        $display("Running at %t", $time);
      end

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Speedometer Verification
  //--------------------------------------------------------------
  `elsif SpeedVerification
    initial begin
      StartUp;

      CustomizeWheelSize(2899);

      CustomizeMode(2);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      CustomizeSpeedCadence(80,150);
      for (int i=0;i<10;i++)
        #3s SpeedTest;

      CustomizeSpeedCadence(100,100);
      for (int i=0;i<10;i++)
        #3s SpeedTest;

      CustomizeSpeedCadence(150,0);
      for (int i=0;i<10;i++)
        #3s SpeedTest;

      EndSimulation;
    end
  
  //--------------------------------------------------------------
  // Gate Level Cadence Verification
  //--------------------------------------------------------------
  `elsif CadenceVerification
    initial begin
      StartUp;

      CustomizeMode(3);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      CustomizeSpeedCadence(20,30);
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      for (int i=0;i<3;i++)
        #9s CadenceTest;

      CustomizeSpeedCadence(20,25);
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      for (int i=0;i<3;i++)
        #9s CadenceTest;

      CustomizeSpeedCadence(20,30);
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      for (int i=0;i<3;i++)
        #9s CadenceTest;

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Mode Switch Verification
  //--------------------------------------------------------------
  `elsif ModeSwitchVerification
    initial begin
      StartUp;

      for (int i=0;i<20;i++) begin
        PressModeButton;
        #4s;
        DisplaySegment;
      end

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Simple Verification
  //--------------------------------------------------------------
  `elsif SimpleVerification
    initial begin
      StartUp;

      //--------------------------------------------------
      // Three Mode Test Round 1
      //--------------------------------------------------
      CustomizeWheelSize(2694);
      CustomizeSpeedCadence(3,30);

      // Odometer Test
      CustomizeMode(0);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i = 0; i<5; i++)
        OdometerTest;

      // Speed Test
      CustomizeMode(2);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i = 0; i<10; i++)
        SpeedTest;

      // Cadence Test
      CustomizeMode(3);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i = 0; i<10; i++)
        CadenceTest;

      //--------------------------------------------------
      // Three Mode Test Round 2
      //--------------------------------------------------
      CustomizeWheelSize(2765);
      CustomizeSpeedCadence(500,600);

      // Odometer Test
      CustomizeMode(0);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i=0; i<5; i++)
        OdometerTest;

      // Speed Test
      CustomizeMode(2);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i=0; i<10; i++)
        SpeedTest;

      // Cadence Test
      CustomizeMode(3);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      for (int i=0; i<10; i++)
        CadenceTest;

      //--------------------------------------------------
      // Timer Test
      //--------------------------------------------------
      CustomizeMode(1);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)

      for (int i=0;i<2;i++) begin
        time_label60 = int'($time / 60);
        $display(" Time Test: Wait until %ds",(time_label60+1)*60+1);
        while ($time != (time_label60+1)*60+1);
          TripTimeTest;
      end

      time_label60 = int'($time / 60);
      $display(" Stop Test: Wait until 181s");
      CustomizeSpeedCadence(0,0);
      while ($time != (time_label60+1)*60+1);
      TripTimeTest;

      CustomizeMode(2);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      SpeedTest;

      CustomizeMode(3);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      CadenceTest;

      CustomizeMode(0);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      OdometerTest;

      $display(" Clear Test");
      PressTripButton;
      trip_time = 0;
      CustomizeMode(0);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      OdometerTest;
      CustomizeMode(1);  // 0:odometer(d), 1:timer(t), 2:speed(v), 3:cadence(c), 4:setting(2)
      TripTimeTest;

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Full Verification
  //--------------------------------------------------------------
  `elsif FullVerification
    initial begin
      StartUp;

      // Fast Speed
      Speed20km_Cadence150rps;
      for (int i=0;i<3;i++)
        #3s OdometerTest;
      PressModeButton;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s SpeedTest;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s CadenceTest;
      PressModeButton;

      // Slow Speed
      Speed10km_Cadence100rps;
      for (int i=0;i<3;i++)
        #3s OdometerTest;
      PressModeButton;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s SpeedTest;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s CadenceTest;
      PressModeButton;

      // Time Test
      #10s;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s TripTimeTest;

      // Stop Test
      BicycleStopped;
      #60s;
      trip_time = trip_time - 60;
      for (int i=0;i<3;i++) begin
        #3s;
        trip_time = trip_time - 3;
        TripTimeTest;
      end
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s SpeedTest;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s CadenceTest;
      PressModeButton;
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      EndSimulation;
    end
  //--------------------------------------------------------------
  // Gate Level Full Verification
  //--------------------------------------------------------------
  `elsif MacroCellVerification
    initial begin
      StartUp;
    end

  `endif
