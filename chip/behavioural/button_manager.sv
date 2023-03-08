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

  localparam Time_25MS = 900;
  localparam Time_500MS = 16000;

  localparam ButtonNum = 2;
  
  localparam NewData_Reg_Addr = 4;
  localparam Setting_Reg_Addr = 3;
  localparam Trip_Reg_Addr = 2;
  localparam Mode_Reg_Addr = 1;
  localparam DayNight_Reg_Addr = 0;

  localparam Stop_Transferring = 2'b0;

  // Button debounce
  logic Trip_Last;
  logic Mode_Last;
  logic [9:0] Trip_Counter;           // Trip button debounce counter
  logic [9:0] Mode_Counter;           // Mode button debounce counter
  logic [14:0] Trip_Click_Counter;    // Trip button after counter
  logic [14:0] Mode_Click_Counter;    // Mode button after counter
  logic Trip_Button_Debounce;
  logic Mode_Button_Debounce;
  wire DayNight_Condition;
  wire Trip_Condition;
  wire Mode_Condition;
  wire Setting_Condition;
  enum logic [1:0] {STATE_IDLE_BEFORE_TRIP, STATE_COUNTER_BEFORE_TRIP} state_before_trip;
  enum logic [1:0] {STATE_IDLE_BEFORE_MODE, STATE_COUNTER_BEFORE_MODE} state_before_mode;
  enum logic [1:0] {STATE_IDLE_AFTER_TRIP, STATE_COUNTER_AFTER_TRIP} state_after_trip;
  enum logic [1:0] {STATE_IDLE_AFTER_MODE, STATE_COUNTER_AFTER_MODE} state_after_mode;

  // For read and read signals one clock delay
  logic [2:0] Addr_Reg;
  logic WriteEnable;

  // Memory map definition
  wire NewData;
  logic Setting_Store;
  logic Trip_Store;
  logic Mode_Store;
  logic DayNight_Store;

  // For the Trip Mode negative edge detection
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      Trip_Last <= '0;
      Mode_Last <= '0;
    end
    else begin
      Trip_Last <= Trip;
      Mode_Last <= Mode;
    end
  end

  // Trip button debounce
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_before_trip <= STATE_IDLE_BEFORE_TRIP;
      Trip_Counter <= '0;
    end
    else
      unique case (state_before_trip)
        STATE_IDLE_BEFORE_TRIP: begin
          if (!Trip && Trip_Last) begin
            state_before_trip <= STATE_COUNTER_BEFORE_TRIP;
            Trip_Counter <= Trip_Counter + 1;
          end
        end
        STATE_COUNTER_BEFORE_TRIP: begin
          if ((Trip_Counter == Time_25MS) || (Trip)) begin
            state_before_trip <= STATE_IDLE_BEFORE_TRIP;
            Trip_Counter <= '0;
          end
          else
            Trip_Counter <= Trip_Counter + 1;
        end
      endcase
  end

  always_comb begin
    if (Trip_Counter == Time_25MS)
      Trip_Button_Debounce = '1;
    else
      Trip_Button_Debounce = '0;
  end

  // Mode button debounce
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_before_mode <= STATE_IDLE_BEFORE_MODE;
      Mode_Counter <= '0;
    end
      else
        unique case (state_before_mode)
          STATE_IDLE_BEFORE_MODE: begin
            if (!Mode && Mode_Last) begin
              state_before_mode <= STATE_COUNTER_BEFORE_MODE;
              Mode_Counter <= Mode_Counter + 1;
            end
          end
          STATE_COUNTER_BEFORE_MODE: begin
            if ((Mode_Counter == Time_25MS) || (Mode)) begin
              Mode_Counter <= '0;
              state_before_mode <= STATE_IDLE_BEFORE_MODE;
            end
            else
              Mode_Counter <= Mode_Counter + 1;
          end
        endcase
  end

  always_comb
  begin
    if (Mode_Counter == Time_25MS)
      Mode_Button_Debounce = '1;
    else
      Mode_Button_Debounce = '0;
  end

  // 500MS after Trip button has been pressed
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_after_trip <= STATE_IDLE_AFTER_TRIP;
      Trip_Click_Counter <= '0;
    end
      else
        unique case (state_after_trip)
          STATE_IDLE_AFTER_TRIP: begin
            if ((Trip_Button_Debounce) && (Trip_Click_Counter == 0) && (Mode_Click_Counter == 0)) begin
              state_after_trip <= STATE_COUNTER_AFTER_TRIP;
              Trip_Click_Counter <= Trip_Click_Counter + 1;
            end
          end
          STATE_COUNTER_AFTER_TRIP: begin
            if ((Trip_Click_Counter == Time_500MS) || (Trip_Button_Debounce) || (Mode_Button_Debounce)) begin
              state_after_trip <= STATE_IDLE_AFTER_TRIP;
              Trip_Click_Counter <= '0;
            end
            else
              Trip_Click_Counter <= Trip_Click_Counter + 1;
          end
        endcase
  end

  // 500MS after Mode button has been pressed
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      state_after_mode <= STATE_IDLE_AFTER_MODE;
      Mode_Click_Counter <= '0;
    end
    else
      unique case (state_after_mode)
        STATE_IDLE_AFTER_MODE: begin
          if ((Mode_Button_Debounce) && (Mode_Click_Counter == 0) && (Trip_Click_Counter == 0)) begin
            state_after_mode <= STATE_COUNTER_AFTER_MODE;
            Mode_Click_Counter <= Mode_Click_Counter + 1;
          end
        end
        STATE_COUNTER_AFTER_TRIP: begin
          if ((Mode_Click_Counter == Time_500MS) || (Mode_Button_Debounce) || (Trip_Button_Debounce)) begin
            state_after_mode <= STATE_IDLE_AFTER_MODE;
            Mode_Click_Counter <= '0;
          end
          else
            Mode_Click_Counter <= Mode_Click_Counter + 1;
        end
      endcase
  end

  // One clock delay new read and write signals generation
  always_ff @ (posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      WriteEnable <= '0;
      Addr_Reg <= '0;
    end
    else if (HSEL && HREADY && (HTRANS != Stop_Transferring)) begin
      WriteEnable <= HWRITE;
      Addr_Reg <= HADDR[4:2];
    end
    else begin
      WriteEnable <= '0;
      Addr_Reg <= 4;
    end
  end

  // Read button registers
  always_comb begin
    if (WriteEnable)
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
    else if (WriteEnable)
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
        if (DayNight_Condition)
            DayNight_Store <= 1;

        if (Setting_Condition)
            Setting_Store <= 1;
        
        if (Trip_Condition)
            Trip_Store <= 1;
        
          if (Mode_Condition)
            Mode_Store <= 1;
    end
  end

  assign Trip_Condition = (Trip_Click_Counter == Time_500MS);
  assign Mode_Condition = (Mode_Click_Counter == Time_500MS);
  assign DayNight_Condition = (Mode_Button_Debounce) && (Mode_Click_Counter < Time_500MS) && (Mode_Click_Counter != 0);
  assign Setting_Condition = ((Mode_Button_Debounce) && (Trip_Click_Counter < Time_500MS) && (Trip_Click_Counter != 0)) ||
                              ((Trip_Button_Debounce) && (Mode_Click_Counter < Time_500MS) && (Mode_Click_Counter != 0)) ||
                              ((Mode_Button_Debounce) && (Trip_Button_Debounce));
  assign NewData = Setting_Store || Trip_Store || Mode_Store || DayNight_Store; 

  // Ready signal generation
  assign HREADYOUT = '1;

endmodule