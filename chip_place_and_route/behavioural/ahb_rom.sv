// Example code for an M0 AHBLite System
//  Iain McNally
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing a ROM
//
// Number of addressable locations : 2**MEMWIDTH
// Size of each addressable location : 8 bits
// Supported transfer sizes : Word, Halfword, Byte
// Alignment of base address : Word aligned

module ahb_rom #(
  parameter MEMWIDTH = 14
)(
  //AHBLITE INTERFACE

    //Slave Select Signal
    input HSEL,
    //Global Signals
    input HCLK,
    input HRESETn,
    //Address, Control & Write Data
    input HREADY,
    input [31:0] HADDR,
    input [1:0] HTRANS,
    input HWRITE,
    input [2:0] HSIZE,
    input [31:0] HWDATA,
    // Transfer Response & Read Data
    output HREADYOUT,
    output [31:0] HRDATA

);

timeunit 1ns;
timeprecision 100ps;

  localparam No_Transfer = 2'b0;

//control signals are stored in registers
  logic read_enable;
  logic [MEMWIDTH-2:0] word_address;
 
//Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if (! HRESETn )
      begin
        read_enable <= '0;
        word_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        read_enable <= ! HWRITE;
        word_address <= HADDR[MEMWIDTH:2];
     end
    else
      begin
        read_enable <= '0;
        word_address <= '0;
     end

//Act on control signals in the data phase

  // no write since this is a ROM

  // read
  dirom512x32 dirom512x32_1(
    .NRST(HRESETn),
    .CS(HCLK),
    .EN(),
    .AD(),
    .DO()
  );

  dirom512x32 dirom512x32_2(
    .NRST(HRESETn),
    .CS(),
    .EN(),
    .AD(),
    .DO()
  );

  dirom512x32 dirom512x32_3(
    .NRST(HRESETn),
    .CS(),
    .EN(),
    .AD(),
    .DO()
  );

  dirom512x32 dirom512x32_4(
    .NRST(HRESETn),
    .CS(),
    .EN(),
    .AD(),
    .DO()
  );

//Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations


endmodule
