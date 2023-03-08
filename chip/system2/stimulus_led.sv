
//------------------------------------------------------------------------------
//  Titile: System module - 2022/2023 SubFile: Stimulus
//  Author: Clark Pu, Chen Paiyun
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
    else begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (write && (ahb_addr[7:2] == 0 || ahb_addr[7:2] == 1)) begin
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
// Tasks
//------------------------------------------------------------------------------

integer
  wheel_size = 700,
  crank_cycle = 1200, // ms
  fork_cycle = 800,  // ms
  noise = 12; //ms

integer
  odometer = 0,
  segment_odometer = 0,
  crank_times = 0,
  fork_times = 0,
  speed = 0;

initial begin 
  start_up_delay();
  crank_times = 0;
  forever begin
    #(crank_cycle * 1000_000) -> trigger_crank_sensor;
    crank_times ++;
  end
end

initial begin 
  start_up_delay();
  fork_times = 0;
  forever begin
    #(fork_cycle * 1000_000) -> trigger_fork_sensor;
    fork_times ++;
  end
end

task OdometerVerification;
  $display("\n Odometer verification start.\n");
  while (!(sel_segment && (ahb_addr[2] == 1)))
    @(posedge Clock);
  #(`clock_period + `clock_period/2);
  odometer = (wheel_size * 3.14 / 1000) * fork_times; // meter
  if (COMPUTER.COMP_core.seven_segment_1.SevenSeg_Store_Integer < 10)
    segment_odometer = COMPUTER.COMP_core.seven_segment_1.SevenSeg_Store_Decimal * 10
      + COMPUTER.COMP_core.seven_segment_1.SevenSeg_Store_Integer * 1000;
  else
    segment_odometer = COMPUTER.COMP_core.seven_segment_1.SevenSeg_Store_Decimal * 100
      + COMPUTER.COMP_core.seven_segment_1.SevenSeg_Store_Integer * 1000;
  $display("\n Answer is %dm. Result is %dm. (%t)\n", odometer, segment_odometer, $time);
  assert (segment_odometer - odometer < 20 && odometer - segment_odometer < 20) else begin
    $display(" *** WARNING ***: Odometer result does not match the answer. Answer is %dm. Result is %dm. (%t)", odometer, segment_odometer, $time);
    error = error + 1;
  end
  $display("\n Odometer verification end.\n");
endtask

task NoiseTest;
  $display("\n Noise test start.\n");
  #2s;
  Trip = 1;
  #(noise * 1000_000);
  Trip = 0;
  #1s;
  Trip = 1;
  #(noise * 1000_000);
  Trip = 0;
  #1s;
  Mode = 1;
  #(noise * 1000_000);
  Mode = 0;
  #1s;
  Mode = 1;
  #(noise * 1000_000);
  Mode = 0;
  $display("\n Noise test end.\n");
endtask

task PressModeButtonTest;
  $display("\n Press Mode 4 times test start.\n");
  for(int i=0;i<4;i++)
    #1s -> press_mode_button;
  $display("\n Press Mode 4 times test end.\n");
endtask

task PressTripButtonTest;
  $display("\n Press Trip 1 time test start.\n");
  #1s -> press_trip_button;
  odometer = 0;
  $display("\n Press Trip 1 time test end.\n");
endtask

task SettingModeTest;
  $display("\n Setting mode test start.\n");
  #1s   -> press_mode_button;
  #17ms -> press_trip_button;
  for(int i=0;i<3;i++) begin
    #1s -> press_mode_button;
    for(int j=0;j<2;j++)
      #0.5s -> press_trip_button;
  end
  $display("\n Setting mode test end.\n");
endtask

task SettingModeExtremTest;
  $display("\n Setting Extrem mode test start.\n");
  #1s   -> press_mode_button;
  #1ns  -> press_trip_button;
  for(int i=0;i<3;i++) begin
    #1s -> press_mode_button;
    for(int j=0;j<2;j++)
      #0.5s -> press_trip_button;
  end
  $display("\n Setting Extrem mode test end.\n");
endtask

task NightModeTest;
  $display("\n Night mode test start.\n");
  for(int i=0;i<2;i++)
    #0.4s -> press_mode_button;
  $display("\n Night mode test end.\n");
endtask

task SuperManSpeed;
  $display("\n Watch out! Super Man is riding the bicycle!\n");
  crank_cycle = 4; // ms
  fork_cycle = 3;  // ms
endtask

task FastSpeedTest;
  $display("\n Change to fast speed.\n");
  crank_cycle = 400; // ms
  fork_cycle = 290;  // ms
endtask

task LowSpeedTest;
  $display("\n Change to Low speed.\n");
  crank_cycle = 1600; // ms
  fork_cycle = 1100;  // ms
endtask

task StartUp;
  Crank = 0;
  Fork = 0;
  Mode = 0;
  Trip = 0;
  DisplayRefresh_Seg = 0;
  start_up_delay();
  $display("\n Simulation Start.\n");
  $display("------------------------------------------------------------------------------");
endtask

//------------------------------------------------------------------------------
// Custom Stimulus & Verification
//------------------------------------------------------------------------------

// Basic Functional Test: Enable Moniter to Check

// Initial behavioural test
initial begin

  StartUp;

  // SuperManSpeed;

  FastSpeedTest;

  for (integer i = 0; i < 15; i ++) begin
    
    #0.5s;

    OdometerVerification;

    #0.5s;
    
    DisplayRefresh_Seg = 0;
    @(posedge Clock);
    DisplayRefresh_Seg = 1;

  end

  #1s;
  
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
      4'b1110: begin
        seg_data[3] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP};
      end
      4'b1101: begin
        seg_data[2] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP};
      end
      4'b1011: begin
        seg_data[1] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP};
      end
      4'b0111: begin
        seg_data[0] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP};
      end
    endcase
  end
end

initial begin

  forever begin

    @(posedge DisplayRefresh_Seg);

    $display("Refresh Seven Segment LED: ");
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
    $display("%s", seg_row);
    seg_row = "   ";
  
  end
end