///////////////////////////////////////////////////////////////////////
//
// computer module - 2022/2023
//
//    this is simply a shell representing the pad ring
//    which instances comp_core
//
///////////////////////////////////////////////////////////////////////

`include "options.sv"

`ifdef led_num_digits
  // already defined - do nothing
`else
  // default specification has 4 digits for the LED display
  `define led_num_digits 4
`endif

module computer(

  output SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP,
  output [`led_num_digits - 1:0] nDigit,

  `ifdef include_oled
    output SCLK, SDIN, DnC, nCS,
  `endif

  input tri1 nMode, nTrip,
  input tri1 nFork, nCrank,

  `ifndef no_scan_signals
    output SDO, input Test, SDI,
    `ifdef scan_enable
      ScanEnable,
    `endif
  `endif

  input Clock, nReset

  );

timeunit 1ns;
timeprecision 100ps;



//
// optionally synchronise the asynchronous reset in this wrapper
//

`ifdef synchronise_reset_within_wrapper

logic sync_nReset_1,sync_nReset_2;

always @( posedge Clock, negedge nReset )
  if ( ! nReset )
    begin
      sync_nReset_1 <= '0;
      sync_nReset_2 <= '0;
    end
  else
    begin
      sync_nReset_1 <= '1;
      sync_nReset_2 <= sync_nReset_1;
    end

  assign core_nReset = sync_nReset_2;

`else

  assign core_nReset = nReset;

`endif


//
// optionally synchronise the asynchronous inputs in this wrapper
//

`ifdef synchronise_inputs_within_wrapper

logic sync_nMode_1, sync_nMode_2;
logic sync_nTrip_1, sync_nTrip_2;
logic sync_nFork_1, sync_nFork_2;
logic sync_nCrank_1, sync_nCrank_2;

always @( posedge Clock, negedge core_nReset )
  if ( ! nReset )
    begin
      sync_nMode_1   <= '1;
      sync_nMode_2   <= '1;

      sync_nTrip_1   <= '1;
      sync_nTrip_2   <= '1;

      sync_nFork_1   <= '1;
      sync_nFork_2   <= '1;

      sync_nCrank_1   <= '1;
      sync_nCrank_2   <= '1;
    end
  else
    begin
      sync_nMode_1   <= nMode;
      sync_nMode_2   <= sync_nMode_1;

      sync_nTrip_1   <= nTrip;
      sync_nTrip_2   <= sync_nTrip_1;

      sync_nFork_1   <= nFork;
      sync_nFork_2   <= sync_nFork_1;

      sync_nCrank_1   <= nCrank;
      sync_nCrank_2   <= sync_nCrank_1;
    end

  assign core_nMode   = sync_nMode_2;
  assign core_nTrip   = sync_nTrip_2;
  assign core_nFork   = sync_nFork_2;
  assign core_nCrank   = sync_nCrank_2;

`else

  assign core_nMode   = nMode;
  assign core_nTrip   = nTrip;
  assign core_nFork   = nFork;
  assign core_nCrank   = nCrank;

`endif



comp_core COMP_core ( 

    .SegA, .SegB, .SegC, .SegD, .SegE, .SegF, .SegG, .DP, .nDigit,

    `ifdef include_oled
      .SCLK, .SDIN, .DnC, .nCS,
    `endif

    .nMode(core_nMode), .nTrip(core_nTrip),
    .nFork(core_nFork), .nCrank(core_nCrank),

    `ifndef no_scan_signals
      .SDO, .Test, .SDI,
      `ifdef scan_enable
        .ScanEnable,
      `endif
    `endif

    .Clock, .nReset(core_nReset)
  );

endmodule
