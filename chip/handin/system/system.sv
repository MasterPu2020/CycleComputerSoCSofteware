///////////////////////////////////////////////////////////////////////
//
// system module - 2022/2023
//
//    this is the top-level module which describes the complete system
//
///////////////////////////////////////////////////////////////////////

`include "options.sv"

`ifdef clock_period
  // already defined - do nothing
`else
  // this is a default frequency of 32.768kHz
  `define clock_period 30517.6ns
  // note that the calculation of the period is not perfectly accurate
  //  - the inaccuracy here will most likely be less than that specified for the clock source itself
`endif

`ifdef num_modes
  // already defined - do nothing
`else
  // default specification has 4 modes
  `define num_modes 4
`endif

`ifdef led_num_digits
  // already defined - do nothing
`else
  // default specification has 4 digits for the LED display
  `define led_num_digits 4
`endif

`define STRINGIFY(x) `"x`"

module system;

timeunit 1ns;
// this precision allows for clock_period/2 and clock_period/4
timeprecision 10ps;

wire SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP;
wire [`led_num_digits - 1:0] nDigit;

wire SCLK, SDIN, DnC, nCS;

logic Mode, Trip, Fork, Crank;
wire nMode, nTrip, nFork, nCrank;
event press_mode_button, press_trip_button, trigger_fork_sensor, trigger_crank_sensor;

logic Button3;
wire nButton3;
event press_third_button;

wire SDO;
logic Clock, nReset, Test, SDI, ScanEnable;

int mode_index;


computer COMPUTER ( 
    .SegA, .SegB, .SegC, .SegD, .SegE, .SegF, .SegG, .DP, .nDigit,

    `ifdef include_oled
      .SCLK, .SDIN, .DnC, .nCS,
    `endif

    .nMode, .nTrip, .nFork, .nCrank,

    `ifdef third_button
      .`third_button(nButton3),
    `endif

    `ifndef no_scan_signals
      .SDO, .Test, .SDI,
      `ifdef scan_enable
        .ScanEnable,
      `endif
    `endif

    .Clock, .nReset
  );

`ifdef sdf_file
  initial
    $sdf_annotate( `STRINGIFY(`sdf_file), COMPUTER );
`endif

// the bicycle computer is supported by simulation models for the LED and OLED displays

led_display LED ( .SegA, .SegB, .SegC, .SegD, .SegE, .SegF, .SegG, .DP, .nDigit );

`ifdef include_oled
  oled_display OLED ( .SCLK, .SDIN, .DnC, .nCS, .nRES(nReset) );
`endif

// the inputs all pull down when active and high impedance at other times

assign nMode    = ( Mode )    ? '0 : 'z;
assign nTrip    = ( Trip )    ? '0 : 'z;
assign nButton3 = ( Button3 ) ? '0 : 'z;
assign nFork    = ( Fork )    ? '0 : 'z;
assign nCrank   = ( Crank )   ? '0 : 'z;

`ifdef external_pullup
  pullup( weak0, weak1 )(nMode);
  pullup( weak0, weak1 )(nTrip);
  pullup( weak0, weak1 )(nButton3);
  pullup( weak0, weak1 )(nFork);
  pullup( weak0, weak1 )(nCrank);
`endif

// display information about the design

initial
  begin
    $display( "COMPILATION OK" );
    $display( "CLOCK PERIOD IS ", `STRINGIFY(`clock_period) );
    `ifdef include_oled
      $display( "DISPLAY IS LED + OLED" );
    `else
      $display( "DISPLAY IS LED ONLY" );
    `endif
    $display( "This Bicycle Computer supports ", `STRINGIFY(`num_modes ), " modes:" );
    `ifdef Mode0
      $display( "  Mode 0: ", `STRINGIFY(`Mode0) );
    `endif
    `ifdef Mode1
      $display( "  Mode 1: ", `STRINGIFY(`Mode1) );
    `endif
    `ifdef Mode2
      $display( "  Mode 2: ", `STRINGIFY(`Mode2) );
    `endif
    `ifdef Mode3
      $display( "  Mode 3: ", `STRINGIFY(`Mode3) );
    `endif
    `ifdef Mode4
      $display( "  Mode 4: ", `STRINGIFY(`Mode4) );
    `endif
    `ifdef Mode5
      $display( "  Mode 5: ", `STRINGIFY(`Mode5) );
    `endif
    `ifdef Mode6
      $display( "  Mode 6: ", `STRINGIFY(`Mode6) );
    `endif
      $display( " (the computer will enter mode 0 on reset)");
  end


// define tasks to help with a simple stimulus

task start_up_delay( );
  begin
    `ifdef start_up_time
      #`start_up_time ;
    `endif
  end

endtask

always @(trigger_fork_sensor)
  begin

    `ifdef sanitise_input
      // delay until 1/4 of a clock period after a clock edge
      // - this should ensure that the clock delay to the
      //   synchronisation D-types doesn't cause setup/hold violations
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Fork = 1;
    
    #2ms

    `ifdef sanitise_input
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Fork = 0;
    
  end

always @(trigger_crank_sensor)
  begin

    `ifdef sanitise_input
      // delay until 1/4 of a clock period after a clock edge
      // - this should ensure that the clock delay to the
      //   synchronisation D-types doesn't cause setup/hold violations
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Crank = 1;
    
    #4ms

    `ifdef sanitise_input
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Crank = 0;
    
  end

always @(press_mode_button)
  begin

    `ifdef sanitise_input
      // delay until 1/4 of a clock period after a clock edge
      // - this should ensure that the clock delay to the
      //   synchronisation D-types doesn't cause setup/hold violations
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Mode = 1;
    
    #0.1s

    `ifdef sanitise_input
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Mode = 0;
    mode_index = ( mode_index + 1 ) % `num_modes;
    
  end

