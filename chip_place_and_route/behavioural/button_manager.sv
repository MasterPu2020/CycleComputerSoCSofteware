
//------------------------------------------------------------------------------
// Title:         Button Manager Behavioural
// Author:        Paiyun Chen (Circle)
// Team:          C4 Chip Designed
// Version:       5.0
// Verification:  Not Done
// Comment:       Still need lots of optimization to decrease the hardware costs.
//------------------------------------------------------------------------------

module button_manager(
    
  // AHB signals
  input wire HCLK,
  input wire HRESETn,

  input wire [31:0] HADDR,    // Only HADDR [4:2] is used (other bits are ignored)
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire HREADY,
  input wire HSEL,
  input wire [2:0] HSIZE,     // Always choose one word
  input wire [1:0] HTRANS,    // AHB always works

  // input from outworld
  input wire Mode,
  input wire Trip,

  output logic [31:0] HRDATA,
  output logic HREADYOUT
);

  timeunit 1ns; timeprecision 100ps;

//------------------------------------------------------------------------------
// Memory Map: (Only showing the valid bits)
// 4000_0000: 1bit  | DayNight Switch Flag
// 4000_0004: 1bit  | Mode Switch Flag
// 4000_0008: 1bit  | Trip Clear Flag
// 4000_000C: 1bit  | Wheel Setting Flag
// 4000_0010: 1bit  | New button pressed Flag
//------------------------------------------------------------------------------
  
  logic DayNight_Store, Mode_Store, Trip_Store, Setting_Store;
  wire  NewData;

//------------------------------------------------------------------------------
// Control and Status Signals
//------------------------------------------------------------------------------


  // Input Synchronization
  logic SYNC_MID_nMode, SYNC_nMode;
  logic SYNC_MID_nTrip, SYNC_nTrip;


  // Button debounce
  logic Trip_Last, Mode_Last;
  logic [ 9:0] DebCount_Trip, DebCount_Mode;
  logic [14:0] InterCount_Trip, InterCount_Mode;
  logic DebFlag_Trip, DebFlag_Mode;
  wire  Con_DayNight, Con_Trip, Con_Mode, Con_Setting;
  enum logic {STATE_IDLE_DEBTRIP, STATE_COUNT_DEBTRIP} state_debtrip;
  enum logic {STATE_IDLE_DEBMODE, STATE_COUNT_DEBMODE} state_debmode;
  enum logic {STATE_IDLE_INTERTRIP, STATE_COUNT_INTERTRIP} state_intertrip;
  enum logic {STATE_IDLE_INTERMODE, STATE_COUNT_INTERMODE} state_intermode;

  logic [ 2:0] Addr_Reg;
  logic Write;

  localparam
    Time_25MS = 900,
    Time_500MS = 16000,
    NewData_Reg_Addr = 4,
    Setting_Reg_Addr = 3,
    Trip_Reg_Addr = 2,
    Mode_Reg_Addr = 1,
    DayNight_Reg_Addr = 0,
    Stop_Transferring = 2'b0;

//------------------------------------------------------------------------------
// Input Synchronization : nMode, nTrip
//------------------------------------------------------------------------------

always_ff @(posedge HCLK, negedge HRESETn) begin
  if (!HRESETn) begin
    SYNC_MID_nMode <= '0;  SYNC_nMode <= '0;
    SYNC_MID_nTrip <= '0;  SYNC_nTrip <= '0;
  end
  else begin
    SYNC_nMode <= SYNC_MID_nMode; SYNC_MID_nMode <= Mode;
    SYNC_nTrip <= SYNC_MID_nTrip; SYNC_MID_nTrip <= Trip;
  end
end

