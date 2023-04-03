//------------------------------------------------------------------------------
//   Title: System module - 2022/2023 SubFile: Display
//  Author: Clark Pu, Paiyun Chen (Circle)
//    Team: C4 Chip Designed
// Version: General Purpose
// Display Process
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------

// Fake OLED Display: Initial Definition
logic [127:0] oled_ram [127:0];
logic [  7:0] oled_command;
logic [ 15:0] oled_X, oled_Y, oled_real_colour;
logic [  7:0] oled_x, oled_y;
integer oled_counter;
string oled_row;
logic DisplayRefresh = 0;

// Fake Seven Segment Display: Initial Definition
string seg_row;
logic [7:0] seg_data [3:0];
real seg_digit_value2, seg_digit_value1, seg_digit_value0;
integer seg_digit_value3;
real seg_value;
logic DisplayRefresh_Seg = 0;

//------------------------------------------------------------------------------
// Fake OLED Display: Get Area and Colour
//------------------------------------------------------------------------------

initial begin
  oled_counter = 0;
  oled_command = 0;
  oled_X = 0;
  oled_Y = 0;
  oled_x = 0; 
  oled_y = 0;
  oled_real_colour = 0;
  forever begin
    @(posedge SCLK);
    if (DnC) begin
      if (oled_command == 8'b0001_0101) begin // oled_X location
        // $display("Writing oled_X... NO.%d bit", oled_counter);
        oled_X[0] = SDIN;
        if (oled_counter >= 15)
          oled_counter = 0;
        else begin
          oled_counter ++;
          oled_X = oled_X << 1;
          oled_x = oled_X[15:8];
        end
      end
      else if (oled_command == 8'b0111_0101) begin // oled_Y location
        // $display("Writing oled_Y... NO.%d bit", oled_counter);
        oled_Y[0] = SDIN;
        if (oled_counter >= 15)
          oled_counter = 0;
        else begin
          oled_counter ++;
          oled_Y = oled_Y << 1;
          oled_y = oled_Y[15:8];
        end
      end
      else if (oled_command == 8'b0101_1100) begin // Real Colour
        // $display("Writing Colour... NO.%d bit", oled_counter);
        oled_real_colour[0] = SDIN;
        if (oled_counter >= 15) begin
          oled_counter = 0;
          if (oled_real_colour == 16'hFFFF) begin
            oled_ram[oled_x][oled_y] = 0;
            //$display(" Pixel(%d, %d) 0 is written into OLED RAM (%t)", oled_x, oled_y, $time);
          end
          else begin
            oled_ram[oled_x][oled_y] = 1;
            //$display(" Pixel(%d, %d) 1 is written into OLED RAM (%t)", oled_x, oled_y, $time);
          end
          if (oled_x == oled_X[7:0]) begin
            oled_x = oled_X[15:8];
            if (oled_y == oled_Y[7:0])
              oled_y = oled_Y[15:8];
            else
              oled_y = oled_y + 1;
          end
          else
            oled_x = oled_x + 1;
        end
        else begin
          oled_counter ++;
          oled_real_colour = oled_real_colour << 1;
        end
      end
    end
    else begin
      // $display("Writing Command... NO.%d bit", oled_counter);
      oled_command[0] = SDIN;
      if (oled_counter >= 7) begin
        oled_counter = 0;
        // Debug
        // if (oled_command == 8'b0001_0101)
        //   $display("CMD: oled_X location. Accepted. (%t)", $time);
        // else if (oled_command == 8'b0111_0101)
        //   $display("CMD: oled_Y location. Accepted. (%t)", $time);
        // else if (oled_command == 8'b0101_1100)
        //   $display("CMD: Colour. Accepted.");
        // if (oled_command != 8'b0001_0101 && oled_command != 8'b0111_0101 && oled_command != 8'b0101_1100)
        //   $display("CMD: Unknown: %b.", oled_command, ". (%t)", $time);
      end
      else begin
        oled_counter ++;
        oled_command = oled_command << 1;
      end
    end
  end
end

//------------------------------------------------------------------------------
// Fake OLED Display: Post Text Picture
//------------------------------------------------------------------------------

initial begin
  forever begin
    @(DisplayRefresh);
    oled_row = "  ";
    $display("Refresh Screen: ");
    for (integer j = 0; j < 96; j++) begin
      for (integer i = 0; i < 128; i++) begin
        if(oled_ram[i][j])
          oled_row = {oled_row, "#"};
        else
          oled_row = {oled_row, "_"};
      end
      $display("%s", oled_row);
      oled_row = "  ";
    end
  end
end

//------------------------------------------------------------------------------
// Fake Seven Segment Display
//------------------------------------------------------------------------------

initial begin
  forever begin
    @ (posedge Clock);
    case (nDigit)
      4'b1110: begin seg_data[3] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b1101: begin seg_data[2] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b1011: begin seg_data[1] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
      4'b0111: begin seg_data[0] = {SegA, SegB, SegC, SegD, SegE, SegF, SegG, DP}; end
    endcase
  end
end

initial begin
  forever begin
    @(posedge Clock);
    unique case (seg_data[3][7:1])
      7'b1111110: seg_digit_value0 = 0;
      7'b0110000: seg_digit_value0 = 1;
      7'b1101101: seg_digit_value0 = 2;
      7'b1111001: seg_digit_value0 = 3;
      7'b0110011: seg_digit_value0 = 4;
      7'b1011011: seg_digit_value0 = 5;
      7'b1011111: seg_digit_value0 = 6;
      7'b1110000: seg_digit_value0 = 7;
      7'b1111111: seg_digit_value0 = 8;
      7'b1111011: seg_digit_value0 = 9;
      default   : seg_digit_value0 = 0;
    endcase

    unique case (seg_data[2][7:1])
      7'b1111110: seg_digit_value1 = 0;
      7'b0110000: seg_digit_value1 = 1;
      7'b1101101: seg_digit_value1 = 2;
      7'b1111001: seg_digit_value1 = 3;
      7'b0110011: seg_digit_value1 = 4;
      7'b1011011: seg_digit_value1 = 5;
      7'b1011111: seg_digit_value1 = 6;
      7'b1110000: seg_digit_value1 = 7;
      7'b1111111: seg_digit_value1 = 8;
      7'b1111011: seg_digit_value1 = 9;
      default   : seg_digit_value1 = 0;
    endcase

    unique case (seg_data[1][7:1])
      7'b1111110: seg_digit_value2 = 0;
      7'b0110000: seg_digit_value2 = 1;
      7'b1101101: seg_digit_value2 = 2;
      7'b1111001: seg_digit_value2 = 3;
      7'b0110011: seg_digit_value2 = 4;
      7'b1011011: seg_digit_value2 = 5;
      7'b1011111: seg_digit_value2 = 6;
      7'b1110000: seg_digit_value2 = 7;
      7'b1111111: seg_digit_value2 = 8;
      7'b1111011: seg_digit_value2 = 9;
      default   : seg_digit_value2 = 0;
    endcase

    unique case (seg_data[0][7:1])
      7'b0111101: seg_digit_value3 = 0;
      7'b0001111: seg_digit_value3 = 1;
      7'b0011000: seg_digit_value3 = 2;
      7'b0001101: seg_digit_value3 = 3;
      default   : seg_digit_value3 = 9;
    endcase
  end
end

initial begin
  forever begin
    @(posedge Clock);
    for (int m=0;m<4;m++) begin
      if (seg_data[m][0])
        seg_value = (seg_digit_value2 * 100 + seg_digit_value1 * 10 + seg_digit_value0) / (10 ** (3-m));
    end
  end
end

initial begin
  forever begin
    @(posedge DisplayRefresh_Seg);

    $display("\n Refresh Seven Segment LED: \n");
    seg_row = "   ";

    // SegA
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][7])
        seg_row = {seg_row, "---######---"};
      else if ((seg_data[m][2]) && (seg_data[m][6]))
        seg_row = {seg_row, "---#----#---"};
      else if ((seg_data[m][2]) && (!seg_data[m][6]))
        seg_row = {seg_row, "---#--------"};
      else if ((!seg_data[m][2]) && (seg_data[m][6]))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // SegF & SegB
    for (integer n = 0; n < 3; n++) begin
      for (integer m = 0; m < 4; m++) begin
        if ((seg_data[m][2]) && (seg_data[m][6]))
          seg_row = {seg_row, "---#----#---"};
        else if ((seg_data[m][2]) && (!seg_data[m][6]))
          seg_row = {seg_row, "---#--------"};
        else if ((!seg_data[m][2]) && (seg_data[m][6]))
          seg_row = {seg_row, "--------#---"};
        else
          seg_row = {seg_row, "------------"};
      end
      $display("%s", seg_row);
      seg_row = "   ";
    end

    // SegG
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][1])
        seg_row = {seg_row, "---######---"};
      else if (((seg_data[m][3]) || (seg_data[m][2])) && ((seg_data[m][5]) || (seg_data[m][6])))
        seg_row = {seg_row, "---#----#---"};
      else if (((seg_data[m][3]) || (seg_data[m][2])) && ((!seg_data[m][5]) && (!seg_data[m][6])))
        seg_row = {seg_row, "---#--------"};
      else if (((!seg_data[m][3]) && (!seg_data[m][2])) && ((seg_data[m][5]) || (seg_data[m][6])))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // SegE & SegC
    for (integer n = 0; n < 3; n++) begin
      for (integer m = 0; m < 4; m++) begin
        if ((seg_data[m][3]) && (seg_data[m][5]))
          seg_row = {seg_row, "---#----#---"};
        else if ((seg_data[m][3]) && (!seg_data[m][5]))
          seg_row = {seg_row, "---#--------"};
        else if ((!seg_data[m][3]) && (seg_data[m][5]))
          seg_row = {seg_row, "--------#---"};
        else
          seg_row = {seg_row, "------------"};
      end
      $display("%s", seg_row);
      seg_row = "   ";
    end

    // SegD
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][4])
        seg_row = {seg_row, "---######---"};
      else if ((seg_data[m][3]) && (seg_data[m][5]))
        seg_row = {seg_row, "---#----#---"};
      else if ((seg_data[m][3]) && (!seg_data[m][5]))
        seg_row = {seg_row, "---#--------"};
      else if ((!seg_data[m][3]) && (seg_data[m][5]))
        seg_row = {seg_row, "--------#---"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s", seg_row);
    seg_row = "   ";

    // DP
    for (integer m = 0; m < 4; m++) begin
      if (seg_data[m][0])
        seg_row = {seg_row, "----------##"};
      else
        seg_row = {seg_row, "------------"};
    end
    $display("%s\n", seg_row);
    seg_row = "   ";

    $display("\n Seven Segment Number = %0f \n", seg_value);

  end
end
