
//------------------------------------------------------------------------------
// Titile:  Sensor Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 3.0
// Verification: Verified
// Comment: Redesigned
//------------------------------------------------------------------------------

module sensor_manager(

  // Clock and Reset
  input  HCLK,
  input  HRESETn,

  // Hardware Software Interface
  input  HSEL,
  input  HREADY,
  input  HWRITE,
  input  [31:0] HADDR, // HADDR[4:2] used
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
// 6000_0004: 32bit | Recording triggerd delta crank cycle number
// 6000_0008: 32bit | Recording triggerd delta fork cycle number
// 6000_000A: 32bit | Recording triggerd delta crank time
// 6000_0010: 32bit | Recording triggerd delta fork time
//------------------------------------------------------------------------------

logic [15:0] fork_data;
logic [ 7:0] delta_crank_data, delta_fork_data;
logic [15:0] crank_time, fork_time;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [2:0] {Idle, ReadDeltaCrank, ReadDeltaFork, ReadDeltaCrankTime, ReadDeltaForkTime, ReadFork, WriteFork} control;
logic last_fork, last_crank;
logic clear_delta_fork, clear_delta_crank;
logic [ 5:0] time_counter;
logic [15:0] sample_crank_time, sample_fork_time;
logic [15:0] delta_crank_time, delta_fork_time;

logic  SYNC_MID_nFork,  SYNC_nFork;
logic  SYNC_MID_nCrank, SYNC_nCrank;

// Parameters
localparam
  Count1MS   = 32,    // = 1ms / ClockCycle = 1,000 / 32.8 adjusted to fit 3s
  NoTransfer = 2'b00; // AHB disabled

//------------------------------------------------------------------------------
// AHB Control signal generation
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    control <= Idle;
    crank_time <= 0;
    fork_time <= 0;
  end
  else begin
    if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 0) &&  HWRITE)
      control <= WriteFork;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 0) && !HWRITE)
      control <= ReadFork;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 1) && !HWRITE) begin
      control <= ReadDeltaCrank;
      crank_time <= sample_crank_time; // Special: Save sample time for next reading operation
    end
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 2) && !HWRITE) begin
      control <= ReadDeltaFork;
      fork_time <= sample_fork_time; // Special: Save sample time for next reading operation
    end
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 3) && !HWRITE) 
      control <= ReadDeltaCrankTime;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[4:2] == 4) && !HWRITE) 
      control <= ReadDeltaForkTime;
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
    fork_data <= 0;
    delta_crank_data <= 0;
    delta_fork_data <= 0;
    delta_crank_time <= 0;
    delta_fork_time <= 0;
    time_counter <= 0;
    sample_fork_time <= 0;
    sample_crank_time <= 0;
    clear_delta_fork <= 0;
    clear_delta_crank <= 0;
    last_fork <= 0;
    last_crank <= 0;
  end
  else begin
    //--------------------------------------------------------------------------
    // Sensor Manager
    //--------------------------------------------------------------------------
    
    // Inner Timer: Count by 1 millisecond
    if (time_counter == Count1MS) begin 
      time_counter <= '0;
      delta_fork_time <= delta_fork_time + 1;
      delta_crank_time <= delta_crank_time + 1;
    end
    else
      time_counter <= time_counter + 1;
    
    // Increase fork and crank, Sample one cycle time
    if (!SYNC_nFork)
      last_fork <= 1;
    else if (last_fork) begin
      fork_data <= fork_data + 1;
      if (clear_delta_fork) begin // Clear fork at the hall point
        delta_fork_data <= 0;
        delta_fork_time <= 0;
        clear_delta_fork <= 0;
      end
      else begin
        delta_fork_data <= delta_fork_data + 1;
        sample_fork_time <= delta_fork_time;
      end
      last_fork <= 0;
    end
    if (!SYNC_nCrank)
      last_crank <= 1;
    else if (last_crank) begin
      if (clear_delta_crank) begin // Clear crank at the hall point
        delta_crank_data <= 0;
        delta_crank_time <= 0;
        clear_delta_crank <= 0;
      end
      else begin
        delta_crank_data <= delta_crank_data + 1;
        sample_crank_time <= delta_crank_time;
      end
      last_crank <= 0;
    end

    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      ReadDeltaCrank : begin delta_crank_data <= 0; clear_delta_crank <= 1; end
      ReadDeltaFork  : begin delta_fork_data  <= 0; clear_delta_fork  <= 1; end
      WriteFork      : fork_data <= HWDATA[15:0];
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
    ReadDeltaCrank     : HRDATA = delta_crank_data;
    ReadDeltaCrankTime : HRDATA = crank_time;
    ReadDeltaFork      : HRDATA = delta_fork_data;
    ReadDeltaForkTime  : HRDATA = fork_time;
    ReadFork           : HRDATA = fork_data;
  endcase
end

endmodule

