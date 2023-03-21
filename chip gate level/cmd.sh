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
	echo -e "\n > Do you want to convert them all into Unix format? (PlEASE REMEBER BACKUP!)"
	echo "    y for Yes, Enter Any Key Else to Quit."
	read -p "Enter: " choice
	if [ "$choice" = "y" ]; then
		for fileName in $dosFile
		do
		dos2unix "$fileName"
		done	 
	fi
else
	echo -e "\nAll files are unix format.\n"
fi
}

echo "------------------------------------------"
echo " > Select Command:"
echo "1.Compile Software."
echo "2.Complete Gate Level (No Graphics) Version: +GateLevel +ScanPath +OLED +NoGraphics."
echo "3.Complete Gate Level (with Graphics) Version: +GateLevel +ScanPath +OLED."
echo "4.LED only Gate Level (No Graphics) Version: +GateLevel +ScanPath +NoGraphics."
echo "5.LED only Gate Level (with Graphics) Version: +GateLevel +ScanPath."
echo "6.LED only Behavioural (No Graphics) Version: +NoGraphics."
echo "7.LED only Behavioural (with Graphics) Version."
echo "8.Macro Cell Version."
echo "s.Synthesis."
echo "d.DOS Format Check."
echo "------------------------------------------"
echo " Enter Number to Run. Enter Any Key Else to Quit."
read -p "Enter: " choice
if [ "$choice" = "1" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
	cd software
	./compile_and_link
	cd ..
	cp ./software/code.vmem ./behavioural/code.vmem
elif [ "$choice" = "2" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
+define+clock_period=30517.6ns \
+define+scan_enable \
+define+external_pullup \
+define+start_up_time=1s \
+define+include_oled \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "3" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
+define+clock_period=30517.6ns \
+define+scan_enable \
+define+external_pullup \
+define+start_up_time=1s \
+define+include_oled \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "4" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
+define+clock_period=30517.6ns \
+define+scan_enable \
+define+external_pullup \
+define+start_up_time=1s \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "5" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate -gate -sdf ./gate_level/computer.sdf ./gate_level \
+define+clock_period=30517.6ns \
+define+scan_enable \
+define+external_pullup \
+define+start_up_time=1s \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "6" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate -no_graphics ./behavioural 200s \
+define+clock_period=30517.6ns \
+define+no_scan_signals \
+define+external_pullup \
+define+start_up_time=1s \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "7" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate ./behavioural 200s \
+define+clock_period=30517.6ns \
+define+no_scan_signals \
+define+external_pullup \
+define+start_up_time=1s \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
elif [ "$choice" = "8" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
./simulate ./behavioural 200s \
+define+clock_period=30517.6ns \
+define+no_scan_signals \
+define+external_pullup \
+define+start_up_time=1s \
+define+num_modes=4 \
+define+Mode0=Distance \
+define+Mode1=Duration \
+define+Mode2=Speed \
+define+Mode3=Cadence \
+define+stimulus=system2/stimulus.sv
+define+functional
elif [ "$choice" = "s" ]; then
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
	dc_shell -gui
	cd ..
elif [ "$choice" = "d" ]; then
	echo -e "\n------------------------------------------\n Processing...\n"
	echo "Check folder chip"
	format
	cd ./behavioural
	echo "Check folder behavioural:"
	format
	cd ..
	cd ./software
	echo "Check folder software:"
	format
	cd ./code
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
