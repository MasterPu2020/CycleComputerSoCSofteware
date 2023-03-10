
//------------------------------------------------------------------------------
//  Title:  System module - 2022/2023 SubFile: Stimulus
//  Author: Clark Pu, Paiyun Chen (Circle)
//    Team: C4 Chip Designed
// Version: 2.0 Initial Behavioural Simulation
// Stimulus Process
//------------------------------------------------------------------------------

`define use_ahb_monitor
`define ingore_read_flag

//------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------

wire ingore_read;
`ifdef ingore_read_flag
  assign ingore_read = 1;
`else
  assign ingore_read = 0;
`endif

// Fake OLED Display: Initial Definition
logic [127:0] oled_ram [127:0];
logic [7:0] oled_command;
logic [15:0] oled_X, oled_Y, oled_real_colour;
logic [ 7:0] oled_x, oled_y;
integer oled_counter;
string oled_row;
logic DisplayRefresh = 0;

// Fake Seven Segment Display: Initial Definition
string seg_row;
logic [7:0] seg_data [3:0];
logic DisplayRefresh_Seg = 0;

integer 
  error = 0, 
  second = 0, 
  millisecond = 0, 
  real_forks = 0, 
  real_cranks = 0;
localparam 
  oneSecond  = 1_000_000_000,   // 1s
  oneMS      = 1_000_000,       // 1ms
  forkCycle  = 800_000_000,     // 0.8s 
  crankCycle = 1_200_000_000,   // 1.2s
  triggerDu  = 1_000_000,       // 0.01s
  oneUS      = 1_000;           // 1us

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
// AHB Monitors
//------------------------------------------------------------------------------

wire [31:0] ahb_addr;
wire [31:0] write_data;
wire write;
wire sel_timer, sel_segment, sel_sensor, sel_button, sel_oled;
wire [31:0] data_timer, data_segment, data_sensor, data_button, data_oled;

assign ahb_addr = COMPUTER.COMP_core.HADDR;
assign sel_timer   = COMPUTER.COMP_core.HSEL_TIMER;
assign sel_segment = COMPUTER.COMP_core.HSEL_SEG;
assign sel_sensor  = COMPUTER.COMP_core.HSEL_SENM;
assign sel_button  = COMPUTER.COMP_core.HSEL_BM;
assign sel_oled    = COMPUTER.COMP_core.HSEL_OLEDM;
assign data_timer   = COMPUTER.COMP_core.HRDATA_TIMER;
assign data_segment = COMPUTER.COMP_core.HRDATA_SEG;
assign data_sensor  = COMPUTER.COMP_core.HRDATA_SENM;
assign data_button  = COMPUTER.COMP_core.HRDATA_BM;
assign data_oled    = COMPUTER.COMP_core.HRDATA_OLEDM;
assign write = COMPUTER.COMP_core.HWRITE;
assign write_data = COMPUTER.COMP_core.HWDATA;

initial $timeformat(0, 2, "s", 10);

`ifdef use_ahb_monitor

// Timer Moniter
always @(posedge Clock) begin
  if (sel_timer) begin
    if (!ingore_read || ahb_addr[7:2] != 2)
      $display(" Timer Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Long Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Long Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Short Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && !write && !ingore_read )
      $display(" Read Flag Control Detected.  (%t)", $time);
    else if (!ingore_read || ahb_addr[7:2] != 2) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 2) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_timer, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end

// Sensor Manager Moniter
always @(posedge Clock) begin
  if (sel_sensor) begin
    $display(" Sensor Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Fork Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Fork Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Crank Control Detected. (%t)", $time);
    else begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (write) begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Write data: %d. (%t)",write_data, $time);
    end
    else begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Read data: %d. (%t)",data_sensor, $time);
    end
    $display("------------------------------------------------------------------------------");
  end
end

