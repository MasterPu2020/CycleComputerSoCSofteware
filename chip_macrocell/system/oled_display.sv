///////////////////////////////////////////////////////////////////////
//
// OLED display module
//
//    this version of the module is empty
//
//    a more advanced version might attempt to decode the inputs
//    to produce a value representing the number on the display
//
//    this module might also be the location of assert statements
//    to help with debugging
//
// Display module information:
//   Type: Adafruit 1.27" 128 x 96 pixels OLED
//   Driver chip: Solomon Systech SSD1351
//
//   Ports:
//	nRES	(Input - Active Low)
//		Reset pin
//
//	SCLK	(Input)
//		Clock for Serial Data
//
//	SDIN	(Input)
//		Serial Data
//
//	DnC	(Input)
//      	Data/nCommand 
//
//	nCS	(Input - Active Low)
//      	Chip Select
//
//
///////////////////////////////////////////////////////////////////////

`include "options.sv"

module oled_display (
  input nRES,
  input SCLK,
  input SDIN,
  input DnC,
  input nCS
  );

timeunit 1ns;
timeprecision 100ps;

  //
  // serial bus timing data from PCD8544 datasheet
  //
  // values are conservative, having been adjusted
  // assuming rise/fall time no greater than 15ns
  //
  specify
    specparam tres=2000ns;   // reset low pulse width

    specparam tcycle=50ns;   // clock cycle time

    specparam tas=15ns;      // DnC setup time
    specparam tah=15ns;      // DnC hold time

    specparam tcss=10ns;     // nCS setup time
    specparam tcsh=10ns;     // nCS hold time

    specparam tdsw=15ns;     // SDIN setup time
    specparam tdhw=15ns;     // SDIN hold time

    specparam tclkl=20ns;    // SCLK low time
    specparam tclkh=20ns;    // SCLK hight time

    specparam max_slew=15ns;

    // reset timings
    $width(negedge nRES, tres);

    // Serial clock timings
    $period(posedge SCLK &&& nRES, tcycle + (2*max_slew));
    $width(negedge SCLK &&& nRES, tclkl + (2*max_slew));
    $width(posedge SCLK &&& nRES, tclkh + (2*max_slew));

    // DnC timings relative to the clock
    $setup(DnC, posedge SCLK &&& nRES, tas + (2*max_slew));
    $hold(DnC, posedge SCLK &&& nRES, tah + (2*max_slew));

    // Chip Select timings relative to the clock
    $setup(nCS, posedge SCLK &&& nRES, tcss + (2*max_slew));
    $hold(nCS, posedge SCLK &&& nRES, tcsh + (2*max_slew));

    // Serial Data timings relative to the clock
    $setup(SDIN, posedge SCLK &&& nRES, tdsw + (2*max_slew));
    $hold(SDIN, posedge SCLK &&& nRES, tdhw + (2*max_slew));

  endspecify
  
endmodule

