
//------------------------------------------------------------------------------
// Titile:  OLED Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 3.0
// Verification: 
// Comment: 1 package for 16 pixels
// Colour Define:
  `define BLACK  16'b00000_000000_00000 // 0
  `define WHITE  16'b11111_111111_11111 // 1
  `define RED    16'b11111_000000_00000 // 2
  `define GREEN  16'b00000_111111_00000 // 3
  `define BLUE   16'b00000_000000_11111 // 4
  `define EMPTY1 16'b00000_000000_00000 // 5
  `define EMPTY2 16'b00000_000000_00000 // 6
  `define EMPTY3 16'b00000_000000_00000 // 7
//------------------------------------------------------------------------------

module oled_manager(

  // Clock and Reset
  input  HCLK,
  input  HRESETn,

  // Hardware Software Interface
  input  HSEL,
  input  HREADY,
  input  HWRITE,
  input  [31:0] HADDR, // HADDR[3:2] used
  input  [31:0] HWDATA,
  input  [ 2:0] HSIZE, // 1 word only
  input  [ 1:0] HTRANS,
  output logic [31:0] HRDATA,
  output logic HREADYOUT,

  // Physical Interface
  output  wire nCS,
  output logic DnC,
  output logic SDIN,
  output  wire SCLK

);

timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map:
// C000_0000: 32bit | 16bit Horizontal location X, 16bit Vertical location Y
// C000_0004: 32bit | Encoded Colour1
// C000_0008: 32bit | Encoded Colour2
// C000_000C: 32bit | Ready flag
//------------------------------------------------------------------------------

logic ready;
logic [15:0] x, y;
logic [31:0] colour [1:0]; // Special smaller no reset D-type will be used, if exists.

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [2:0] {Idle, ReadReady, WriteReady, WritePosition, WriteColour1, WriteColour2} control;
enum logic [4:0] {CmdX, X, CmdY, Y, CmdC,
                  C00, C01, C02, C03, 
                  C10, C11, C12, C13, 
                  C20, C21, C22, C23, 
                  C30, C31, C32, C33 } launch_state;
logic [3:0] counter;
logic launch;
logic new_position;
// None Register
logic [ 3:0] selected_colour;
logic [15:0] decode_colour;
logic [15:0] data;
// Parameters
localparam
  CmdSetCol = 8'b0001_0101,
  CmdSetRow = 8'b0111_0101,
  CmdColour = 8'b0101_1100,
  NoTransfer = 2'b00; // AHB disabled

//------------------------------------------------------------------------------
// AHB Control signal generation
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    control <= Idle;
  end
  else begin
    if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 3) &&  HWRITE)
      control <= WriteReady;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 0) && HWRITE) 
      control <= WritePosition;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) && HWRITE) 
      control <= WriteColour1;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 2) && HWRITE) 
      control <= WriteColour2;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 3) && !HWRITE)
      control <= ReadReady;
    else
      control <= Idle;
  end
end

//------------------------------------------------------------------------------
// OLED SCLK & nCS output
//------------------------------------------------------------------------------

assign nCS = 0;
assign SCLK = launch?HCLK:0;
// Falling Edge Triggered Signal : Synthesis Process Must Pay Attention to This Part !!!
// This block is like 'assign nHCLK = ~ HCLK, then @(posedge nHCLK)', basicly create 2 different clock.
always_ff @(negedge HCLK, negedge HRESETn) begin
  if (!HRESETn)
    launch <= '0;
  else
    if (!ready)
      launch <= '1;
    else
      launch <= '0;
end

//------------------------------------------------------------------------------
// One Cycle Delayed AHB Controled OLED Serial Output DnC & SDIN
//------------------------------------------------------------------------------

