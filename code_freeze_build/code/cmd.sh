stop=0
format(){
files=""
for anyFile in `ls`
do
	anyFileName="$anyFile"
	files="$files $anyFileName"
done
dosFile=""
for fileName in $files
do
	check=`file "$fileName"`
	message=$(echo $check | grep "with CRLF line terminators")
	if [[ $message != "" ]]; then
		echo "$check"
		dosFile="$dosFile $fileName"
	fi
done
if [[ $dosFile != "" ]]; then
	# echo -e "\n > Do you want to convert them all into Unix format? (PlEASE REMEBER BACKUP!)"
	# echo "    y for Yes, Enter Any Key Else to Quit."
	# read -p "Enter: " choice
	# if [ "$choice" = "y" ]; then
	for fileName in $dosFile
	do
	dos2unix "$fileName"
	done	 
	# fi
else
	echo -e "\nAll files are unix format.\n"
fi
}

echo "------------------------------------------"
echo " > Select Command:"
echo "1.Compile Software."
echo "2.Behavioural.        (2+gui with Graphics)"
echo "3.Gate Level.         (3+gui with Graphics)"
echo "4.Place and Route.    (4+gui with Graphics)"
echo "s.Synthesis."
echo "d.DOS Format Check."
echo "new_padring.New Padring   (Backup Needed!)"
echo "new_layout.New Layout     (Backup Needed!)"
echo "------------------------------------------"
echo " Enter Number to Run. Enter Any Key Else to Quit."
read -p "Enter: " choice
if [ "$choice" = "1" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
	cd software
	./compile_and_link
	cd ..
	cp ./software/code.vmem ./behavioural/code.vmem
elif [ "$choice" = "2" ]; then # Behavioural
	echo -e "\n------------------------------------------\n Processing...\n"
	mv ./behavioural/computer.sv ./computer.sv
	./simulate -no_graphics ./behavioural 200s +define+stimulus=system2/stimulus.sv
	mv ./computer.sv ./behavioural/computer.sv
elif [ "$choice" = "3" ]; then # Gate Level
	echo -e "\n------------------------------------------\n Processing...\n"
	./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level +define+stimulus=system2/stimulus.sv
elif [ "$choice" = "4" ]; then # Place and Route
	echo -e "\n------------------------------------------\n Processing...\n"
	./simulate -no_graphics -gate -sdf ./extracted/computer.sdf ./extracted +define+stimulus=system2/stimulus.sv
elif [ "$choice" = "2+gui" ]; then # Behavioural
	echo -e "\n------------------------------------------\n Processing...\n"
	mv ./behavioural/computer.sv ./computer.sv
	./simulate ./behavioural 200s +define+stimulus=system2/stimulus.sv
	mv ./computer.sv ./behavioural/computer.sv
elif [ "$choice" = "3+gui" ]; then # Gate Level
	echo -e "\n------------------------------------------\n Processing...\n"
	./simulate -gate -sdf ./gate_level/computer.sdf ./gate_level +define+stimulus=system2/stimulus.sv
elif [ "$choice" = "4+gui" ]; then # Place and Route
	echo -e "\n------------------------------------------\n Processing...\n"
	./simulate -gate -sdf ./extracted/computer.sdf ./extracted +define+stimulus=system2/stimulus.sv
elif [ "$choice" = "new_padring" ]; then # new_padring
	echo -e "\n------------------------------------------\n Processing...\n"
	cd ./padring
	process_pad_ring padring.txt
	cp computer.sv ../behavioural/computer.sv
elif [ "$choice" = "new_layout" ]; then # new_layout
	echo -e "\n------------------------------------------\n Processing...\n"
	cp ./place_and_route/place_and_route.tcl ./place_and_route.tcl
	rm -rf place_and_route
	prepare_edi computer place_and_route
	mv ./place_and_route.tcl ./place_and_route/place_and_route.tcl
	cd place_and_route
	encounter
	cd ..
	cp ./place_and_route/computer_final.v ./extracted/computer.v
	cp ./place_and_route/SDF/computer_func_max.sdf ./extracted/computer.sdf
elif [ "$choice" = "s" ]; then # synthesis
	echo -e "\n------------------------------------------\n Processing...\n"
	cd ./synthesis
	init=0
	for files in `ls -a`
	do
		if [ "$files" = ".synopsys_dc.setup" ]; then
			init=1
		fi
	done
	if [ "$init" = "0" ]; then
		echo " > Seems you didn't setup, do you want to setup now?"
		echo "   y for Yes, Enter Any Key Else for No."
		read -p "Enter: " choice
		if [ "$choice" = "y" ]; then
			do_c35b4_copy_synopsys_setup
		fi
	fi
dc_shell << EOF
	source synthesis.tcl
	quit
EOF
	cd ..
elif [ "$choice" = "d" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
	echo "Check folder chip"
	format
	cd ./behavioural
	echo "Check folder behavioural:"
	format
	cd ..
	cd ./gate_level
	echo "Check folder gate_level:"
	format
	cd ..
	cd ./extracted
	echo "Check folder extracted:"
	format
	cd ..
	cd ./software/code
	echo "Check folder software/code:"
	format
	cd ..
	cd ..
	cd ./system2
	echo "Check folder system2:"
	format
	cd ..
	cd ./system
	echo "Check folder system:"
	format
	cd ..
	cd ./padring
	echo "Check folder system:"
	format
	cd ..
fi

if [ $stop -eq 0 ]; then
	echo -e "\n\n *********** Process Finished ************\n"
	echo -e "------------------------------------------\n"
else
	echo -e "\n Process Stopped.\n"
	echo -e "------------------------------------------\n"
fi
