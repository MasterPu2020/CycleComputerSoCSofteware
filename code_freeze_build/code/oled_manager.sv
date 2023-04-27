
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
// [0] C000_0000: 1bit | Mode        : 0 for Auto, 1 for Normal.
// [1] C000_0004: 1bit | Normal Mode : 0 for Command 1 for Data.
// [2] C000_0008: 1bit | Normal Mode : 0 for send data.
// [3] C000_000C: 8bit | Normal Mode : 8 bit data.
// [4] C000_0010: 1bit | Screen Mode: 0: Day   1: Night
// [5 + n]        4bit | Pixel Block : 0 ~ n. Write Only
//------------------------------------------------------------------------------

localparam 
  BlockAmoutWidth    = 4,
  BlockAmout         = 19,  // Max: 2**(BlockAmoutWidth + 1) - 1
  ResourceAmoutWidth = 4,
  ResourceAmout      = 30,  // Max: 2**(ResourceAmoutWidth + 1) - 1
  PictureHeight      = 13,
  PictureWidth       = 8,
  ResourceWidth      = PictureHeight * PictureWidth - 1; // 104 bit

logic mode;
logic dnc;
logic ready;
logic [7:0] normal_data;
logic screen_mode;
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
logic last_screen_mode;

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
  // Sending -> {ColourBlue0, ColourBlue1} = {Red, Green, Blue}
  ColourBlue0  = 8'h06,
  ColourBlue1  = 8'h3C,
  ColourWhite0 = 8'hFF,
  ColourWhite1 = 8'hFF;

// Locations 16 bit: Same address of RAM. 16 bit {Y,X}
wire [15:0] location_rom [BlockAmout:0];
assign location_rom[ 0] = 16'h1F0E;
assign location_rom[ 1] = 16'h1F16;
assign location_rom[ 2] = 16'h1F2A;
assign location_rom[ 3] = 16'h2C35;
assign location_rom[ 4] = 16'h1F35;
assign location_rom[ 5] = 16'h2C45;
assign location_rom[ 6] = 16'h1F45;
assign location_rom[ 7] = 16'h2C50;
assign location_rom[ 8] = 16'h1F50;
assign location_rom[ 9] = 16'h1F5E;
assign location_rom[10] = 16'h1F66;
assign location_rom[11] = 16'h1F6E;
assign location_rom[12] = 16'h1F3D;
assign location_rom[13] = 16'h3E0E;
assign location_rom[14] = 16'h3E16;
assign location_rom[15] = 16'h3E2A;
assign location_rom[16] = 16'h3E35;
assign location_rom[17] = 16'h3E45;
assign location_rom[18] = 16'h3E50;
assign location_rom[19] = 16'h3E3D;

// Pictures 8x13 bit: begin from 0 bit, end at 104 bit
wire [ResourceWidth:0] resource_rom [ResourceAmout:0];
assign resource_rom[ 0] = 104'h7EFFC3C3C3C3C3C3C3C3C3FF7E; // File Name: 0.png
assign resource_rom[ 1] = 104'hFF7E18181818181818181B1E1C; // File Name: 1.png
assign resource_rom[ 2] = 104'h7EFFFF0303037FFEC0C0C0FF7E; // File Name: 2.png
assign resource_rom[ 3] = 104'h7EFFFFC0C0C0FFFFC0C0C0FF7F; // File Name: 3.png
assign resource_rom[ 4] = 104'h40C0C0C0C0FEFFFFC3C3C3C3C3; // File Name: 4.png
assign resource_rom[ 5] = 104'h7EFFFFC0C0C0FFFF030303FF7F; // File Name: 5.png
assign resource_rom[ 6] = 104'h7EFFFFC3C3C3FFFF030303FF7F; // File Name: 6.png
assign resource_rom[ 7] = 104'h40C0C0C0C0C0C0C0C0C0C0FFFE; // File Name: 7.png
assign resource_rom[ 8] = 104'h7EFFC3C3C3C3FFFFC3C3C3FF7E; // File Name: 8.png
assign resource_rom[ 9] = 104'h7EFFFFC0C0C0FEFFC3C3C3FF7E; // File Name: 9.png
assign resource_rom[10] = 104'h3C665A5A663CE09C3C00000000; // File Name: candence1.png
assign resource_rom[11] = 104'h3C665A5A663C1C090F0E041F1F; // File Name: candence2.png
assign resource_rom[12] = 104'h00000018180000001818000000; // File Name: colon.png
assign resource_rom[13] = 104'h00000606000006060000000000; // File Name: colonfortime.png
assign resource_rom[14] = 104'h8282868606060C8C8C98181890; // File Name: distance1.png
assign resource_rom[15] = 104'h41416161606030313119181809; // File Name: distance2.png
assign resource_rom[16] = 104'h00181800000000000000000000; // File Name: dot.png
assign resource_rom[17] = 104'h00000000000000000000000000; // File Name: empty.png
assign resource_rom[18] = 104'h000013131313131F0303030000; // File Name: h.png
assign resource_rom[19] = 104'h0000330B0F0B33030303020000; // File Name: k.png
assign resource_rom[20] = 104'h00002B2B2B2B3F1F0000000000; // File Name: m.png
assign resource_rom[21] = 104'h00000606060E1E360000000000; // File Name: rpm1.png
assign resource_rom[22] = 104'h0303838F9F93938F0000000000; // File Name: rpm2.png
assign resource_rom[23] = 104'h00000F101F031E000000000000; // File Name: s.png
assign resource_rom[24] = 104'hE0F0180C86C66666C68C18F0E0; // File Name: setting1.png
assign resource_rom[25] = 104'h070F1830616366666331180F07; // File Name: setting2.png
assign resource_rom[26] = 104'h78C888183060407C183060C080; // File Name: speed1.png
assign resource_rom[27] = 104'h00000103060C183E060C18103F; // File Name: speed2.png
assign resource_rom[28] = 104'hE0F0180C06868686868C18F0E0; // File Name: timer1.png
assign resource_rom[29] = 104'h070F1830606767606030180F07; // File Name: timer2.png
assign resource_rom[30] = 104'h000000000000000000FFFF0000; // File Name: underline.png

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
    screen_mode <= 0;
    last_screen_mode <= 0;
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
              // If screen mode is been updated
              // Else if an OLED block (a resource picture) is out of date, update the block according to the privilege.
              if (screen_mode != last_screen_mode) begin
                last_screen_mode <= screen_mode;
                if (screen_mode == 0)
                  data <= 8'hA6;
                else
                  data <= 8'hA7;
                dnc <= 0;
                state <= ChangeData;
              end
              else if (block_ram[search_ram_addr] != oled_block_ram[search_ram_addr]) begin
                  auto_control <= Start;
                  block_ram_addr <= search_ram_addr;
                  resource_rom_addr <= block_ram[search_ram_addr];
                  pixel_pointer <= 0;
                  search_ram_addr <= 0;
              end
              else if (search_ram_addr == BlockAmout) // if it's the last block
                search_ram_addr <= 0;
              else
                search_ram_addr <= search_ram_addr + 1;
            end
          endcase
          if (auto_control != Finished) begin
            state <= ChangeData;
            // One cycle delayed, so it needs combinational logic provide an one-cycle-ahead value
            data <= auto_data;
            dnc <= auto_dnc;
          end
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
      else if (ahb_addr == 4)
        screen_mode <= HWDATA;
      else
        block_ram[ahb_addr - 5] <= HWDATA;
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
  else if (ahb_addr == 4 && !ahb_write)
    HRDATA = {31'b0, screen_mode};
end

endmodule

