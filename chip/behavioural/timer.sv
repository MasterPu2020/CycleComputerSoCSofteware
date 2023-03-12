
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
  input  [31:0] HADDR, // HADDR[3:2] used
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
// 8000_0000: 32bit | Long timer records less than 18 hours
// 8000_0004: 32bit | Short timer records less than 65 seconds
// 8000_0008: 32bit | 3 second flag
//------------------------------------------------------------------------------

logic [15:0] short, long;
logic time_up;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [2:0] {Idle, ReadLong, WriteLong, ReadShort, ReadTimeUp} control;
logic [15:0] long_counter;
logic [ 5:0] short_counter;
// Parameters
localparam
  ClockCycle = 30518, // ns = 30.5 us
  Count1S    = 32768, // = 1s / ClockCycle = 1,000,000 / 32,786.9
  Count1MS   = 32,    // = 1ms / ClockCycle = 1,000 / 32.8 adjusted to fit 3s
  TimeUp     = 3000,  // 3000 ms = 3s
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
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 0) && !HWRITE)
      control <= ReadLong;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) && !HWRITE) 
      control <= ReadShort;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 2) && !HWRITE) 
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
    long_counter <= '0;
    long <= '0;
    short_counter <= '0;
    short <= '0;
    time_up <= '0;
  end
  else begin
    //--------------------------------------------------------------------------
    // Timer
    //--------------------------------------------------------------------------
    // Count by 1 millisecond
    if (short_counter == Count1MS) begin 
      short_counter <= '0;
      short <= short + 1;
    end
    else
      short_counter <= short_counter + 1;
    // Count by 1 second
    if (long_counter == Count1S) begin 
      long_counter <= '0;
      long <= long + 1;
    end
    else
      long_counter <= long_counter + 1;
    // Time up flag
    if (short >= TimeUp) 
      time_up <= 1;
    else
      time_up <= 0;
    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      WriteLong: long <= HWDATA[15:0]; // Write long
      ReadShort: short <= '0; // Clear short after it's been read
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
    ReadLong   : HRDATA = {16'b0, long};
    ReadShort  : HRDATA = {16'b0, short};
    ReadTimeUp : HRDATA = {31'b0, time_up};
  endcase
end

endmodule
