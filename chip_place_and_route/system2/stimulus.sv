
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
  `define SpeedVerification         // Not Verified
//  `define CadenceVerification       // Behavioural Passed
//  `define ModeSwitchVerification    // Gate Level Passed
//  `define SettingVerification       // Not verified
//  `define TimeStopVerification      // Not verified
//  `define ScanPathVerification
//  `define SimpleVerification        // Behavioural Passed 
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
  speed = 0,
  clock_count = 0;

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
    $display("\n Custom wheel size switch start.\n");
    $display("------------------------------------------------------------------------------");

    wheel_size = (real'(wheelsize_ref)/1000);

    integer
      wheelsize_ref_dig2,
      wheelsize_ref_dig1,
      wheelsize_ref_dig0;

    wheelsize_ref_dig2 = (wheelsize_ref/100)%10;
    wheelsize_ref_dig1 = (wheelsize_ref/ 10)%10;
    wheelsize_ref_dig0 =  wheelsize_ref     %10;

    PressSettingButton;
    #1s DisplaySegment;
    
    while (seg_digit_value2 != wheelsize_ref_dig2) begin
      #1s -> press_trip_button;
      #1s DisplaySegment;
    end
    #1s -> press_mode_button;

    while (seg_digit_value1 != wheelsize_ref_dig1) begin
      #1s -> press_trip_button;
      #1s DisplaySegment;
    end
    #1s -> press_mode_button;

    while (seg_digit_value0 != wheelsize_ref_dig0) begin
      #1s -> press_trip_button;
      #1s DisplaySegment;
    end
    #1s -> press_mode_button;

    #1s DisplaySegment;
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

      PressModeButton;

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

      BicycleStopped;

      PressModeButton;
      
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

      PressModeButton;
      #4s;
      PressModeButton;
      #4s;

      Speed20km_Cadence150rps;
      for (int i=0;i<10;i++)
        #3s SpeedTest;

      Speed10km_Cadence100rps;
      for (int i=0;i<10;i++)
        #3s SpeedTest;

      BicycleStopped;
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

      PressModeButton;
      PressModeButton;
      PressModeButton;

      Speed20km_Cadence150rps;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      for (int i=0;i<3;i++)
        #9s CadenceTest;

      Speed10km_Cadence100rps;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      for (int i=0;i<3;i++)
        #9s CadenceTest;

      BicycleStopped;
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
  // Gate Level Setting Verification
  //--------------------------------------------------------------
  `elsif SettingVerification
    initial begin
      StartUp;

      PressSettingButton;

      for (int j=0;j<5;j++) begin
        for (int i=0;i<13;i++) begin
          PressTripButton;
          #1ms;
          DisplaySegment;
        end
        PressModeButton;
      end
      
      EndSimulation;
    end

  //--------------------------------------------------------------
  // Gate Level ScanPath Verification
  //--------------------------------------------------------------
  `elsif ScanPathVerification
    initial begin
      StartUp;

      $display("\n Scan path has been enabled.\n");

      @(posedge Clock);
      #(`clock_period/4);
        Test = '1;
      @(posedge Clock);
      #(`clock_period/4);
        ScanEnable = '1;
      #0.5s;
      @(posedge Clock);
      #(`clock_period/4);
        SDI = '1;
      @(posedge Clock);
      #(`clock_period/4);
        SDI = '0;

      for (int i=0;i<8;i++) begin
        @(posedge SDO);
        $display("\n Clock number = %d\n", clock_count);
      end

    end

  //--------------------------------------------------------------
  // Gate Level Simple Verification
  //--------------------------------------------------------------
  `elsif SimpleVerification
    initial begin
      StartUp;

      $display(" Fast Speed Test");
      Speed20km_Cadence150rps;
      for (int i = 0; i<5; i++)
        #1s $display("Running at %t", $time);
      OdometerTest;
      PressModeButton;
      PressModeButton;
      for (int i = 0; i<5; i++)
        #1s $display("Running at %t", $time);
      SpeedTest;
      PressModeButton;
      for (int i = 0; i<5; i++)
        #1s $display("Running at %t", $time);
      CadenceTest;
      PressModeButton;

      $display(" Slow Speed Test");
      Speed10km_Cadence100rps;
      for (int i = 0; i<5; i++)
        #1s $display("Running at %t", $time);
      OdometerTest;
      PressModeButton;
      PressModeButton;
      for (int i = 0; i<5; i++)
        #1s $display("Running at %t", $time);
      SpeedTest;
      PressModeButton;
      for (int i = 0; i<10; i++)
        #1s $display("Running at %t", $time);
      CadenceTest;
      PressModeButton;

      $display(" Time Test: Wait until 64s");
      PressModeButton;
      for (int i = 0; i<20; i++)
        #1s $display("Running at %t", $time);
      TripTimeTest;

      BicycleStopped;
      $display(" Stop Test: Wait until 128s");
      for (int i = 0; i<66; i++)
        #1s $display("Running at %t", $time);
      trip_time = trip_time - 61;
      TripTimeTest;
      PressModeButton;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      SpeedTest;
      PressModeButton;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      CadenceTest;
      PressModeButton;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      OdometerTest;

      $display(" Clear Test");
      PressTripButton;
      trip_time = 0;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
      OdometerTest;
      PressModeButton;
      for (int i = 0; i<3; i++)
        #1s $display("Running at %t", $time);
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