//------------------------------------------------------------------------------
// Button Debounce
//------------------------------------------------------------------------------

  // For the Trip Mode negative edge detection
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      Trip_Last <= '0;
      Mode_Last <= '0;
    end
    else begin
      Trip_Last <= SYNC_nTrip;
      Mode_Last <= SYNC_nMode;
    end
  end

  // Trip button debounce
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_debtrip <= STATE_IDLE_DEBTRIP;
      DebCount_Trip <= '0;
    end
    else
      unique case (state_debtrip)
        STATE_IDLE_DEBTRIP: begin
          if (!SYNC_nTrip && Trip_Last) begin
            state_debtrip <= STATE_COUNT_DEBTRIP;
            DebCount_Trip <= DebCount_Trip + 1;
          end
        end
        STATE_COUNT_DEBTRIP: begin
          if ((DebCount_Trip == Time_25MS) || (SYNC_nTrip)) begin
            state_debtrip <= STATE_IDLE_DEBTRIP;
            DebCount_Trip <= '0;
          end
          else
            DebCount_Trip <= DebCount_Trip + 1;
        end
      endcase
  end

  always_comb begin
    if (DebCount_Trip == Time_25MS)
      DebFlag_Trip = '1;
    else
      DebFlag_Trip = '0;
  end

  // Mode button debounce
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_debmode <= STATE_IDLE_DEBMODE;
      DebCount_Mode <= '0;
    end
      else
        unique case (state_debmode)
          STATE_IDLE_DEBMODE: begin
            if (!SYNC_nMode && Mode_Last) begin
              state_debmode <= STATE_COUNT_DEBMODE;
              DebCount_Mode <= DebCount_Mode + 1;
            end
          end
          STATE_COUNT_DEBMODE: begin
            if ((DebCount_Mode == Time_25MS) || (SYNC_nMode)) begin
              DebCount_Mode <= '0;
              state_debmode <= STATE_IDLE_DEBMODE;
            end
            else
              DebCount_Mode <= DebCount_Mode + 1;
          end
        endcase
  end

  always_comb
  begin
    if (DebCount_Mode == Time_25MS)
      DebFlag_Mode = '1;
    else
      DebFlag_Mode = '0;
  end

  // 500MS after Trip button has been pressed
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_intertrip <= STATE_IDLE_INTERTRIP;
      InterCount_Trip <= '0;
    end
      else
        unique case (state_intertrip)
          STATE_IDLE_INTERTRIP: begin
            if ((DebFlag_Trip) && (InterCount_Trip == 0) && (InterCount_Mode == 0)) begin
              state_intertrip <= STATE_COUNT_INTERTRIP;
              InterCount_Trip <= InterCount_Trip + 1;
            end
          end
          STATE_COUNT_INTERTRIP: begin
            if ((InterCount_Trip == Time_500MS) || (DebFlag_Trip) || (DebFlag_Mode)) begin
              state_intertrip <= STATE_IDLE_INTERTRIP;
              InterCount_Trip <= '0;
            end
            else
              InterCount_Trip <= InterCount_Trip + 1;
          end
        endcase
  end

  // 500MS after Mode button has been pressed
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_intermode <= STATE_IDLE_INTERMODE;
      InterCount_Mode <= '0;
    end
    else
      unique case (state_intermode)
        STATE_IDLE_INTERMODE: begin
          if ((DebFlag_Mode) && (InterCount_Mode == 0) && (InterCount_Trip == 0)) begin
            state_intermode <= STATE_COUNT_INTERMODE;
            InterCount_Mode <= InterCount_Mode + 1;
          end
        end
        STATE_COUNT_INTERTRIP: begin
          if ((InterCount_Mode == Time_500MS) || (DebFlag_Mode) || (DebFlag_Trip)) begin
            state_intermode <= STATE_IDLE_INTERMODE;
            InterCount_Mode <= '0;
          end
          else
            InterCount_Mode <= InterCount_Mode + 1;
        end
      endcase
  end

  // One clock delay new read and write signals generation
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      Write <= '0;
      Addr_Reg <= '0;
    end
    else if (HSEL && HREADY && (HTRANS != Stop_Transferring)) begin
      Write <= HWRITE;
      Addr_Reg <= HADDR[4:2];
    end
    else begin
      Write <= '0;
      Addr_Reg <= 4;
    end
  end

  // Read button registers
  always_comb begin
    if (Write)
        HRDATA = '0;
    else
      HRDATA = '0;
      case (Addr_Reg)
        DayNight_Reg_Addr:  begin HRDATA = {31'b0, DayNight_Store}; end
        Mode_Reg_Addr:      begin HRDATA = {31'b0, Mode_Store};     end
        Trip_Reg_Addr:      begin HRDATA = {31'b0, Trip_Store};     end
        Setting_Reg_Addr:   begin HRDATA = {31'b0, Setting_Store};  end
        NewData_Reg_Addr:   begin HRDATA = {31'b0, NewData};        end
      endcase
  end
  
  // Write button registers
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
        Setting_Store <= '0;
        Trip_Store <= '0;
        Mode_Store <= '0;
        DayNight_Store <= '0;
    end
    /*
    // Software write
    else if (Write)
      case (Addr_Reg)
        DayNight_Reg_Addr:  DayNight_Store <= HWDATA[0];
        Mode_Reg_Addr:      Mode_Store <= HWDATA[0];
        Trip_Reg_Addr:      Trip_Store <= HWDATA[0];
        Setting_Reg_Addr:   Setting_Store <= HWDATA[0];
        NewData_Reg_Addr:   NewData <= HWDATA[0];
      endcase
    */
    // Hardware write
    // Read register refresh
    else if (
                ((Addr_Reg == Mode_Reg_Addr) && (Mode_Store)) ||
                ((Addr_Reg == Trip_Reg_Addr) && (Trip_Store)) ||
                ((Addr_Reg == Setting_Reg_Addr) && (Setting_Store)) ||
                ((Addr_Reg == DayNight_Reg_Addr) && (DayNight_Store))
            ) begin
      Setting_Store <= '0;
      Mode_Store <= '0;
      Trip_Store <= '0;
      DayNight_Store <= '0;
    end
    else begin
      if (Con_DayNight)
        DayNight_Store <= 1;

      if (Con_Setting)
        Setting_Store <= 1;
      
      if (Con_Trip)
        Trip_Store <= 1;
      
      if (Con_Mode)
        Mode_Store <= 1;
    end
  end

  assign Con_Trip = (InterCount_Trip == Time_500MS);
  assign Con_Mode = (InterCount_Mode == Time_500MS);
  assign Con_DayNight = (DebFlag_Mode) && (InterCount_Mode != Time_500MS) && (InterCount_Mode != 0);
  assign Con_Setting = ((DebFlag_Mode) && (InterCount_Trip != Time_500MS) && (InterCount_Trip != 0)) ||
                       ((DebFlag_Trip) && (InterCount_Mode != Time_500MS) && (InterCount_Mode != 0)) ||
                       ((DebFlag_Mode) && (DebFlag_Trip));
  assign NewData = Setting_Store || Trip_Store || Mode_Store || DayNight_Store; 

  // Ready signal generation
  assign HREADYOUT = '1;

endmodule