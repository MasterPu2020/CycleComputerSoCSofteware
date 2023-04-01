
//------------------------------------------------------------------------------
// Titile:  OLED Manager Behavioural
// Author:  Clark Pu
// Team:    C4 Chip Designed
// Version: 5.2
// Verification: Verified by Clark
// Comment: Super large and smart manager for super slow clock
//------------------------------------------------------------------------------

module oled_manager(

  // Clock and Reset
  input  HCLK,
  input  HRESETn,

  // Hardware Software Interface
  input  HSEL,
  input  HREADY,
  input  HWRITE,
  input  [31:0] HADDR,
  input  [31:0] HWDATA,
  input  [ 2:0] HSIZE, // 1 word only
  input  [ 1:0] HTRANS,
  output logic [31:0] HRDATA,
  output logic HREADYOUT,

  // Physical Interface
  output logic nCS,  // combinational
  output logic DnC,  // combinational
  output logic SDIN, // combinational
  output logic SCLK  // combinational

);

timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map:
// C[0]:     | Mode       : 0: Auto, 1: Normal
// C[1]:     | Normal Mode: 2 bit D/C: 1/0 2: self update
// C[2]:     | Normal Mode: 1 bit Ready flag.
// C[3]:     | Normal Mode: 8 bit data.
// C[3 + n]: | Pixel Block: 0 ~ n. Write Only
//------------------------------------------------------------------------------

localparam 
  BlockAmoutWidth    = 4,
  BlockAmout         = 2**(BlockAmoutWidth + 1) - 1,     // 32 bit
  ResourceAmoutWidth = 4,
  ResourceAmout      = 2**(ResourceAmoutWidth + 1) - 1,  // 32 bit
  PictureHeight      = 13,
  PictureWidth       = 8,
  ResourceWidth      = PictureHeight * PictureWidth - 1; // 104 bit

logic mode;
logic dnc;
logic ready;
logic [7:0] normal_data;
logic [ResourceAmoutWidth:0] block_ram [BlockAmout:0];

//------------------------------------------------------------------------------
// Process Registers
//------------------------------------------------------------------------------

// AHB Control registers
localparam 
  NoTransfer = 2'b00,
  MemoryWidth = BlockAmoutWidth + 1;
logic ahb_write;
logic [MemoryWidth:0] ahb_addr;

// SDI Sending registers
enum logic [1:0] {Wait, ChangeData, SendData} state;
logic [7:0] data;
logic [2:0] counter;

// pixel block image on OLED
logic [ResourceAmoutWidth:0] oled_block_ram [BlockAmout:0];

// Auto sending address finding
logic [ResourceAmoutWidth:0] resource_rom_addr;
logic [BlockAmoutWidth:0] search_ram_addr;
logic [BlockAmoutWidth:0] block_ram_addr;
logic [6:0] pixel_pointer; // width is log2 of ResourceWidth : this is data bit-address

// Auto sending control
enum logic [3:0] {Start, Finished, PixelCMD, XCMD, YCMD, Pixel0, Pixel1, xStart, yStart, xEnd, yEnd} auto_control;
logic [7:0] auto_data; // combinational
logic auto_dnc;        // combinational

//------------------------------------------------------------------------------
// Local Read Only Memory
//------------------------------------------------------------------------------

// Command 8 bit
localparam
  SetX = 8'h15, // Column
  SetY = 8'h75, // Row
  SetPixel = 8'h5C;

// Colours 16 bit
localparam
  ColourBlue0  = 8'h06,
  ColourBlue1  = 8'h3C,
  ColourWhite0 = 8'hFF,
  ColourWhite1 = 8'hFF;

// Locations 16 bit: Same address of RAM
wire [15:0] location_rom [BlockAmout:0];
assign location_rom[ 0] = 16'h0000;
assign location_rom[ 1] = 16'h0000;
assign location_rom[ 2] = 16'h0000;
assign location_rom[ 3] = 16'h0000;
assign location_rom[ 4] = 16'h0000;
assign location_rom[ 5] = 16'h0000;
assign location_rom[ 6] = 16'h0000;
assign location_rom[ 7] = 16'h0000;
assign location_rom[ 8] = 16'h0000;
assign location_rom[ 9] = 16'h0000;
assign location_rom[10] = 16'h0000;
assign location_rom[11] = 16'h0000;
assign location_rom[12] = 16'h0000;
assign location_rom[13] = 16'h0000;
assign location_rom[14] = 16'h0000;
assign location_rom[15] = 16'h0000;
assign location_rom[16] = 16'h0000;
assign location_rom[17] = 16'h0000;
assign location_rom[18] = 16'h0000;
assign location_rom[19] = 16'h0000;
assign location_rom[20] = 16'h0000;
assign location_rom[21] = 16'h0000;
assign location_rom[22] = 16'h0000;
assign location_rom[23] = 16'h0000;
assign location_rom[24] = 16'h0000;
assign location_rom[25] = 16'h0000;
assign location_rom[26] = 16'h0000;
assign location_rom[27] = 16'h0000;
assign location_rom[28] = 16'h0000;
assign location_rom[29] = 16'h0000;
assign location_rom[30] = 16'h0000;
assign location_rom[31] = 16'h0000;

