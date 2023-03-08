module seven_segment(
    // AHB signals
    input wire HCLK,
    input wire HRESETn,

    input wire [31:0] HADDR,    // Only HADDR[2] is used (other bits are ignored)
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

    timeunit 1ns;
    timeprecision 100ps;

    localparam SevenSeg_Decimal_Reg_Addr = 0;
    localparam SevenSeg_Integer_Reg_Addr = 1;

    localparam Stop_Transferring = 2'b0;

    // For read signals one clock delay
    logic Addr_Reg;
    logic Write;

    // Address 0xA0000000 for decimal
    logic [6:0] Store_Frac;
    // Address 0xA0000004 for integer
    logic [6:0] Store_Int;

    // Decoder binary to BCD
    enum logic [2:0] {STATE_IDLE, STATE_ADD, STATE_SHIFT, STATE_END} state;
    logic Decoder_Control;
    logic [3:0] Decoder_Counter;
    logic [14:0] Decoder_Shift_Decimal;
    logic [14:0] Decoder_Shift_Integer;
    logic [7:0] SevenSeg_Store_BCD_Decimal;
    logic [7:0] SevenSeg_Store_BCD_Integer;

    // Seven segment display
    logic [1:0] SevenSeg_Counter;
    logic [3:0] Disp_Data;

    // One clock delay new read write signals generation
    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
        begin
            Write <= '0;
            Addr_Reg <= '0;
        end
        else if (HSEL && HREADY && (HTRANS != Stop_Transferring))
        begin
            Write <= HWRITE;
            Addr_Reg <= HADDR[2];
        end
        else
        begin
            Write <= '0;
            Addr_Reg <= '0;
        end
    end

    assign HRDATA = '0;

/*
    // Read SevenSeg Store reg
    always_comb
        if (Write)
            HRDATA = '0;
        else
            unique case (Addr_Reg)
                SevenSeg_Decimal_Reg_Addr:
                begin
                    HRDATA = {25'b0, Store_Frac};
                end
                SevenSeg_Integer_Reg_Addr:
                begin
                    HRDATA = {25'b0, Store_Int};
                end
                default:
                begin
                    HRDATA = '0;
                end
            endcase
*/

    // Write SevenSeg Store reg
    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
        begin
            Store_Frac <= '0;
            Store_Int <= '0;
        end
        // Software write
        else if (Write)
        begin
            case (Addr_Reg)
                SevenSeg_Decimal_Reg_Addr:
                    Store_Frac <= HWDATA[6:0];
                SevenSeg_Integer_Reg_Addr:
                    Store_Int <= HWDATA[6:0];
            endcase
        end
    end

    // Before decoding: new control signal generation, ensure the new sevenseg store value will be stored correctly
    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
            Decoder_Control <= '0;
        else if ((Write) && (Addr_Reg))
            Decoder_Control <= '1;
        else
            Decoder_Control <= '0;
    end

    // Decode binary to BCD
    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
        begin
            state <= STATE_IDLE;
            Decoder_Counter <= '0;
            Decoder_Shift_Decimal <= '0;
            Decoder_Shift_Integer <= '0;
        end
        else
            unique case (state)
                STATE_IDLE:
                begin
                    if (Decoder_Control)
                    begin
                        state <= STATE_ADD;
                        Decoder_Shift_Decimal <= {8'b0, Store_Frac};
                        Decoder_Shift_Integer <= {8'b0, Store_Int};
                    end
                end
                STATE_ADD:
                begin
                    state <= STATE_SHIFT;
                    Decoder_Counter <= Decoder_Counter + 1;
                    if (Decoder_Shift_Decimal[10:7] > 4)
                        Decoder_Shift_Decimal[10:7] <= Decoder_Shift_Decimal[10:7] + 3;
        
                    if (Decoder_Shift_Decimal[14:11] > 4)
                        Decoder_Shift_Decimal[14:11] <= Decoder_Shift_Decimal[14:11] + 3;

                    if (Decoder_Shift_Integer[10:7] > 4)
                        Decoder_Shift_Integer[10:7] <= Decoder_Shift_Integer[10:7] + 3;
        
                    if (Decoder_Shift_Integer[14:11] > 4)
                        Decoder_Shift_Integer[14:11] <= Decoder_Shift_Integer[14:11] + 3;
                end
                STATE_SHIFT:
                begin
                    if (Decoder_Counter < 7)
                    begin
                        state <= STATE_ADD;
                        Decoder_Shift_Decimal <= Decoder_Shift_Decimal << 1;
                        Decoder_Shift_Integer <= Decoder_Shift_Integer << 1;
                    end
                    else
                        state <= STATE_END;
                end
                STATE_END:
                begin
                    state <= STATE_IDLE;
                    Decoder_Counter <= '0;
                    SevenSeg_Store_BCD_Decimal <= Decoder_Shift_Decimal[13:6];  // Have to left shift once to get the right answer
                    SevenSeg_Store_BCD_Integer <= Decoder_Shift_Integer[13:6];
                end
                default:
                    state <= STATE_IDLE;
                endcase
    end

    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (!HRESETn)
            SevenSeg_Counter <= '0;
        else if (SevenSeg_Counter == 3)
            SevenSeg_Counter <= '0;
        else
            SevenSeg_Counter <= SevenSeg_Counter + 1;
    end

    always_comb
    begin
        unique case (SevenSeg_Counter)
            0: nDigit = 4'b1110;
            1: nDigit = 4'b1101;
            2: nDigit = 4'b1011;
            3: nDigit = 4'b0111;
            default: nDigit = 4'b1111;
        endcase
    end

    always_comb
    begin
        if (SevenSeg_Store_BCD_Integer[7:4] == '0)
            unique case (SevenSeg_Counter)
                0:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Decimal[3:0];
                    DP = '0;
                end
                1:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Decimal[7:4];
                    DP = '0;
                end
                2:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Integer[3:0];
                    DP = '1;
                end
                3:
                begin
                    Disp_Data = 4'ha;
                    DP = '0;
                end
                default:
                begin
                    Disp_Data = '0;
                    DP = '0;
                end
            endcase
        else
            unique case (SevenSeg_Counter)
                0:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Decimal[7:4];
                    DP = '0;
                end
                1:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Integer[3:0];
                    DP = '1;
                end
                2:
                begin
                    Disp_Data = SevenSeg_Store_BCD_Integer[7:4];
                    DP = '0;
                end
                3:
                begin
                    Disp_Data = 4'ha;
                    DP = '0;
                end
                default:
                begin
                    Disp_Data = '0;
                    DP = '0;
                end
            endcase
    end

    always_comb
    begin
        unique case (Disp_Data)
            4'h0:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '1;
                SegD = '1;
                SegE = '1;
                SegF = '1;
                SegG = '0;
            end
            4'h1:
            begin
                SegA = '0;
                SegB = '1;
                SegC = '1;
                SegD = '0;
                SegE = '0;
                SegF = '0;
                SegG = '0;
            end
            4'h2:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '0;
                SegD = '1;
                SegE = '1;
                SegF = '0;
                SegG = '1;
            end
            4'h3:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '1;
                SegD = '1;
                SegE = '0;
                SegF = '0;
                SegG = '1;
            end
            4'h4:
            begin
                SegA = '0;
                SegB = '1;
                SegC = '1;
                SegD = '0;
                SegE = '0;
                SegF = '1;
                SegG = '1;
            end
            4'h5:
            begin
                SegA = '1;
                SegB = '0;
                SegC = '1;
                SegD = '1;
                SegE = '0;
                SegF = '1;
                SegG = '1;
            end
            4'h6:
            begin
                SegA = '1;
                SegB = '0;
                SegC = '1;
                SegD = '1;
                SegE = '1;
                SegF = '1;
                SegG = '1;
            end
            4'h7:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '1;
                SegD = '0;
                SegE = '0;
                SegF = '0;
                SegG = '0;
            end
            4'h8:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '1;
                SegD = '1;
                SegE = '1;
                SegF = '1;
                SegG = '1;
            end
            4'h9:
            begin
                SegA = '1;
                SegB = '1;
                SegC = '1;
                SegD = '1;
                SegE = '0;
                SegF = '1;
                SegG = '1;
            end
            4'ha:
            begin
                SegA = '0;
                SegB = '1;
                SegC = '1;
                SegD = '1;
                SegE = '1;
                SegF = '0;
                SegG = '1;
            end
            default:
            begin
                SegA = '0;
                SegB = '0;
                SegC = '0;
                SegD = '0;
                SegE = '0;
                SegF = '0;
                SegG = '0;
            end
        endcase
    end

    // Ready signal generation
    assign HREADYOUT = '1; 

endmodule