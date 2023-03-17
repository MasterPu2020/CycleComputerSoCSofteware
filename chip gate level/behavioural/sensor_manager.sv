
//------------------------------------------------------------------------------
// Titile:  Sensor Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 2.0
// Verification: Verified with Testbench. Verified with SoC.
// Comment: Operation Data with Word Only
//------------------------------------------------------------------------------

module sensor_manager(

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
  output logic HREADYOUT,

  // Physical Interface
  input nFork,
  input nCrank

);

timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map:
// 6000_0000: 32bit | Recording triggerd fork cycle number
// 6000_0004: 32bit | Recording triggerd crank cycle number
//------------------------------------------------------------------------------

logic [15:0] forks, cranks;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [1:0] {Idle, ReadCrank, ReadFork, WriteFork} control;
logic last_fork, last_crank;

logic  SYNC_MID_nFork,  SYNC_nFork;
logic  SYNC_MID_nCrank, SYNC_nCrank;

// Parameters
localparam
  NoTransfer = 2'b00; // AHB disabled

//------------------------------------------------------------------------------
// AHB Control signal generation
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    control <= Idle;
  end
  else begin
    if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[2] == 0) &&  HWRITE)
      control <= WriteFork;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[2] == 0) && !HWRITE)
      control <= ReadFork;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[2] == 1) && !HWRITE) 
      control <= ReadCrank;
    else
      control <= Idle;
  end
end

//------------------------------------------------------------------------------
// Input Synchronization : nFork, nCrank
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    SYNC_MID_nCrank <= '0;  SYNC_nCrank <= '0;
    SYNC_MID_nFork  <= '0;  SYNC_nFork <= '0;
  end
  else begin
    SYNC_nCrank <= SYNC_MID_nCrank; SYNC_MID_nCrank <= nCrank;
    SYNC_nFork  <= SYNC_MID_nFork;  SYNC_MID_nFork  <= nFork;
  end
end

//------------------------------------------------------------------------------
// One Cycle Delayed AHB Controled Sensor Manager
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    forks <= '0;
    cranks <= '0;
    last_fork <= '0;
    last_crank <= '0;
  end
  else begin
    //--------------------------------------------------------------------------
    // Sensor Manager
    //--------------------------------------------------------------------------
    // Increase fork and crank
    if (!SYNC_nFork)
      last_fork <= 1;
    else if (last_fork) begin
      forks <= forks + 1;
      last_fork <= 0;
    end
    if (!SYNC_nCrank)
      last_crank <= 1;
    else if (last_crank) begin
      cranks <= cranks + 1;
      last_crank <= 0;
    end
    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      ReadCrank : cranks <= '0; // Clear crank after it's been read
      WriteFork :  forks <= HWDATA[15:0];
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
    ReadCrank : HRDATA = {16'b0, cranks};
    ReadFork  : HRDATA = {16'b0, forks};
  endcase
end

endmodule

