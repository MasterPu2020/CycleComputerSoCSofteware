
//------------------------------------------------------------------------------
// Title:         Seven Segment Manager Behavioural
// Author:        Paiyun Chen (Circle)
// Team:          C4 Chip Designed
// Version:       5.0
// Verification:  Done with stimulus files and testbenches.
// Comment:       Being able to display all four fundamental modes.
//                Added an extra Mode E to display the setting mode.
//                Cancelled blinking because it will cause extra timer requirements.
//------------------------------------------------------------------------------

module seven_segment(
  // AHB signals
  input wire HCLK,
  input wire HRESETn,

  input wire [31:0] HADDR,    // Only HADDR[3:2] is used (other bits are ignored)
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire HREADY,
  input wire HSEL,
  input wire [2:0] HSIZE,
  input wire [1:0] HTRANS,

  output wire [31:0] HRDATA,
  output HREADYOUT,

  output logic SegA,
  output logic SegB,
  output logic SegC,
  output logic SegD,
  output logic SegE,
  output logic SegF,
  output logic SegG,
  output logic DP,
  output logic [3:0] nDigit
);

  timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map: (Only showing the valid bits)
// A000_0000: 8bits  | Storing BCD code of the fraction part
// A000_0004: 12bits | Storing BCD code of the integer part
// A000_0008: 4bits  | Storing Mode Information
//------------------------------------------------------------------------------

  logic [ 7:0] Store_Frac;  // Address 0xA0000000 for fraction part
  logic [11:0] Store_Int;   // Address 0xA0000004 for integer part
  logic [ 3:0] Store_Mode;  // Address 0xA0000008 for mode selection

//------------------------------------------------------------------------------
// Control and Status Signals
//------------------------------------------------------------------------------

  // For read signals one clock delay
  logic [ 1:0] Addr_Reg;
  logic Write;

  // Seven segment display
  logic [ 1:0] Display_Counter;
  logic [ 3:0] Disp_Data;

  localparam 
    Store_Frac_Addr = 0,
    Store_Int_Addr  = 1,
    Store_Mode_Addr = 2,
    Stop_Transferring = 2'b0;

//------------------------------------------------------------------------------
// AHB Control Signal Generation
//------------------------------------------------------------------------------

  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      Write <= '0;
      Addr_Reg <= '0;
    end
    else if (HSEL && HREADY && (HTRANS != Stop_Transferring)) begin
      Write <= HWRITE;
      Addr_Reg <= HADDR[3:2];
    end
    else begin
      Write <= '0;
      Addr_Reg <= '0;
    end
  end