// OLED Manager Moniter
always @(posedge Clock) begin
  if (sel_oled) begin
    if (!ingore_read || ahb_addr[7:2] != 3 ) 
      $display(" OLED Manager Operation Detected.");
    if (ahb_addr[7:2] == 3 && write )
      $display(" Write Ready Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && write )
      $display(" Write Area Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && write )
      $display(" Write Colour1 Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && write )
      $display(" Write Colour2 Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 3 && !write && !ingore_read )
      $display(" Read Ready Control Detected. (%t)", $time);
    else if (!ingore_read || ahb_addr[7:2] != 3) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 3 ) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_oled, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end

// Seven Segment Manager Moniter : Write Only
always @(posedge Clock) begin
  if (sel_segment) begin
    $display(" Seven Segment Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Segment Fraction Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 1 && write )
      $display(" Write Segment Integer Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && write)
      $display(" Write Segment Mode Control Detected. (%t)", $time);
    else begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (write && (ahb_addr[7:2] == 0 || ahb_addr[7:2] == 1 || ahb_addr[7:2] == 2)) begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Write data: %d. (%t)",write_data, $time);
    end
    $display("------------------------------------------------------------------------------");
  end
end

// Button Manager Moniter : Read Only
always @(posedge Clock) begin
  if (sel_button) begin
    if (!ingore_read || ahb_addr[7:2] != 4 )
      $display(" Button Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Day Night Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Mode Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && !write )
      $display(" Read Trip Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 3 && !write )
      $display(" Read Setting Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 4 && !write && !ingore_read)
      $display(" Read NewData Control Detected. (%t)", $time);
    else if (!ingore_read) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 4 ) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_button, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end

`endif

//------------------------------------------------------------------------------
// Real Environment Simulation
//------------------------------------------------------------------------------

integer
  wheel_size = 2.136,
  crank_cycle = 1200, // ms
  fork_cycle = 800,  // ms
  noise = 24; //ms

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
    #3s;
    speed = (wheel_size * (fork_times - last_fork_times))/(trip_time - last_trip_time); // m/s
  end
end

initial begin // Cadence will keep measuring
  start_up_delay();
  forever begin
    last_trip_time = trip_time;
    last_crank_times = crank_times;
    #3s;
    cadence = (crank_times - last_crank_times) * 20;
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
  // Odometer Task(s)
  //--------------------------------------------------------------

  task OdometerVerification; // This will test if the recoreded odometer matchs the real odometer
    $display("\n Odometer verification start.\n");
    $display("------------------------------------------------------------------------------");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    $display("fork_times = %d", fork_times);
    odometer = 2.136 * fork_times; // meter
      segment_odometer = COMPUTER.COMP_core.seven_segment_1.Store_Frac[ 3:0] * 10
        + COMPUTER.COMP_core.seven_segment_1.Store_Frac[ 7:4] * 100
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [ 3:0] * 1000
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [ 7:4] * 10000
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [11:8] * 100000;
    $display("\n Real Odometer is %dm. Segment display is %dm. (%t)\n", odometer, segment_odometer, $time);
    //assert (segment_odometer - odometer < 20 && odometer - segment_odometer < 20) else begin
      //$display(" *** WARNING ***: Odometer result error more than 20m.");
      //error = error + 1;
    //end
    $display("\n Odometer verification end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Speedometer Task(s)
  //--------------------------------------------------------------

  task SpeedVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Speed verification start.\n");
    $display("------------------------------------------------------------------------------");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
      segment_odometer = COMPUTER.COMP_core.seven_segment_1.Store_Frac[ 3:0] * 10
        + COMPUTER.COMP_core.seven_segment_1.Store_Frac[ 7:4] * 100
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [ 3:0] * 1000
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [ 7:4] * 10000
        + COMPUTER.COMP_core.seven_segment_1.Store_Int [11:8] * 100000;
    $display("\n Real Speed is %d km/h. Segment display is %d km/h. (%t)\n", (speed * 3.6), segment_speed, $time);
    assert (segment_speed - (speed * 3.6) < 2 && (speed * 3.6) - segment_speed < 2) else begin
      $display(" *** WARNING ***: Speed result error more than 1km/h.");
      error = error + 1;
    end
    $display("\n Speed verification end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Cadence Meter Task(s)
  //--------------------------------------------------------------
  task CadenceVerification; // This will test if the recoreded speed matchs the real speed
    $display("\n Cadence verification start.\n");
    $display("------------------------------------------------------------------------------");
    while (!(sel_segment && (ahb_addr[2] == 1))) // AHB write
      @(posedge Clock);
    #(`clock_period + `clock_period/2); // AHB write complete
    segment_cadence = COMPUTER.COMP_core.seven_segment_1.Store_Int[3:0]
      + COMPUTER.COMP_core.seven_segment_1.Store_Int[7:4] * 10
      + COMPUTER.COMP_core.seven_segment_1.Store_Int[11:8] * 100;
    $display("\n Real Cadence is %d rpm. Segment display is %d rpm. (%t)\n", cadence, segment_cadence, $time);
    assert (segment_cadence - cadence < 10 && cadence - segment_cadence < 10) else begin
      $display(" *** WARNING ***: Cadence result error more than 10 rpm.");
      error = error + 1;
    end
    $display("\n Cadence verification end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  //--------------------------------------------------------------
  // Button Manager Tasks
  //--------------------------------------------------------------
  task ButtonNoiseTest; // This will test if the button will debaunce 
    $display("\n Noise test start.\n");
    $display("------------------------------------------------------------------------------");
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
    $display("\n Noise test end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  task PressModeButtonTest; // This will test if the press of the mode button will be detected
    $display("\n Press Mode 1 times test start.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_mode_button;
    $display("\n Wait for the software to check to the button.\n");
    while (!(sel_button && (ahb_addr[4:2] == 1))) // AHB read mode command
      @(posedge Clock);
    #(`clock_period/2); // AHB read mode data
    if (data_button == 1)
      $display("\n Button mode is pressed. (%t)\n", $time);
    assert (data_button == 1) else begin
      $display("\n *** WARNING ***: Button mode is NOT pressed. (%t)\n", $time);
      error = error + 1;
    end
    $display("\n Press Mode 1 times test end.\n");
    $display("------------------------------------------------------------------------------");
  endtask

  task PressTripButtonTest; // This will test if the press of the trip button will be detected
    $display("\n Press Trip 1 time test start.\n");
    $display("------------------------------------------------------------------------------");
    #1s -> press_trip_button;
    $display("\n Wait for the software to check to the button.\n");
    while (!(sel_button && (ahb_addr[4:2] == 2))) // AHB read mode command
      @(posedge Clock);
    #(`clock_period/2); // AHB read mode data
    if (data_button == 1) begin
      $display("\n Button trip is pressed. (%t)\n", $time);
      odometer = 0;
      trip_time = 0;
    end
    assert (data_button == 1) else begin
      $display("\n *** WARNING ***: Button trip is NOT pressed. (%t)\n", $time);
      error = error + 1;
    end
      $display("\n Press Trip 1 time test end.\n");
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

  task DisplaySegment;
    @(posedge Clock);
    @(posedge Clock);
    @(posedge Clock);
    @(posedge Clock);
    DisplayRefresh_Seg = 0;
    @(posedge Clock);
    DisplayRefresh_Seg = 1;
    @(posedge Clock);
    DisplayRefresh_Seg = 0;
  endtask

  //--------------------------------------------------------------
  // Accuracy Verification Tasks
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
//------------------------------------------------------------------------------

// Basic Functional Test: Enable Moniter to Check

// Initial behavioural test
initial begin

  StartUp;

  //--------------------------------------------------------------
  // Trip Time Clear Test
  //--------------------------------------------------------------
    FastSpeedTest;
    #70s;
    PressModeButtonTest;
    #0.5s;
    DisplaySegment;
    PressTripButtonTest;
    #0.5s;
    DisplaySegment;

  //--------------------------------------------------------------
  // Trip Time Stop Test
  //--------------------------------------------------------------
    /*
    FastSpeedTest;
    #70s;

    PressModeButtonTest;
    DisplaySegment;

    ZeroSpeedTest;
    #70s;
    
    DisplaySegment;
    */
  
  //--------------------------------------------------------------
  // Cadence Verification Test
  //--------------------------------------------------------------
    /*
    FastSpeedTest;
    SinglePressModeButton;
    SinglePressModeButton;
    SinglePressModeButton;


    for (int i=0; i<10; i++) begin
      #3s;
      CadenceVerification;
      DisplaySegment;
    end
    */

  //--------------------------------------------------------------
  // Odometer Verification Test
  //--------------------------------------------------------------
    /*
    FastSpeedTest;

    #5s;
    OdometerVerification;
    DisplaySegment;

    PressModeButtonTest;
    #5s;
    $display("\n This is trip time. And real trip time is %ds:\n ", trip_time);
    DisplaySegment;

    PressModeButtonTest;
    #5s;
    $display("\n This is speed:");
    DisplaySegment;

    PressModeButtonTest;
    #5s;
    $display("\n This is cadence:");
    DisplaySegment;

    #5s;
    PressTripButtonTest;
    OdometerVerification;
    DisplaySegment;
    */


  #5s;
  $stop;
  $finish;

end

//------------------------------------------------------------------------------
// Fake OLED Display: Get Area and Colour
//------------------------------------------------------------------------------

initial begin
  oled_counter = 0;
  oled_command = 0;
  oled_X = 0;
  oled_Y = 0;
  oled_x = 0; 
  oled_y = 0;
  oled_real_colour = 0;
  forever begin
    @(posedge SCLK);
    if (DnC) begin
      if (oled_command == 8'b0001_0101) begin // oled_X location
        // $display("Writing oled_X... NO.%d bit", oled_counter);
        oled_X[0] = SDIN;
        if (oled_counter >= 15)
          oled_counter = 0;
        else begin
          oled_counter ++;
          oled_X = oled_X << 1;
          oled_x = oled_X[15:8];
        end
      end
      else if (oled_command == 8'b0111_0101) begin // oled_Y location
        // $display("Writing oled_Y... NO.%d bit", oled_counter);
        oled_Y[0] = SDIN;
        if (oled_counter >= 15)
          oled_counter = 0;
        else begin
          oled_counter ++;
          oled_Y = oled_Y << 1;
          oled_y = oled_Y[15:8];
        end
      end
      else if (oled_command == 8'b0101_1100) begin // Real Colour
        // $display("Writing Colour... NO.%d bit", oled_counter);
        oled_real_colour[0] = SDIN;
        if (oled_counter >= 15) begin
          oled_counter = 0;
          if (oled_real_colour == 0) begin
            oled_ram[oled_x][oled_y] = 0;
            $display(" Pixel(%d, %d) 0 is written into OLED RAM (%t)", oled_x, oled_y, $time);
          end
          else begin
            oled_ram[oled_x][oled_y] = 1;
            $display(" Pixel(%d, %d) 1 is written into OLED RAM (%t)", oled_x, oled_y, $time);
          end
          if (oled_x == oled_X[7:0]) begin
            oled_x = oled_X[15:8];
            if (oled_y == oled_Y[7:0])
              oled_y = oled_Y[15:8];
            else
              oled_y = oled_y + 1;
          end
          else
            oled_x = oled_x + 1;
        end
        else begin
          oled_counter ++;
          oled_real_colour = oled_real_colour << 1;
        end
      end
    end
    else begin
      // $display("Writing Command... NO.%d bit", oled_counter);
      oled_command[0] = SDIN;
      if (oled_counter >= 7) begin
        oled_counter = 0;
        // // Debug
        // if (oled_command == 8'b0001_0101)
        //   $display("CMD: oled_X location. Accepted.");
        // else if (oled_command == 8'b0111_0101)
        //   $display("CMD: oled_Y location. Accepted.");
        // else if (oled_command == 8'b0101_1100)
        //   $display("CMD: Colour. Accepted.");
        if (oled_command != 8'b0001_0101 && oled_command != 8'b0111_0101 && oled_command != 8'b0101_1100)
          $display("CMD: Unknown: %b.", oled_command, " Rejected.");
      end
      else begin
        oled_counter ++;
        oled_command = oled_command << 1;
      end
    end
  end
end

//------------------------------------------------------------------------------
// Fake OLED Display: Post Text Picture
//------------------------------------------------------------------------------

initial begin
  forever begin
    @(DisplayRefresh);
    oled_row = "  ";
    $display("Refresh Screen: ");
    for (integer j = 0; j < 96; j++) begin
      for (integer i = 0; i < 128; i++) begin
        if(oled_ram[i][j])
          oled_row = {oled_row, "#"};
        else
          oled_row = {oled_row, "_"};
      end
      $display("%s", oled_row);
      oled_row = "  ";
    end
  end
end

//------------------------------------------------------------------------------
// Fake Seven Segment Display: Screen Demonstration
//------------------------------------------------------------------------------

initial begin
  forever begin
    @ (posedge Clock);
    case (nDigit)
      4'b1110: begin seg_data[3] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b1101: begin seg_data[2] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b1011: begin seg_data[1] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b0111: begin seg_data[0] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
    endcase
  end
end

initial begin

  forever begin

    @(posedge DisplayRefresh_Seg);

    $display("\n Refresh Seven Segment LED: \n");
    seg_row = "   ";

    // SegA
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][7])
        seg_row = {seg_row, "---######---"};
      else if ((seg_data[m][2]) && (seg_data[m][6]))
        seg_row = {seg_row, "---#----#---"};
      else if ((seg_data[m][2]) && (!seg_data[m][6]))
        seg_row = {seg_row, "---#--------"};
      else if ((!seg_data[m][2]) && (seg_data[m][6]))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // SegF & SegB
    for (integer n = 0; n < 3; n++) begin
      for (integer m = 0; m < 4; m++) begin
        if ((seg_data[m][2]) && (seg_data[m][6]))
          seg_row = {seg_row, "---#----#---"};
        else if ((seg_data[m][2]) && (!seg_data[m][6]))
          seg_row = {seg_row, "---#--------"};
        else if ((!seg_data[m][2]) && (seg_data[m][6]))
          seg_row = {seg_row, "--------#---"};
        else
          seg_row = {seg_row, "------------"};
      end
      $display("%s", seg_row);
      seg_row = "   ";
    end

    // SegG
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][1])
        seg_row = {seg_row, "---######---"};
      else if (((seg_data[m][3]) || (seg_data[m][2])) && ((seg_data[m][5]) || (seg_data[m][6])))
        seg_row = {seg_row, "---#----#---"};
      else if (((seg_data[m][3]) || (seg_data[m][2])) && ((!seg_data[m][5]) && (!seg_data[m][6])))
        seg_row = {seg_row, "---#--------"};
      else if (((!seg_data[m][3]) && (!seg_data[m][2])) && ((seg_data[m][5]) || (seg_data[m][6])))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // SegE & SegC
    for (integer n = 0; n < 3; n++) begin
      for (integer m = 0; m < 4; m++) begin
        if ((seg_data[m][3]) && (seg_data[m][5]))
          seg_row = {seg_row, "---#----#---"};
        else if ((seg_data[m][3]) && (!seg_data[m][5]))
          seg_row = {seg_row, "---#--------"};
        else if ((!seg_data[m][3]) && (seg_data[m][5]))
          seg_row = {seg_row, "--------#---"};
        else
          seg_row = {seg_row, "------------"};
      end
      $display("%s", seg_row);
      seg_row = "   ";
    end

    // SegD
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][4])
        seg_row = {seg_row, "---######---"};
      else if ((seg_data[m][3]) && (seg_data[m][5]))
        seg_row = {seg_row, "---#----#---"};
      else if ((seg_data[m][3]) && (!seg_data[m][5]))
        seg_row = {seg_row, "---#--------"};
      else if ((!seg_data[m][3]) && (seg_data[m][5]))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // DP
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][0])
        seg_row = {seg_row, "----------##"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s\n", seg_row);
    seg_row = "   ";

    $display("------------------------------------------------------------------------------");
  
  end
end