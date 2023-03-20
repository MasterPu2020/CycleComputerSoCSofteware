
//------------------------------------------------------------------------------
// Titile:  OLED Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 4.2
// Verification: Verified with testbench
// Comment: 1 package for 8 bit data.
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
  output logic nCS,
  output logic DnC,
  output logic SDIN,
  output logic SCLK

);

timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map:
// C000_0000: 32bit | Data(1) or Command(0) Select : DnC . Write Only
// C000_0004: 32bit | Ready flag. Read and Write
// C000_0008: 32bit | 8 bit data. Write Only
//------------------------------------------------------------------------------

logic ready;
logic dnc;
logic [7:0] data;

//------------------------------------------------------------------------------
// Control and Status registers
//------------------------------------------------------------------------------

enum logic [2:0] {Idle, ReadReady, WriteReady, WriteDnC, WriteData} control;
enum logic [1:0] {Wait, ChangeData, SendData} state;
logic [2:0] counter;
// Parameters
localparam NoTransfer = 2'b00;

//------------------------------------------------------------------------------
// AHB Control signal generation
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    control <= Idle;
  end
  else begin
    if      (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) &&  HWRITE)
      control <= WriteReady;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 0) &&  HWRITE) 
      control <= WriteDnC;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 2) &&  HWRITE) 
      control <= WriteData;
    else if (HREADY && HSEL && (HTRANS != NoTransfer) && (HADDR[3:2] == 1) && !HWRITE)
      control <= ReadReady;
    else
      control <= Idle;
  end
end

//------------------------------------------------------------------------------
// One Cycle Delayed AHB Controled OLED Output
//------------------------------------------------------------------------------

always_comb begin
  DnC  = dnc;
  nCS  = 1;
  SCLK = 0;
  SDIN = data[7];
  case (state)
    Wait       : begin nCS = 1; SCLK = 0; end
    ChangeData : begin nCS = 0; SCLK = 0; end
    SendData   : begin nCS = 0; SCLK = 1; end
  endcase
end

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    state <= Wait;
    ready <= 1;
    dnc   <= 0;
    data  <= 0;
    counter <= 0;
  end
  else begin
    //--------------------------------------------------------------------------
    // OLED Manager State Machine
    //--------------------------------------------------------------------------
    case (state)
      Wait: begin
        if (ready == 0) 
          state <= ChangeData;
      end
      ChangeData: begin
        state <= SendData;
      end
      SendData: begin
        if (counter == 7) begin
          counter <= 0;
          ready   <= 1;
          state   <= Wait;
        end
        else begin
          counter <= counter + 1;
          state   <= ChangeData;
        end
        data <= data << 1;
      end
    endcase
    //--------------------------------------------------------------------------
    // One Cycle Delayed AHB Control
    //--------------------------------------------------------------------------
    case (control)
      WriteReady : ready <= HWDATA[0];
      WriteDnC   : dnc   <= HWDATA[0];
      WriteData  : data  <= HWDATA[15:0];
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