//------------------------------------------------------------------------------
// Seven Segment Display
//------------------------------------------------------------------------------

  // SevenSeg Display
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn)
      Display_Counter <= '0;
    else if (Display_Counter == 3)
      Display_Counter <= '0;
    else
      Display_Counter <= Display_Counter + 1;
  end

  always_comb begin
    nDigit = 4'b0;
    unique case (Display_Counter)
      0: nDigit = 4'b1110;
      1: nDigit = 4'b1101;
      2: nDigit = 4'b1011;
      3: nDigit = 4'b0111;
    endcase
  end

  // float point
  always_comb begin
    Disp_Data = '0; DP = '0;
    if (Store_Mode == 4'hd) begin
      unique case (Display_Counter)
        0:  begin Disp_Data = Store_Int[3:0];   DP = '1; end
        1:  begin Disp_Data = Store_Int[7:4];   DP = '0; end
        2:  begin Disp_Data = Store_Int[11:8];  DP = '0; end
        3:  begin Disp_Data = Store_Mode;       DP = '0; end
      endcase
    end
    else if (Store_Mode == 4'he) begin
      unique case (Display_Counter)
        0:  begin Disp_Data = Store_Int[3:0];   DP = '1; end
        1:  begin Disp_Data = Store_Int[7:4];   DP = '0; end
        2:  begin Disp_Data = Store_Int[11:8];  DP = '0; end
        3:  begin Disp_Data = 4'h2;             DP = '0; end
      endcase
    end
    else if (Store_Mode == 4'he) begin
      unique case (Display_Counter)
        0:  begin Disp_Data = Store_Int[ 3:0]; DP = '1; end
        1:  begin Disp_Data = Store_Int[ 7:4]; DP = '0; end
        2:  begin Disp_Data = Store_Int[11:8]; DP = '0; end
        3:  begin Disp_Data = 4'h2;            DP = '0; end
      endcase
    end
    else begin
      if (Store_Int[11:8] != '0)
        unique case (Display_Counter)
          0:  begin Disp_Data = Store_Int[ 3:0];  DP = '1; end
          1:  begin Disp_Data = Store_Int[ 7:4];  DP = '0; end
          2:  begin Disp_Data = Store_Int[11:8];  DP = '0; end
          3:  begin Disp_Data = Store_Mode;       DP = '0; end
        endcase
      else if (Store_Int[7:4] != '0)
        unique case (Display_Counter)
          0:  begin Disp_Data = Store_Frac[7:4];  DP = '0; end
          1:  begin Disp_Data = Store_Int[3:0];   DP = '1; end
          2:  begin Disp_Data = Store_Int[7:4];   DP = '0; end
          3:  begin Disp_Data = Store_Mode;       DP = '0; end
        endcase
      else
        unique case (Display_Counter)
          0:  begin Disp_Data = Store_Frac[3:0];  DP = '0; end
          1:  begin Disp_Data = Store_Frac[7:4];  DP = '0; end
          2:  begin Disp_Data = Store_Int[3:0];   DP = '1; end
          3:  begin Disp_Data = Store_Mode;       DP = '0; end
        endcase
    end
  end

  always_comb begin
    SegA = '0; SegB = '0; SegC = '0; SegD = '0; SegE = '0; SegF = '0; SegG = '0;
    case (Disp_Data)
      4'h0: begin SegA = '1; SegB = '1; SegC = '1; SegD = '1; SegE = '1; SegF = '1; SegG = '0; end
      4'h1: begin SegA = '0; SegB = '1; SegC = '1; SegD = '0; SegE = '0; SegF = '0; SegG = '0; end
      4'h2: begin SegA = '1; SegB = '1; SegC = '0; SegD = '1; SegE = '1; SegF = '0; SegG = '1; end
      4'h3: begin SegA = '1; SegB = '1; SegC = '1; SegD = '1; SegE = '0; SegF = '0; SegG = '1; end
      4'h4: begin SegA = '0; SegB = '1; SegC = '1; SegD = '0; SegE = '0; SegF = '1; SegG = '1; end
      4'h5: begin SegA = '1; SegB = '0; SegC = '1; SegD = '1; SegE = '0; SegF = '1; SegG = '1; end
      4'h6: begin SegA = '1; SegB = '0; SegC = '1; SegD = '1; SegE = '1; SegF = '1; SegG = '1; end
      4'h7: begin SegA = '1; SegB = '1; SegC = '1; SegD = '0; SegE = '0; SegF = '0; SegG = '0; end
      4'h8: begin SegA = '1; SegB = '1; SegC = '1; SegD = '1; SegE = '1; SegF = '1; SegG = '1; end
      4'h9: begin SegA = '1; SegB = '1; SegC = '1; SegD = '1; SegE = '0; SegF = '1; SegG = '1; end
      4'ha: begin SegA = '0; SegB = '1; SegC = '1; SegD = '1; SegE = '1; SegF = '0; SegG = '1; end
      4'hb: begin SegA = '0; SegB = '0; SegC = '0; SegD = '1; SegE = '1; SegF = '1; SegG = '1; end
      4'hc: begin SegA = '0; SegB = '0; SegC = '1; SegD = '1; SegE = '0; SegF = '0; SegG = '0; end
      4'hd: begin SegA = '0; SegB = '0; SegC = '0; SegD = '1; SegE = '1; SegF = '0; SegG = '1; end
    endcase
  end

//------------------------------------------------------------------------------
// AHB Input
//------------------------------------------------------------------------------

  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      Store_Frac <= '0;
      Store_Int <= '0;
      Store_Mode <= '0;
    end
    else if (Write) begin
      case (Addr_Reg)
        Store_Frac_Addr: Store_Frac <= HWDATA[7:0];
        Store_Int_Addr: Store_Int <= HWDATA[11:0];
        Store_Mode_Addr: Store_Mode <= HWDATA[3:0];
      endcase
    end
  end

//------------------------------------------------------------------------------
// AHB Output
//------------------------------------------------------------------------------

  assign HRDATA = '0;
  assign HREADYOUT = '1; 

endmodule