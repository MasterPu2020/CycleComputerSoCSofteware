
//------------------------------------------------------------------------------
// Titile:  Timer Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 2.0
// Verification: Verified with Testbench. Verified with SoC.
// Comment: Operation Data with Word Only
//------------------------------------------------------------------------------

module timer(

  // Clock and Reset
  input  HCLK,
  input  HRESETn,

  // Hardware Software Interface
  input  HSEL,
  input  HREADY,
  input  HWRITE,
  input  [31:0] HADDR, // HADDR[2] used
  input  [31:0] HWDATA,
  input  [ 2:0] HSIZE, // 1 word only
  input  [ 1:0] HTRANS,
  output logic [31:0] HRDATA,
  output logic HREADYOUT

  // Physical Interface

);

timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map:
// 8000_0000: 32bit | Trip timer records less than 18 hours
// 8000_0004: 32bit | 3 second flag
//------------------------------------------------------------------------------

logic [15:0] trip_time;
logic time_up;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [2:0] {Idle, ReadLong, WriteLong, WriteTimeUp, ReadTimeUp} control;
logic [15:0] counter;
logic [15:0] last_trip_time;
// Parameters
localparam
  UpdateTime = 3,     // s
  ClockCycle = 30518, // ns = 30.5 us
  Count1S    = 32768, // = 1s / ClockCycle = 1,000,000 / 32,786.9
  NoTransfer = 2'b00; // AHB disabled

//------------------------------------------------------------------------------
// AHB Control signal generation
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    control <= Idle;
  end
  else begin  
         if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 0) &&  HWRITE)
      control <= WriteLong;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) &&  HWRITE)
      control <= WriteTimeUp;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 0) && !HWRITE) 
      control <= ReadLong;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) && !HWRITE) 
      control <= ReadTimeUp;
    else
      control <= Idle;
  end
end

//------------------------------------------------------------------------------
// One Cycle Delayed AHB Controled Timer
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    counter <= 0;
    trip_time <= 0;
    last_trip_time <= 0;
    time_up <= 0;
  end
  else begin
    //--------------------------------------------------------------------------
    // Timer
    //--------------------------------------------------------------------------

    // Count by 1 second
    if (counter == Count1S) begin 
      counter <= '0;
      trip_time <= trip_time + 1;
    end
    else
      counter <= counter + 1;

    // Time up flag
    if (trip_time - last_trip_time >= UpdateTime)
      time_up <= 1;
    else
      time_up <= 0;

    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      WriteLong: trip_time <= HWDATA[15:0]; // Write trip_time
      WriteTimeUp: last_trip_time <= trip_time;
    endcase
  end
end

//------------------------------------------------------------------------------
// AHB Output
//------------------------------------------------------------------------------

always_comb begin
  HREADYOUT = '1;
  HRDATA = 32'b0;
  case (control)
    ReadLong   : HRDATA = trip_time;
    ReadTimeUp : HRDATA = time_up;
  endcase
end

endmodule
