
//------------------------------------------------------------------------------
//   Title: System module - 2022/2023 SubFile: Stimulus
//  Author: Clark Pu, Paiyun Chen (Circle)
//    Team: C4 Chip Designed
// Version: 1.0 Gate Level Simulation
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Gate Level Verison Macros
//------------------------------------------------------------------------------

// 1. Test Mission: Enable only one mission each time!
//    Mission Status: ----- Passed, Failed, Not Verified.
//    Verified with software version 5.5
 `define GateLevelOdometerTest      // Not Verified
// `define GateLevelTripTimeTest      // Not Verified
// `define GateLevelSpeedTest         // Not Verified
// `define GateLevelCadenceTest       // Not Verified

// 2. AHB Monitor options:
 `define ingore_read_flag

// 3. Monitor enable:
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
// AHB Signals (Not available in gate level simulation)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Real Environment Simulation
//------------------------------------------------------------------------------

// Tested real variable
real
  error = 0,
  wheel_size = 2.136,
  crank_cycle = 1200, // ms
  fork_cycle = 800,  // ms
  noise = 25, //ms
  ave_speed = 0,
  ave_cadence = 0;

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
  speed = 0;

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
    #10s;
    speed = (wheel_size * (fork_times - last_fork_times))/(trip_time - last_trip_time); // m/s
    ave_speed = wheel_size * fork_times / trip_time;
  end
end

initial begin // Cadence will keep measuring
  start_up_delay();
  forever begin
    last_crank_times = crank_times;
    #12s;
    cadence = (crank_times - last_crank_times) * 5;
    ave_cadence = crank_times * 60 / trip_time;
  end
end

//------------------------------------------------------------------------------
// Gate Level Tasks
//------------------------------------------------------------------------------

  //--------------------------------------------------------------
  // Gate Level Initialization & Completion Tasks
  //--------------------------------------------------------------
  task GateLevelStartUp;
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

  task GateLevelEndSimulation;
    #1s;
    $finish;
  endtask

  //--------------------------------------------------------------
  // Gate Level Odometer Task
  //--------------------------------------------------------------

  task GateLevelOdometerTest;
    $display("\n Odometer verification start.");
    #3s;
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
  // Gate LevelTrip Time Verification
  //--------------------------------------------------------------

  task GateLevelTripTimeTask; // This will test if the recoreded speed matchs the real speed
    $display("\n Trip time verification start.");
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
  // Gate Level Speed Verification
  //--------------------------------------------------------------

  task SpeedVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Speed verification start.");
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
  // Gate Level Cadence Verification
  //--------------------------------------------------------------

  task CadenceVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Cadence verification start.");
    DisplaySegment;
    $display("\n Real Cadence is %d rpm. Segment display is %d rpm (ave cadence = %d). (%t)", cadence, seg_value, ave_cadence, $time);
    assert (seg_value - cadence <= 10 && cadence - seg_value <= 10) else begin
      $display(" *** WARNING ***: Cadence result error more than 10 rpm.");
      error = error + 1;
    end
    $display("\n Cadence verification end.");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Speed Options
  //--------------------------------------------------------------

  task SuperFastSpeed;
    $display("\n Watch out! Super Man is riding the bicycle! (%t)\n", $time);
    crank_cycle = 40; // ms
    fork_cycle = 30;  // ms
  endtask

  task FastSpeedTest;
    $display("\n Change to fast speed. (%t)\n", $time);
    crank_cycle = 190; // ms
    fork_cycle = 300;  // ms
  endtask

  task LowSpeedTest;
    $display("\n Change to Low speed. (%t)\n", $time);
    crank_cycle = 1600; // ms
    fork_cycle = 1100;  // ms
  endtask

  task ZeroSpeedTest;
    $display("\n Bicycle stopped. (%t)\n", $time);
    crank_cycle = 100_000; // ms
    fork_cycle = 100_000;  // ms
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
    #1s -> press_mode_button;
  endtask

  task SinglePressTripButton;
    $display("\n Trip button will be pressed once.\n");
    #1s -> press_trip_button;
  endtask

//------------------------------------------------------------------------------
// Gate Level Custom Stimulus & Verification
// Comment: Use marco to enable
//------------------------------------------------------------------------------

  //--------------------------------------------------------------
  // Gate Level Odometer Verification Test
  //--------------------------------------------------------------
  `ifdef GateLevelOdometerTest
    initial begin
      GateLevelStartUp;

      LowSpeedTest;

      for (int i=0;i<30;i++) begin
        #3s;
        GateLevelOdometerTest;
      end

      GateLevelEndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Trip Time Verification Test
  //--------------------------------------------------------------
  `elsif GateLevelTripTimeTest
    initial begin
      GateLevelStartUp;

      SinglePressModeButton;

      LowSpeedTest;

      for (int i=0;i<30;i++) begin
        #3s;
        GateLevelTripTimeTest;
      end

      GateLevelEndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Speedometer Verification Test
  //--------------------------------------------------------------
  `elsif GateLevelSpeedTest
    initial begin
      GateLevelStartUp;

      SinglePressModeButton;
      SinglePressModeButton;

      LowSpeedTest;

      for (int i=0;i<30;i++) begin
        #3s;
        GateLevelSpeedTest;
      end

      GateLevelEndSimulation;
    end
  
  //--------------------------------------------------------------
  // Gate Level Cadence Verification Test
  //--------------------------------------------------------------
  `elsif GateLevelCadenceTest
    initial begin
      GateLevelStartUp;

      SinglePressModeButton;
      SinglePressModeButton;
      SinglePressModeButton;

      LowSpeedTest;

      for (int i=0;i<30;i++) begin
        #3s;
        GateLevelCadenceTest;
      end

      GateLevelEndSimulation;
    end

  `endif
