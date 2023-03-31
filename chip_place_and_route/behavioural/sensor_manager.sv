
//------------------------------------------------------------------------------
// Titile:  Sensor Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 3.1
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
// 6000_0004: 32bit | Recording triggerd 1 cycle crank time
// 6000_0008: 32bit | Recording triggerd 1 cycle fork time
//------------------------------------------------------------------------------

logic [15:0] fork_data;
logic [15:0] crank_time, fork_time;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

logic ahb_write;
logic [1:0] ahb_addr;

logic last_fork, last_crank;
logic [ 5:0] time_counter;
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
    ahb_write <= 0;
    ahb_addr <= 0;
  end
  else begin
    if (HREADY && HSEL && (HTRANS != NoTransfer)) begin
      ahb_write <= HWRITE;
      ahb_addr <= HADDR[3:2];
    end
    else begin
      ahb_write <= 0;
      ahb_addr <= 0;
    end
    
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
    delta_crank_time <= 0;
    delta_fork_time <= 0;
    time_counter <= 0;
    last_fork <= 0;
    last_crank <= 0;
    crank_time <= 0;
    fork_time <= 0;
  end
  else begin
    //--------------------------------------------------------------------------
    // Sensor Manager
    //--------------------------------------------------------------------------
    
    // Inner Timer: Count by 1 millisecond
    if (time_counter == Count1MS) begin 
      time_counter <= '0;
      if (delta_crank_time > 3000)
        crank_time <= delta_crank_time;
      else
        delta_crank_time <= delta_crank_time + 1;
      if (delta_fork_time > 3000)
        fork_time <= delta_fork_time;
      else
        delta_fork_time <= delta_fork_time + 1;
    end
    else
      time_counter <= time_counter + 1;
    
    // Increase fork and crank, Sample one cycle time
    if (!SYNC_nFork)
      last_fork <= 1;
    else if (last_fork) begin
      fork_data <= fork_data + 1;
      fork_time <= delta_fork_time;
      delta_fork_time <= 0;
      last_fork <= 0;
    end
    if (!SYNC_nCrank)
      last_crank <= 1;
    else if (last_crank) begin
      crank_time <= delta_crank_time;
      delta_crank_time <= 0;
      last_crank <= 0;
    end
    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------

    if (ahb_write && ahb_addr == 0)
      fork_data <= HWDATA;

  end
end

//------------------------------------------------------------------------------
// AHB Output
//------------------------------------------------------------------------------

always_comb begin
  HREADYOUT = '1;
  HRDATA = 32'b0;
  if (!ahb_write) begin
    case (ahb_addr)
      0 : HRDATA = fork_data;
      1 : HRDATA = crank_time;
      2 : HRDATA = fork_time;
    endcase
  end
end

endmodule