always_comb begin
  // Decode colour
  decode_colour = `BLACK;
  selected_colour = 0;
  case (launch_state)
    C00: selected_colour = colour[0][ 3: 0]; C01: selected_colour = colour[0][ 7: 4]; C02: selected_colour = colour[0][11: 8]; C03: selected_colour = colour[0][15:12];
    C10: selected_colour = colour[0][19:16]; C11: selected_colour = colour[0][23:20]; C12: selected_colour = colour[0][27:24]; C13: selected_colour = colour[0][31:28];
    C20: selected_colour = colour[1][ 3: 0]; C21: selected_colour = colour[1][ 7: 4]; C22: selected_colour = colour[1][11: 8]; C23: selected_colour = colour[1][15:12];
    C30: selected_colour = colour[1][19:16]; C31: selected_colour = colour[1][23:20]; C32: selected_colour = colour[1][27:24]; C33: selected_colour = colour[1][31:28];
  endcase
  case (selected_colour)
    0: decode_colour = `BLACK;
    1: decode_colour = `WHITE;
    2: decode_colour = `RED;
    3: decode_colour = `GREEN;
    4: decode_colour = `BLUE;
    5: decode_colour = `EMPTY1;
    6: decode_colour = `EMPTY2;
    7: decode_colour = `EMPTY3;
  endcase
  // Decode data
  data = decode_colour;
  case (launch_state)
    CmdX : data = {16'b0, CmdSetCol};
       X : data = x;
    CmdY : data = {16'b0, CmdSetRow};
       Y : data = y;
    CmdC : data = {16'b0, CmdColour};
  endcase
end

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    x <= '0;
    y <= '0;
    ready <= '1;
    DnC <= '0;
    SDIN <= '0;
    counter <= 15;
    new_position <= '0;
    launch_state <= C00;
  end
  else begin
    //--------------------------------------------------------------------------
    // OLED Serial Output DnC & SDIN
    //--------------------------------------------------------------------------
    if (!ready) begin
      SDIN <= data >> counter;
      counter <= counter - 1; // 0 - 1 = 15 then a new data cycle start
      if (counter == 0)       // The end of data cycle
        case (launch_state)
          CmdX: launch_state <= X;
             X: begin launch_state <= CmdY; counter <= 7; end
          CmdY: launch_state <= Y;
             Y: begin launch_state <= CmdC; counter <= 7; end
          CmdC: launch_state <= C00;
           C00: launch_state <= C01; C01: launch_state <=  C02;  C02: launch_state <= C03; C03: launch_state <= C10; 
           C10: launch_state <= C11; C11: launch_state <=  C12;  C12: launch_state <= C13; C13: launch_state <= C20; 
           C20: launch_state <= C21; C21: launch_state <=  C22;  C22: launch_state <= C23; C23: launch_state <= C30; 
           C30: launch_state <= C31; C31: launch_state <=  C32;  C32: launch_state <= C33; 
           C33: begin launch_state <= C00; ready <= 1; end // Quit "if(!ready)"
        endcase
      if (launch_state == CmdX || launch_state == CmdY || launch_state == CmdC)
        DnC <= 0;
      else
        DnC <= 1;
    end
    else begin
      if (new_position) begin // It will remember there will be a new position data even during launching time
        launch_state <= CmdX;
        new_position <= 0;
      end
      if (launch_state == CmdX)
        counter <= 7;
      else
        counter <= 15;
      DnC <= 0;
      SDIN <= 0;
    end
    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      WriteReady    : ready <= HWDATA[0];
      WritePosition : begin 
                        x <= HWDATA[31:16];
                        y <= HWDATA[15: 0];
                        new_position <= 1;
                      end
      WriteColour1  : colour[0] <= HWDATA;
      WriteColour2  : colour[1] <= HWDATA;
    endcase
  end
end

//------------------------------------------------------------------------------
// AHB Output
//------------------------------------------------------------------------------

always_comb begin
  HREADYOUT = '1;
  HRDATA = 32'b0;
  if (control == ReadReady)
    HRDATA = {31'b0, ready};
end

endmodule

