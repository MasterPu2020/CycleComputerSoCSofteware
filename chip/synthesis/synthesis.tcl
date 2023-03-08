    analyze -format sv  "../behavioural/wrap_dice.sv ../behavioural/dice.sv ../behavioural/control.sv ../behavioural/encoder.sv ../behavioural/random.sv ../behavioural/dtype.sv"

    elaborate wrap_dice

    link

    set_max_area 400000
    
    create_clock -name master_clock  -period 30  [get_ports Clock]
    
    set_clock_latency     2.5 [get_clocks master_clock]
    set_clock_transition  0.5 [get_clocks master_clock]
    set_clock_uncertainty 1.0 [get_clocks master_clock]
     
    set_input_delay  2.0 -max -network_latency_included -clock master_clock \
    [remove_from_collection [all_inputs] [get_ports Clock]]
    set_input_delay  0.1 -min -network_latency_included -clock master_clock \
    [remove_from_collection [all_inputs] [get_ports Clock]]
    
    set_output_delay 2.0 -max -network_latency_included -clock master_clock \
    [all_outputs]
    set_output_delay 0.1 -min -network_latency_included -clock master_clock \
    [all_outputs]
    
    set_load 1.0  -max [all_outputs]
    set_load 0.01 -min [all_outputs]
    
    set_driving_cell -max -library c35_IOLIB_WC -lib_cell BU24P -pin PAD [all_inputs]
    set_driving_cell -min -library c35_IOLIB_WC -lib_cell BU1P -pin PAD [all_inputs]

    set_false_path -from [get_ports nReset]

    set_fix_hold master_clock

    set_dont_touch [get_cells RESET_SYNC_FF*]

    set_max_area 0
 
    compile

    current_design wrap_dice
    #ungroup -all -flatten
    
    set_dft_signal -view existing_dft -type ScanClock   -port Clock        -timing {45 60}
    set_dft_signal -view existing_dft -type Reset       -port nReset       -active_state 0

    set_dft_signal -view spec         -type TestMode    -port Test         -active_state 1
    set_dft_signal -view spec         -type ScanEnable  -port ScanEnable   -active_state 1
    set_dft_signal -view spec         -type ScanDataIn  -port SDI 
    set_dft_signal -view spec         -type ScanDataOut -port SDO

    create_test_protocol
    
    set_dft_configuration -fix_reset enable
    set_autofix_configuration -type reset -method mux -control Test -test_data nReset

    set_dft_configuration -fix_set enable
    set_autofix_configuration -type set -method mux -control Test -test_data nReset

    current_design wrap_dice  

    set_scan_configuration -chain_count 1


#set_dft_clock_gating_configuration -dont_connect_cgs_of \
#   {u_dice/u_random/dtype1/Q_reg u_dice/u_random/dtype2/Q_reg u_dice/u_random/dtype3/Q_reg u_dice/u_random/dtype4/Q_reg u_dice/u_random/dtype5/Q_reg u_dice/u_random/dtype6/Q_reg u_dice/u_random/dtype7/Q_reg u_dice/u_random/dtype8/Q_reg u_dice/u_random/dtype9/Q_reg u_dice/u_random/dtype10/Q_reg u_dice/u_random/dtype11/Q_reg}



    
    preview_dft

    insert_dft

    dft_drc

    compile -map_effort high -incremental_mapping
    
    compile -scan

    

    report_names -rules verilog
    change_names -rules verilog -hierarchy -verbose

    write -f verilog -hierarchy -output "../gate_level/wrap_dice.v"

    write_sdc ../constraints/wrap_dice.sdc
    write_sdf ../gate_level/wrap_dice.sdf

    report_power
    report_timing
    report_qor
    report_constraint -all_violators

    report_area > synth_area.rpt
    report_power > synth_power.rpt
    report_timing > synth_timing.rpt


	#set_app_var test_default_delay 0
