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
//

`define STRINGIFY(x) `"x`"

`ifdef prog_file_vmem
  // already defined - do nothing
`else
  `define prog_file_vmem  code.vmem
`endif

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

// Memory Array  
  logic [31:0] memory[0:(2**(MEMWIDTH-2)-1)];

//control signals are stored in registers
  logic read_enable;
  logic [MEMWIDTH-2:0] word_address;
  logic [3:0] byte_select;
  

// BEGIN CUSTOM
// include program instructions from file
`include `STRINGIFY(`prog_file_vmem)
// END CUSTOM
 
//Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if (! HRESETn )
      begin
        read_enable <= '0;
        word_address <= '0;
        byte_select <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        read_enable <= ! HWRITE;
        word_address <= HADDR[MEMWIDTH:2];
        byte_select <= generate_byte_select( HSIZE, HADDR[1:0] );
     end
    else
      begin
        read_enable <= '0;
        word_address <= '0;
        byte_select <= '0;
     end

//Act on control signals in the data phase

  // no write since this is a ROM

  //read
  // (output of zero when not enabled for read is not necessary but may help with debugging)
  assign HRDATA[ 7: 0] = ( read_enable && byte_select[0] ) ? memory[word_address][ 7: 0] : '0;
  assign HRDATA[15: 8] = ( read_enable && byte_select[1] ) ? memory[word_address][15: 8] : '0;
  assign HRDATA[23:16] = ( read_enable && byte_select[2] ) ? memory[word_address][23:16] : '0;
  assign HRDATA[31:24] = ( read_enable && byte_select[3] ) ? memory[word_address][31:24] : '0;

//Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations


// decode byte select signals from the size and the lowest two address bits
  function logic [3:0] generate_byte_select( logic [2:0] size, logic [1:0] byte_adress );
    logic byte3, byte2, byte1, byte0;
    byte0 = size[1] || ( byte_adress == 0 );
    byte1 = size[1] || ( size[0] && ( byte_adress == 0 ) ) || ( byte_adress == 1 );
    byte2 = size[1] || ( byte_adress == 2 );
    byte3 = size[1] || ( size[0] && ( byte_adress == 2 ) ) || ( byte_adress == 3 );
    return { byte3, byte2, byte1, byte0 };
  endfunction

endmodule
