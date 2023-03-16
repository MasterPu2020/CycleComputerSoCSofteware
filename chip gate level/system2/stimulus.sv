
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
//  `define SpeedVerification         // Not Verified
//  `define CadenceVerification       // Not Verified
 `define SimpleVerification        // Not Verified
//  `define FullVerification          // Not Verified

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
  segment_odometer = 0,
  segment_speed = 0,
  segment_cadence = 0,
  segment_time = 0,
  crank_times = 0,
  fork_times = 0,
  trip_time = 0,
  cadence = 0,
  speed = 0;

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
    $finish;
  endtask

  //--------------------------------------------------------------
  // Gate Level Verification Task
  //--------------------------------------------------------------

  task OdometerTest;
    $display("\n This is odometer:");
    odometer = (2.136 * fork_times);
    DisplaySegment;
    $display("\n Real Odometer is %fkm. Segment display is %fkm (fork_times = %d). (%t)", odometer/1000.0, seg_value, fork_times, $time);
    $display("------------------------------------------------------------------------------");
  endtask

  task TripTimeTest;
    $display("\n This is Trip time:");
    DisplaySegment;
    $display("\n Real trip time is %fs. Segment display is %fs. (%t)", trip_time, seg_value*6000, $time);
    $display("------------------------------------------------------------------------------");
  endtask

  task SpeedTest;
    $display("\n This is speed:");
    DisplaySegment;
    $display("\n Real Speed is %f km/h. Segment display is %f km/h (ave speed = %dkm/h). (%t)", speed, seg_value, ave_speed*3.6, $time);
    $display("------------------------------------------------------------------------------");
  endtask

  task CadenceTest;
    $display("\n This is cadence:");
    DisplaySegment;
    $display("\n Real Cadence is %d rpm. Segment display is %d rpm (ave cadence = %d). (%t)", cadence, seg_value, ave_cadence, $time);
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Speed Options
  //--------------------------------------------------------------

  task Speed10km_Cadence100rps;
    $display("\n Change to low speed: 10km/h, 100rps. (%t)\n", $time);
    crank_cycle = 600; // ms
    fork_cycle = 834;  // ms
    speed = 10;
    cadence = 100;
  endtask

  task Speed20km_Cadence150rps;
    $display("\n Change to fast speed: 20km/h, 150rps. (%t)\n", $time);
    crank_cycle = 400; // ms
    fork_cycle = 384;  // ms
    speed = 20;
    cadence = 150;
  endtask

  task BicycleStopped;
    $display("\n Bicycle stopped. (%t)\n", $time);
    crank_cycle = 100_000; // ms
    fork_cycle = 100_000;  // ms
    speed = 0;
    cadence = 0;
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

  task PressModeButton;
    $display("\n Mode button will be pressed once.\n");
    #1s -> press_mode_button;
  endtask

  task PressTripButton;
    $display("\n Trip button will be pressed once.\n");
    #1s -> press_trip_button;
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

      Speed20km_Cadence150rps;
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      Speed10km_Cadence100rps;
      for (int i=0;i<3;i++)
        #3s OdometerTest;

      BicycleStopped;
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

      PressModeButton;

      Speed20km_Cadence150rps;

      #60s;
      
      for (int i=0;i<3;i++)
        #3s TripTimeTest;

      BicycleStopped;

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
  // Gate Level Speedometer Verification
  //--------------------------------------------------------------
  `elsif SpeedVerification
    initial begin
      StartUp;

      PressModeButton;
      PressModeButton;

      Speed20km_Cadence150rps;
      for (int i=0;i<3;i++)
        #3s SpeedTest;

      Speed10km_Cadence100rps;
      for (int i=0;i<3;i++)
        #3s SpeedTest;

      BicycleStopped;
      for (int i=0;i<3;i++)
        #3s SpeedTest;

      EndSimulation;
    end
  
  //--------------------------------------------------------------
  // Gate Level Cadence Verification
  //--------------------------------------------------------------
  `elsif CadenceVerification
    initial begin
      StartUp;

      PressModeButton;
      PressModeButton;
      PressModeButton;

      Speed20km_Cadence150rps;
      for (int i=0;i<3;i++)
        #3s CadenceTest;

      Speed10km_Cadence100rps;
      for (int i=0;i<3;i++)
        #3s CadenceTest;

      BicycleStopped;
      for (int i=0;i<3;i++)
        #3s CadenceTest;

      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level Simple Verification
  //--------------------------------------------------------------
  `elsif SimpleVerification
    initial begin
      StartUp;

      // Fast Speed
      Speed20km_Cadence150rps;
      #5s OdometerTest;
      PressModeButton;
      PressModeButton;
      #5s SpeedTest;
      PressModeButton;
      #5s CadenceTest;
      PressModeButton;

      // Slow Speed
      Speed10km_Cadence100rps;
      #5s OdometerTest;
      PressModeButton;
      PressModeButton;
      #5s SpeedTest;
      PressModeButton;
      #5s CadenceTest;
      PressModeButton;

      // Time Test
      #31s TripTimeTest;

      // Stop Test
      BicycleStopped;
      #61s;
      trip_time = trip_time - 61;
      TripTimeTest;
      PressModeButton;
      #3s SpeedTest;
      PressModeButton;
      #3s CadenceTest;
      PressModeButton;
      #3s OdometerTest;

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

  `endif
