stop=0

# check enviornment for stupid user
fileList=""
for file in `ls`
do
	fileName="$file"
	fileList="$fileList $fileName"
done
if [ "$fileList" = " build.sh code" ]; then
	echo -e "------------------------------------------\n"
    echo -e "Start building project...\n"
else
	echo -e "------------------------------------------\n"
    echo -e "Enviornment check failed."
	echo -e "Too many files in this directory:$fileList\n"
	stop=1
fi

# make directories
if [ $stop -eq 0 ]; then
	echo -e "------------------------------------------\n"
    echo -e "Start placing files\n"
	echo "Calling a prepared command on this unix machine:" # read this as a comment
	init_soc_asic_introductory_example -here
	rm -rf behavioural
	rm -rf testbench
	echo "Calling a prepared command on this unix machine:"  # read this as a comment
	init_chip_environment -force -here
	echo "Creating directories"  # read this as a comment
	mkdir behavioural
	mkdir constraints
	mkdir extracted
	mkdir gate_level
	mkdir macro_models
	mkdir padring
	mkdir place_and_route
	mkdir post_process
	mkdir synthesis
	mkdir system2
	echo "Moving files to directories"  # read this as a comment 
	cp ./code/ahb_interconnect.sv ./behavioural/ahb_interconnect.sv
	cp ./code/ahb_ram.sv ./behavioural/ahb_ram.sv
	cp ./code/ahb_rom.sv ./behavioural/ahb_rom.sv
	cp ./code/button_manager.sv ./behavioural/button_manager.sv
	cp ./code/comp_core.sv ./behavioural/comp_core.sv
	cp ./code/computer.sv ./behavioural/computer.sv
	cp ./code/CORTEXM0DS.sv ./behavioural/CORTEXM0DS.sv
	cp ./code/cortexm0ds_logic.sv ./behavioural/cortexm0ds_logic.sv
	cp ./code/oled_manager.sv ./behavioural/oled_manager.sv
	cp ./code/sensor_manager.sv ./behavioural/sensor_manager.sv
	cp ./code/seven_segment.sv ./behavioural/seven_segment.sv
	cp ./code/timer.sv ./behavioural/timer.sv
	cp ./code/options_behavioural.sv ./behavioural/options.sv

	cp ./code/main.c ./software/code/main.c

	cp ./code/padring.txt ./padring/padring.txt
	cd ./padring
	process_pad_ring padring.txt
	cd ..
	cp ./code/computer.sv ./padring/computer.sv

	cp ./code/synthesis.tcl ./synthesis/synthesis.tcl
	cp ./system/system.sv ./gate_level/system.sv
	cp ./code/options_gate_level.sv ./gate_level/options.sv

	cp ./code/place_and_route.tcl ./place_and_route/place_and_route.tcl
	cp ./system/system.sv ./extracted/system.sv
	cp ./code/options_gate_level.sv ./extracted/options.sv

	cp ./code/options_gate_level.sv ./system/options.sv
	cp ./code/system.tcl ./system/system.tcl

	cp ./code/system.tcl ./behavioural/system.tcl
	cp ./code/system.tcl ./gate_level/system.tcl
	cp ./code/system.tcl ./extracted/system.tcl

	cp ./code/stimulus.sv ./system2/stimulus.sv
	cp ./code/display.sv ./system2/display.sv

	cp ./code/cmd.sh ./cmd.sh

	rm -rf code

	dos2unix cmd.sh
	
bash cmd.sh << EOF
	1
EOF

bash cmd.sh << EOF
	d
EOF

	echo -e "\nEnd placing files\n"
fi

# synthesis
if [ $stop -eq 0 ]; then
	echo -e "------------------------------------------\n"
    echo -e "Start synthesis\n"
	cd ./synthesis
	do_c35b4_copy_synopsys_setup
dc_shell -no_gui << EOF
	source synthesis.tcl
	quit
EOF
	cd ..
fi

# place and route
if [ $stop -eq 0 ]; then
	echo -e "------------------------------------------\n"
    echo -e "Start place and route\n"
	cp ./place_and_route/place_and_route.tcl ./place_and_route.tcl
	rm -rf place_and_route
	prepare_edi computer place_and_route
	mv ./place_and_route.tcl ./place_and_route/place_and_route.tcl
	cd ./place_and_route
encounter -no_gui << EOF
	source place_and_route.tcl
	exit
EOF
	cd ..
	cp ./place_and_route/computer_final.v ./extracted/computer.v
	cp ./place_and_route/SDF/computer_func_max.sdf ./extracted/computer.sdf
fi

# end building project
if [ $stop -eq 0 ]; then
	echo -e "\n\n *********** Process Finished ************\n"
	echo -e "------------------------------------------\n"
else
	echo -e "\n Process Stopped.\n"
	echo -e "------------------------------------------\n"
fi