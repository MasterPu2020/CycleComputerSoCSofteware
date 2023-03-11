
//------------------------------------------------------------------------------
//   Title: System module - 2022/2023 SubFile: Monitor
//  Author: Clark Pu
//    Team: C4 Chip Designed
// Version: 2.0 Initial Behavioural Simulation
// Monitor Process
//------------------------------------------------------------------------------

// Timer Moniter
always @(posedge Clock) begin
  if (sel_timer) begin
    if (!ingore_read || ahb_addr[7:2] != 2)
      $display(" Timer Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Long Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Long Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Short Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && !write && !ingore_read )
      $display(" Read Flag Control Detected.  (%t)", $time);
    else if (!ingore_read || ahb_addr[7:2] != 2) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 2) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_timer, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end

// Sensor Manager Moniter
always @(posedge Clock) begin
  if (sel_sensor) begin
    $display(" Sensor Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Fork Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Fork Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Crank Control Detected. (%t)", $time);
    else begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (write) begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Write data: %d. (%t)",write_data, $time);
    end
    else begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Read data: %d. (%t)",data_sensor, $time);
    end
    $display("------------------------------------------------------------------------------");
  end
end

// OLED Manager Moniter
always @(posedge Clock) begin
  if (sel_oled) begin
    if (!ingore_read || ahb_addr[7:2] != 3 ) 
      $display(" OLED Manager Operation Detected.");
    if (ahb_addr[7:2] == 3 && write )
      $display(" Write Ready Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 0 && write )
      $display(" Write Area Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 1 && write )
      $display(" Write Colour1 Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && write )
      $display(" Write Colour2 Control Detected.  (%t)", $time);
    else if (ahb_addr[7:2] == 3 && !write && !ingore_read )
      $display(" Read Ready Control Detected. (%t)", $time);
    else if (!ingore_read || ahb_addr[7:2] != 3) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 3 ) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_oled, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end

// Seven Segment Manager Moniter : Write Only
always @(posedge Clock) begin
  if (sel_segment) begin
    $display(" Seven Segment Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && write )
      $display(" Write Segment Fraction Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 1 && write )
      $display(" Write Segment Integer Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && write)
      $display(" Write Segment Mode Control Detected. (%t)", $time);
    else begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (write && (ahb_addr[7:2] == 0 || ahb_addr[7:2] == 1 || ahb_addr[7:2] == 2)) begin
      #((`clock_period)/2); // deeeeeeeeeelay
      $display(" Write data: %d. (%t)",write_data, $time);
    end
    $display("------------------------------------------------------------------------------");
  end
end

// Button Manager Moniter : Read Only
always @(posedge Clock) begin
  if (sel_button) begin
    if (!ingore_read || ahb_addr[7:2] != 4 )
      $display(" Button Manager Operation Detected.");
    if (ahb_addr[7:2] == 0 && !write )
      $display(" Read Day Night Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 1 && !write )
      $display(" Read Mode Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 2 && !write )
      $display(" Read Trip Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 3 && !write )
      $display(" Read Setting Control Detected. (%t)", $time);
    else if (ahb_addr[7:2] == 4 && !write && !ingore_read)
      $display(" Read NewData Control Detected. (%t)", $time);
    else if (!ingore_read) begin
      $display(" *** WARNING ***: Selected, but wrong opertion. Address is %h. Write/nRead is %b. (%t)", ahb_addr, write, $time);
      $display("------------------------------------------------------------------------------");
      error ++;
    end
    if (!ingore_read || ahb_addr[7:2] != 4 ) begin
      if (write) begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Write data: %d. (%t)",write_data, $time);
      end
      else begin
        #((`clock_period)/2); // deeeeeeeeeelay
        $display(" Read data: %d. (%t)",data_button, $time);
      end
      $display("------------------------------------------------------------------------------");
    end
  end
end