// Pictures 8x13 bit: begin with 0 bit, end with 104 bit
wire [ResourceWidth:0] resource_rom [ResourceAmout:0];
assign resource_rom[0] = 104'hff;
assign resource_rom[1] = 104'hff;
assign resource_rom[2] = 104'hff;
assign resource_rom[3] = 104'hff;
assign resource_rom[4] = 104'hff;
assign resource_rom[5] = 104'hff;
assign resource_rom[6] = 104'hff;
assign resource_rom[7] = 104'hff;
assign resource_rom[8] = 104'hff;
assign resource_rom[9] = 104'hff;

//------------------------------------------------------------------------------
// AHB Signal
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    ahb_addr <= 0;
    ahb_write <= 0;
  end
  else
    if (HREADY && HSEL && (HTRANS != NoTransfer)) begin
      ahb_addr <= HADDR[MemoryWidth + 2 : 2];
      ahb_write <= HWRITE;
    end
    else begin
      ahb_addr <= 0;
      ahb_write <= 0;
    end
end

//------------------------------------------------------------------------------
// Auto Mode 8 bit data
//------------------------------------------------------------------------------

always_comb begin
  auto_data = 0;
  auto_dnc = 1;
  case (auto_control) // "One-cycle-ahead" value
    Start    : begin auto_dnc = 0; auto_data = SetX; end
    XCMD     : auto_data = location_rom[block_ram_addr][ 7:0];
    xStart   : auto_data = location_rom[block_ram_addr][ 7:0] + (PictureWidth - 1);
    xEnd     : begin auto_dnc = 0; auto_data = SetY; end
    YCMD     : auto_data = location_rom[block_ram_addr][15:8];
    yStart   : auto_data = location_rom[block_ram_addr][15:8] + (PictureHeight - 1);
    yEnd     : begin auto_dnc = 0; auto_data = SetPixel; end
    PixelCMD : auto_data = resource_rom[resource_rom_addr][pixel_pointer]?ColourBlue0:ColourWhite0;
    Pixel0   : auto_data = resource_rom[resource_rom_addr][pixel_pointer]?ColourBlue1:ColourWhite1;
    Pixel1   : auto_data = resource_rom[resource_rom_addr][pixel_pointer]?ColourBlue0:ColourWhite0;
  endcase
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
    // Mode Control
    mode <= 0;
    normal_data <= 0;
    // SDI Data
    state <= Wait;
    ready <= 1;
    dnc   <= 0;
    data  <= 0;
    counter <= 0;
    // Block Update
    search_ram_addr <= 0;
    block_ram_addr <= 0;
    resource_rom_addr <= 0;
    pixel_pointer <= 0;
    auto_control <= Finished;
    // Block Registers
    for (int addr = 0; addr < BlockAmout + 1; addr ++) begin
      block_ram[addr] <= 0;
      oled_block_ram[addr] <= 0;
    end
  end
  else begin
    //--------------------------------------------------------------------------
    // OLED SDI Data Sending State Machine
    //--------------------------------------------------------------------------
    case (state)
      Wait: begin
        if (mode) begin // normal mode
          data <= normal_data;
          search_ram_addr <= 0;
          if (ready == 0) 
            state <= ChangeData;
        end
        else begin // auto mode
          //--------------------------------------------------------------------------
          // Auto Control State Machine
          //--------------------------------------------------------------------------
          case (auto_control)
            Start    : auto_control <= XCMD;
            XCMD     : auto_control <= xStart;
            xStart   : auto_control <= xEnd;
            xEnd     : auto_control <= YCMD;
            YCMD     : auto_control <= yStart;
            yStart   : auto_control <= yEnd;
            yEnd     : auto_control <= PixelCMD;
            PixelCMD : auto_control <= Pixel0;
            Pixel0   : begin
              if (pixel_pointer == ResourceWidth) begin
                oled_block_ram[block_ram_addr] <= resource_rom_addr;
                auto_control <= Finished;
                search_ram_addr <= 0;
              end
              else begin
                auto_control <= Pixel1;
                pixel_pointer <= pixel_pointer + 1;
              end
            end
            Pixel1   : auto_control <= Pixel0;
            Finished : begin
              // If an OLED block (a resource picture) is out of date, update the block according to the privilege.
              if (block_ram[search_ram_addr] != oled_block_ram[search_ram_addr]) begin
                  auto_control <= Start;
                  block_ram_addr <= search_ram_addr;
                  resource_rom_addr <= block_ram[search_ram_addr];
                  pixel_pointer <= 0;
                  search_ram_addr <= 0;
              end
              else
                search_ram_addr <= search_ram_addr + 1;
            end
          endcase
          // One cycle delayed, so it needs combinational logic provide an one-cycle-ahead value
          data <= auto_data;
          dnc <= auto_dnc;
          if (auto_control != Finished)
            state <= ChangeData;
          //--------------------------------------------------------------------------
          // Auto Control State Machine End
          //--------------------------------------------------------------------------
        end
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
    // One Cycle Delayed AHB Write
    //--------------------------------------------------------------------------
    if (ahb_write) begin
      if (ahb_addr == 0)
        mode  <= HWDATA;
      else if (ahb_addr == 1)
        dnc   <= HWDATA;
      else if (ahb_addr == 2)
        ready <= HWDATA;
      else if (ahb_addr == 3)
        normal_data <= HWDATA;
      else
        block_ram[ahb_addr - 4] <= HWDATA;
    end
  end
end

//------------------------------------------------------------------------------
// AHB Output
//------------------------------------------------------------------------------

always_comb begin
  HREADYOUT = '1;
  HRDATA = 32'b0;
  if (ahb_addr == 2 && !ahb_write)
    HRDATA = {31'b0, ready};
end

endmodule

