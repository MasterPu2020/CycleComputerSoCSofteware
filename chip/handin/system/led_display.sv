///////////////////////////////////////////////////////////////////////
//
// LED display module
//
//    this version of the module is empty
//
//    a more advanced version might attempt to decode the inputs
//    to produce a value representing the number on the display
//
//    this module might also be the location of assert statements
//    to help with debugging
//
// The arrangement of the digits and segments of the L.E.D. display is
// shown below. Each digit has seven segments marked A-G and a decimal point
// to the right marked DP. The most significant digit is Digit 3.
//
//        Digit 3         Digit 2         Digit 1         Digit 0
//
//         --A--           --A--           --A--           --A--
//        |     |         |     |         |     |         |     |
//        F     B         F     B         F     B         F     B  
//        |     |         |     |         |     |         |     |
//         --G--           --G--           --G--           --G--
//        |     |         |     |         |     |         |     |
//        E     C         E     C         E     C         E     C
//        |     |         |     |         |     |         |     |
//         --D--   *DP     --D--   *DP     --D--   *DP     --D--   *DP
//
// The display is a common cathode multiplexed display. Thus a segment is
// lit if and only if the relevant "SegX" line is taken high and the
// relevant "nDigit" line is taken low.
//
///////////////////////////////////////////////////////////////////////

`include "options.sv"

`ifdef led_num_digits
  // already defined - do nothing
`else
  // default specification has 4 digits for the LED display
  `define led_num_digits 4
`endif

module led_display (
  input SegA,
  input SegB,
  input SegC,
  input SegD,
  input SegE,
  input SegF,
  input SegG,
  input DP,

  input [`led_num_digits - 1:0] nDigit

  );

timeunit 1ns;
timeprecision 100ps;

  wire [7:0] Digit; // this intentionally has more bits than nDigit  

  assign Digit = ~nDigit;

  // impose a minimum width for active Digit
  //
  // initially set at 30us
  // (this will not be an issue with default clock 32.768kHz)
  specify
    specparam twidth=30us;
    $width(posedge Digit[0], twidth);
    $width(posedge Digit[1], twidth);
    $width(posedge Digit[2], twidth);
    $width(posedge Digit[3], twidth);
    $width(posedge Digit[4], twidth);
    $width(posedge Digit[5], twidth);
    $width(posedge Digit[6], twidth);
    $width(posedge Digit[7], twidth);
  endspecify

endmodule

