###################################################################

# Created by write_sdc on Sun Mar 12 15:35:14 2023

###################################################################
set sdc_version 2.0

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA
set_max_area 0
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
Clock]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports Clock]
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
nReset]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports nReset]
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
nFork]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports nFork]
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
nCrank]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports nCrank]
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
nTrip]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports nTrip]
set_driving_cell -min -lib_cell BU1P -library c35_IOLIB_WC -pin PAD [get_ports \
nMode]
set_driving_cell -max -lib_cell BU24P -library c35_IOLIB_WC -pin PAD           \
[get_ports nMode]
set_load -pin_load 1 [get_ports nCS]
set_load -pin_load 1 [get_ports DnC]
set_load -pin_load 1 [get_ports SDIN]
set_load -pin_load 1 [get_ports SCLK]
set_load -pin_load 1 [get_ports SegA]
set_load -pin_load 1 [get_ports SegB]
set_load -pin_load 1 [get_ports SegC]
set_load -pin_load 1 [get_ports SegD]
set_load -pin_load 1 [get_ports SegE]
set_load -pin_load 1 [get_ports SegF]
set_load -pin_load 1 [get_ports SegG]
set_load -pin_load 1 [get_ports DP]
set_load -pin_load 1 [get_ports {nDigit[3]}]
set_load -pin_load 1 [get_ports {nDigit[2]}]
set_load -pin_load 1 [get_ports {nDigit[1]}]
set_load -pin_load 1 [get_ports {nDigit[0]}]
set_load -min -pin_load 0.01 [get_ports nCS]
set_load -min -pin_load 0.01 [get_ports DnC]
set_load -min -pin_load 0.01 [get_ports SDIN]
set_load -min -pin_load 0.01 [get_ports SCLK]
set_load -min -pin_load 0.01 [get_ports SegA]
set_load -min -pin_load 0.01 [get_ports SegB]
set_load -min -pin_load 0.01 [get_ports SegC]
set_load -min -pin_load 0.01 [get_ports SegD]
set_load -min -pin_load 0.01 [get_ports SegE]
set_load -min -pin_load 0.01 [get_ports SegF]
set_load -min -pin_load 0.01 [get_ports SegG]
set_load -min -pin_load 0.01 [get_ports DP]
set_load -min -pin_load 0.01 [get_ports {nDigit[3]}]
set_load -min -pin_load 0.01 [get_ports {nDigit[2]}]
set_load -min -pin_load 0.01 [get_ports {nDigit[1]}]
set_load -min -pin_load 0.01 [get_ports {nDigit[0]}]
