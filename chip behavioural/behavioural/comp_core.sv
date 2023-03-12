//------------------------------------------------------------------------------
//  Titile: Computer Core
//  Source: Example arm_soc.sv
//    Team: C4 Chip Modified
// Version: 1.0
// Verification: Verified with Testbench. Verified with SoC.
// Comment: AHB bus.
//------------------------------------------------------------------------------

module comp_core(
  input Clock, nReset,
  input nFork, nCrank,
  input nTrip, nMode,
  output nCS, DnC, SDIN, SCLK,
  output SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP,
  output [3:0] nDigit
);
 
timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Wiring
//------------------------------------------------------------------------------

wire [31:0] HADDR, HWDATA, HRDATA;
wire [1:0] HTRANS;
wire [2:0] HSIZE, HBURST;
wire [3:0] HPROT;
wire HWRITE, HMASTLOCK, HRESP, HREADY;
wire          HSEL_ROM,      HSEL_RAM,      HSEL_BM,      HSEL_SENM,      HSEL_TIMER,      HSEL_SEG,      HSEL_OLEDM;
wire [31:0] HRDATA_ROM,    HRDATA_RAM,    HRDATA_BM,    HRDATA_SENM,    HRDATA_TIMER,    HRDATA_SEG,    HRDATA_OLEDM;
wire     HREADYOUT_ROM, HREADYOUT_RAM, HREADYOUT_BM, HREADYOUT_SENM, HREADYOUT_TIMER, HREADYOUT_SEG, HREADYOUT_OLEDM;
wire TXEV, RXEV, SLEEPING, SYSRESETREQ, NMI, LOCKUP;
wire [15:0] IRQ;

assign HRESP = '0;
assign NMI = '0;
assign IRQ = {16'b0000_0000_0000_0000};
assign RXEV = '0;

//------------------------------------------------------------------------------
// Instances
//------------------------------------------------------------------------------

// Coretex M0
CORTEXM0DS m0_1 (
  .HCLK(Clock), .HRESETn(nReset),
  .HADDR, .HBURST, .HMASTLOCK, .HPROT, .HSIZE, .HTRANS, .HWDATA, .HWRITE,
  .HRDATA, .HREADY, .HRESP,                                   
  .NMI, .IRQ, .TXEV, .RXEV, .LOCKUP, .SYSRESETREQ, .SLEEPING
);

// AHB Interconnect
ahb_interconnect ahb_interconnect_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HRDATA, .HREADY,
  .HSEL_SIGNALS({          HSEL_OLEDM,      HSEL_SEG,      HSEL_TIMER,     HSEL_SENM,       HSEL_BM,      HSEL_RAM,      HSEL_ROM}),
  .HRDATA_SIGNALS({      HRDATA_OLEDM,    HRDATA_SEG,    HRDATA_TIMER,   HRDATA_SENM,     HRDATA_BM,    HRDATA_RAM,    HRDATA_ROM}),
  .HREADYOUT_SIGNALS({HREADYOUT_OLEDM, HREADYOUT_SEG, HREADYOUT_TIMER, HREADYOUT_SENM, HREADYOUT_BM, HREADYOUT_RAM, HREADYOUT_ROM})
);

// AHBLite Slaves
ahb_rom rom_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_ROM),
  .HRDATA(HRDATA_ROM), .HREADYOUT(HREADYOUT_ROM)
);

ahb_ram ram_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_RAM),
  .HRDATA(HRDATA_RAM), .HREADYOUT(HREADYOUT_RAM)
);

timer timer_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_TIMER),
  .HRDATA(HRDATA_TIMER), .HREADYOUT(HREADYOUT_TIMER)
);

sensor_manager sensor_manager_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .nFork, .nCrank,
  .HSEL(HSEL_SENM),
  .HRDATA(HRDATA_SENM), .HREADYOUT(HREADYOUT_SENM)
);

oled_manager oled_manager_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .nCS, .DnC, .SDIN, .SCLK,
  .HSEL(HSEL_OLEDM),
  .HRDATA(HRDATA_OLEDM), .HREADYOUT(HREADYOUT_OLEDM)
);

button_manager button_manager_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .Trip(nTrip), .Mode(nMode),
  .HSEL(HSEL_BM),
  .HRDATA(HRDATA_BM), .HREADYOUT(HREADYOUT_BM)
);

seven_segment seven_segment_1 (
  .HCLK(Clock), .HRESETn(nReset), .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .SegA, .SegB, .SegC, .SegD, .SegE, .SegF, .SegG, .DP, .nDigit,
  .HSEL(HSEL_SEG),
  .HRDATA(HRDATA_SEG), .HREADYOUT(HREADYOUT_SEG)
);

endmodule