always @(press_trip_button)
  begin

    `ifdef sanitise_input
      // delay until 1/4 of a clock period after a clock edge
      // - this should ensure that the clock delay to the
      //   synchronisation D-types doesn't cause setup/hold violations
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Trip = 1;
    
    #0.1s

    `ifdef sanitise_input
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Trip = 0;
    
  end

always @(press_third_button)
  begin

    $display( "Press Third button" );

    `ifdef sanitise_input
      // delay until 1/4 of a clock period after a clock edge
      // - this should ensure that the clock delay to the
      //   synchronisation D-types doesn't cause setup/hold violations
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Button3 = 1;
    
    #0.1s

    `ifdef sanitise_input
      @(posedge Clock );
      #(`clock_period / 4)
    `endif

    Button3 = 0;
    
  end

`ifdef stimulus

  `include `STRINGIFY(`stimulus)

`else

  initial
    begin
      Test = 0;
      SDI = 0;
      ScanEnable = 0;
      nReset = 0;
      #(`clock_period / 4) nReset = 1;
    end

  initial
    begin
      Clock = 0;
      #`clock_period
      forever
        begin
          Clock = 1;
          #(`clock_period / 2) Clock = 0;
          #(`clock_period / 2) Clock = 0;
        end
    end


  // Button stimulus
  //
  //  This default stimulus represents a change in
  //  mode once per second 

  initial
    begin
      Mode = 0;
      Trip = 0;
      mode_index = 0;
      start_up_delay();
      `ifdef basic_mode_change
        forever
          #1s -> press_mode_button;
      `endif
    end
  

  // Hall-effect sensor stimulus
  //
  //  This default stimulus represents initial inactivity
  //  followed by pedalling at a constant rate 

  initial
    begin
      Crank = 0;
      start_up_delay();
      #0.5s
      forever
        #600ms -> trigger_crank_sensor;
    end
  
  initial
    begin
      Fork = 0;
      start_up_delay();
      #0.6s
      forever
        #384ms -> trigger_fork_sensor;
    end
  
  
`endif

`ifdef special_monitor

  `include "monitor.sv"

`endif

`ifdef sim_time

  initial
    begin
      #`sim_time
      $stop;
      $finish;
    end

`endif

endmodule
