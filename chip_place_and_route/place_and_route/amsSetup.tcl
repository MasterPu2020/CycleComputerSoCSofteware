#######################################################
##                                                     
##  Encounter Command File      
##                              
##  Owner: austriamicrosystems  
##  HIT-Kit: Digital            
##  version: 24-Apr-2014        
##                              
##  Created on: Mon 20 Mar 18:25:18 GMT 2023                          
##                                                    
########################################################

proc amsHelp {} {
    print "#### Available Functions" 
    print "---#     - amsDbSetup....................... Setup Database - read Config"
    print "---#     - amsUserGrid...................... Sets the grid for the IO-Cells"
    print "---#     - amsGlobalConnect type............ connects global nets: "
    print "---#                                               type = core | both"
    print "---#     - amsAddEndCaps.................... place Caps"
    print "---#     - amsSetMMMC ....................... set MultiMode"
    print "---#     - amsSetAnalysisView cond conslist.. set Analysis Views"
    print "---#     - amsFillcore ...................... places core filler cells"
    print "---#     - amsFillperi ...................... places periphery filler cells"
    print "---#     - amsRoute router................... run routing with: "
    print "---#                                               router = nano|nanodcv|wroute|wroute2(using 2CPUs)"
    print "---#     - amsWrite postfix ................. writes GDS, Verilog NL, SPEF, DB"
    print "---#     - amsWriteSDF4View viewList......... write SDF for all analysis views in list"
    print "---#     - amsZoomTo x y .................... zooms to coordinates x y"
    print "#### " 
} 

proc addAMSHKMenu {} {
   global HKMenuAdded
   # add AMSMenu if Encounter version is higher or equal to 10
   set encVer [string range [getVersion] 0 [expr [string first . [getVersion]]-1]]
   if {$encVer >= 10} {
     uiAdd amsHKMenu -type menu -label "hitkit Utilities" -in main
     uiAdd expCommand -type command -label "Unfix Clock Nets" -command [list changeClockStatus -all -noFixedNetWires] -in amsHKMenu
     uiAdd expCommand -type command -label "Remove tmp_oa_db libs from cds.lib" -command [list removeTmpoalibs] -in amsHKMenu
     uiAdd expCommand -type command -label "Wroute..." -command [list ::Rda_Route::RouteStdCell::create] -in amsHKMenu
     print "### austriamicrosystems HitKit-Utilities Menu added";}
     set HKMenuAdded 1
}

proc amsDbSetup {} {
   global topcellname
   ##--- Load configuration file
   ## source c35_computer.globals
   ##--- if the netlist includes assign statements they can be replaced by buffers with following command
   ## setDoAssign on -buffer <buffername>
   init_design
   setCTSMode -bottomPreferredLayer 1
   setMaxRouteLayer 4
   setExtractRCMode -lefTechFileMap /opt/cad/designkits/ams/v410/cds/HK_C35/LEF/c35b4/qrclaymap.ccl
   
   ##-- some design checks at the beginning
   set filename1 [format "checkDesignDbSetup/%s.main.htm" $topcellname]
   checkDesign -all -outDir checkDesignDbSetup
   
   set filename2 [format "checkDesignDbSetup/%s.checkTiming" $topcellname]
   check_timing -verbose  > $filename2
   print "#### "
   print "---# CheckDesign Result: $filename1"
   print "---# CheckTiming Result: $filename2"
   print "#### "
   
}


proc amsUserGrid {} {
   ##--- Set user grids
   setPreference ConstraintUserXGrid 0.1
   setPreference ConstraintUserXOffset 0.1
   setPreference ConstraintUserYGrid 0.1
   setPreference ConstraintUserYOffset 0.1
   setPreference SnapAllCorners 1
   setPreference BlockSnapRule 2

   snapFPlanIO -usergrid
}

proc amsGlobalConnect type {
   ##--- Define global power connects
   switch $type {
      "core" {
               set globalNetsList {{vdd! vdd!} {gnd! gnd!}}
               ##--- Define global Power nets - make global connections
             }
      "both" {
               ##--- Define global Power nets - make global connections
               clearGlobalNets
               set globalNetsList {{vdd! vdd!} {gnd! gnd!}}
               set globalNetsList [lappend globalNetsList {vdd3r1! vdd3r1!} {vdd3r2! vdd3r2!} {vdd3o! vdd3o!} {gnd3r! gnd3r!} {gnd3o! gnd3o!}]
             }
     }
     clearGlobalNets
     foreach net $globalNetsList {
        set n [lindex $net 0]
        set p [lindex $net 1]
        globalNetConnect $n -type pgpin -pin $p -inst * -module {}
        print "---# GlobalConnect all $p pins to net $n"
     }
}


proc amsSetAnalysisView {cond consList} {
    
    switch $cond {
      "typ"    { 
                 set viewList {}
                 foreach cons $consList {
		    set avname [format "%s_typ" $cons]
                    set viewList [lappend viewList $avname]
                 }
                 set_analysis_view -setup $viewList -hold $viewList
	       } 
      "minmax" { 
		 set maxviewList {}
		 set minviewList {}
                 foreach cons $consList {
		    set maxavname [format "%s_max" $cons]
                    set maxviewList [lappend maxviewList $maxavname]
		    set minavname [format "%s_min" $cons]
                    set minviewList [lappend minviewList $minavname]
                 }
                 set_analysis_view -setup $maxviewList -hold $minviewList
	       } 
      "min"    { 
                 set viewList {}
                 foreach cons $consList {
		    set avname [format "%s_min" $cons]
                    set viewList [lappend viewList $avname]
                 }
		 set_analysis_view -setup $viewList -hold $viewList
	       } 
      "max"    { 
                 set viewList {}
                 foreach cons $consList {
		    set avname [format "%s_max" $cons]
                    set viewList [lappend viewList $avname]
                 }
		 set_analysis_view -setup $viewList -hold $viewList
	       } 
      }
}


proc amsAddEndCaps {} {
   ##-- add CAP cells
   addEndCap -preCap ENDCAPL -postCap ENDCAPR -prefix ENDCAP
}


proc amsFillcore {} {
   ##-- Add Core Filler cells
   addFiller -cell FILL25 FILL10 FILL5 FILL2 -prefix FILLER
   addFiller -cell FILLRT25 FILLRT10 FILLRT5 FILLRT2 FILLRT1 -prefix FILLERRT
}

proc amsFillperi {} {
   ##-- Add Peri Filler cells
   set fillerList {100_P 50_P 20_P 10_P 5_P 2_P 1_P 01_P}
   foreach fillcell $fillerList {
      addIoFiller -cell PERI_SPACER_$fillcell -prefix pfill
   }
}

proc amsRoute {{router wroute}} {
    switch $router {
      "nano" { 
               ##-- Run Routing
               ##-- Nano-Route
               setMaxRouteLayer 4
               routeDesign -globalDetail
             }
      "nanodcv" { 
               ##-- Run Routing
               ##-- Nano-Route using double-cut vias
               setMaxRouteLayer  4
	              setNanoRouteMode -routeUseMultiCutViaEffort high
               setNanoRouteMode -routeReserveSpaceForMultiCut true
               routeDesign
               setNanoRouteMode -routeWithTimingDriven false
               setNanoRouteMode -droutePostRouteSwapVia mulitCut
               #setNanoRouteMode -dbViaWeight "VIA1_HC 10, VIA1_VC 10, VIA2_HC 10, VIA2_VC 10, VIA1_D* 10, VIA2_D* 10, VIA1_PR 1, VIA2_PR 1"
               routeDesign -viaOpt
             }
    "wroute" {
               ##-- WROUTE
             wroute -topLayerLimit 4
             }
    "wroutedcv" {
             ##-- WROUTE using double-cut vias
             wroute -topLayerLimit 4 -optimizeMode viasOnlyDuring
             }
    "wroute2" {
               ##-- WROUTE
             wroute -topLayerLimit 4 -multiCpu 2
             }
     }
}

proc amsSave postfix {
   global topcellname
   global dbdir
   set filename [format "%s/%s_%s.enc" $dbdir $topcellname $postfix]
   saveDesign $filename
}

proc amsSaveOA {libname {viewname routed}} {
   global topcellname
   saveDesign -cellview {$libname $topcellname $viewname}
   print "---#     Saved as OA: $libname $topcellname $viewname\n"
}

proc amsWrite {postfix {dir .}} {
   global topcellname

   if {$dir != "."} {
      set dir [format "FINALDATA/%s" $dir]
      system mkdir $dir
   }

   ##-- Save Design
   amsSave $postfix
   ##-- Write DEF
   set filename_def [format "%s/%s_%s.def" $dir $topcellname $postfix]
   defOut -floorplan -netlist -routing $filename_def
   ##-- Write GDS2
   set filename_gds [format "%s/%s_%s_fe.gds" $dir $topcellname $postfix]
   streamOut $filename_gds -mapFile gds2.map -libName DesignLib -structureName $topcellname \
         -attachInstanceName 13 -attachNetName 13 -stripes 1 -units 1000 -mode ALL

   ##-- Write port file
   set filename_ports [format "%s/%s.ports" $dir $topcellname]
   amsPortList $filename_ports

   ##-- Verilog Netlist
   set filename_vnl [format "%s/%s_%s.v" $dir $topcellname $postfix]
   saveNetlist $filename_vnl
   ##-- Verilog Netlist with FILLCAP cells
   set filename_vnl2 [format "%s/%s_%s_fillcap.v" $dir $topcellname $postfix]
   saveNetlist $filename_vnl2 -excludeLeafCell -includePhysicalInst \
                         -excludeCellInst { FILLRT1 FILLRT2 FILLRT5 FILLRT10 FILLRT25 FILL1 ENDCAPL ENDCAPR ENDCAP \
                                            PERI_SPACER_100_P PERI_SPACER_50_P PERI_SPACER_20_P PERI_SPACER_10_P PERI_SPACER_5_P PERI_SPACER_2_P PERI_SPACER_1_P PERI_SPACER_01_P CORNERP \
                                          }

   ##-- Extract detail parasitics
   setExtractRCMode -engine postRoute -effortLevel low
   extractRC
   set filename_spef1 [format "%s/%s_%s.spef" $dir $topcellname $postfix]
   rcOut -spef $filename_spef1
   
   ##-- run QRC extraction
   setExtractRCMode -engine postRoute -effortLevel signoff 
   extractRC 
   set filename_spef2 [format "%s/%s_%s_qrc.spef" $dir $topcellname $postfix]
   rcOut -spef $filename_spef2

   print "####    Saved data\n"
   print "---# Save directory: $dir"
   print "---# DEF           : $filename_def"
   print "---# GDSII         : $filename_gds"
   print "---# VerilogNL     : $filename_vnl"
   print "---# VerilogNL     : $filename_vnl2 (includes FILLCAPs)"
   print "---# Encounter SPEF: $filename_spef1"
   print "---# QRC SPEF      : $filename_spef2"
   print "---# Port List     : $filename_ports"
   print "#### \n"
}


##--  write SDF for a specific analysis view
proc amsWriteSDF4View {viewList} {
   global topcellname

   set sdfver 2.1

   foreach view $viewList {
      set filename [format "SDF/%s_%s.sdf" $topcellname $view]
      print "---# Analysis View: $view\n"

      switch $sdfver {
         "2.1"  { write_sdf -version 2.1 -prec 3 -edges check_edge -average_typ_delays \
                     -remashold -splitrecrem -splitsetuphold -force_calculation \
                     -view $view $filename
                }
         "3.0"  { write_sdf -version 3.0 -prec 3 -edges check_edge \
                     -force_calculation -average_typ_delays \
                     -view $view $filename
         ##-- additional for verilog XL: -splitrecrem
                }
      }
      print "---# Created SDF: $filename\n" 
   }
}

##--  write SDF for a specific analysis view
proc amsWriteSDFbtw {minview typview maxview} {
   global topcellname

   set sdfver 2.1

   set filename [format "SDF/%s_all.sdf" $topcellname]

   switch $sdfver {
         "2.1"  { write_sdf -version 2.1 -prec 3 -edges check_edge -average_typ_delays \
                     -remashold -splitrecrem -splitsetuphold -force_calculation \
                     -min_view $minview -typ_view $typview -max_view $maxview $filename
                }
         "3.0"  { write_sdf -version 3.0 -prec 3 -edges check_edge \
                     -force_calculation -average_typ_delays \
                     -min_view $minview -typ_view $typview -max_view $maxview $filename
         ##-- additional for verilog XL: -splitrecrem
                }
   }
      print "---# Created SDF: $filename\n"
}

##-- Other usefule procedures

proc amsZoomTo {x y {factor 10}} {
   set llx [expr {$x - $factor}]
   set lly [expr {$y - $factor}]
   set urx [expr {$x + $factor}]
   set ury [expr {$y + $factor}]
   zoomBox $llx $lly $urx $ury
}
##-- End of First Encounter TCL command file

proc protoSDF {} {
    amsDbSetup
    amsSetMMMC
    amsSetAnalysisView minmax {func}
    floorplan -r 1.0 0.8 2 2 2 2
    setPlaceMode -fp true -timingDriven false -reorderScan false -doCongOpt false -modulePlan false
    placeDesign -noPrePlaceOpt
    trialRoute -maxRouteLayer 4 -floorplanMode
    extractRC
    amsWriteSDF4View {func_max func_min}
}


proc amsFloorplan {type util iodist {ratio 1.0} {rowdist -1}} {
  ##-- rowdistance - used with thick3M or 2M process
  ##-- Initialize floorplan
  switch $type {
     "core" {
              floorPlan -r $ratio $util $iodist $iodist $iodist $iodist
            }
     "peri" {
              floorPlan -r $ratio $util $iodist $iodist $iodist $iodist
              ##--- Load corner io file to add corner cells (if necessary)
              loadIoFile corners.io
              floorPlan -r $ratio $util $iodist $iodist $iodist $iodist

              ##-- Snap IO cells to user grid
              snapFPlanIO -usergrid
            }
  }
  ##-- Place Macros 
  ##-- Create Placement Blockages
  ##createObstruct llx lly urx ury 
  ##-- Cut Rows under Macros, Halos and Blockages
  ##cutCoreRow
  fit
}

proc amsPowerRoute {{pownetsList {}}} {
   set offset 0.8
   set spacing 0.8
   # foreach power net in the specified list
   # route a ring
   foreach pownet $pownetsList {
      set name [lindex $pownet 0]
      set width [lindex $pownet 1]
      print "----$name $width $offset----"
      set lay_bt  "MET1"
      set lay_lr  "MET2"
      addRing \
           -layer {bottom MET1 top MET1 right MET2 left MET2} -width $width -spacing $spacing -offset $offset \
	          -around core \
	          -jog_distance 0.7 \
	          -threshold 0.7 \
	          -nets $name
      set offset [ expr $offset + $spacing + $width]
   }
   # do followpin routing
   sroute -connect { blockPin padPin corePin } \
	                                     -nets {vdd! gnd!}
}


proc amsTa {state} {

    global topcellname
    switch $state {
         "prePlace"  { timeDesign -prePlace -outDir timingReports -expandedViews }
         "preCTS"    { timeDesign -preCTS   -outDir timingReports -expandedViews }
         "postCTS"   { timeDesign -postCTS  -outDir timingReports -expandedViews
                       timeDesign -postCTS -hold -outDir timingReports -expandedViews
                     }
         "postRoute" { timeDesign -postRoute -outDir timingReports -expandedViews
                       timeDesign -postRoute -hold -outDir timingReports -expandedViews
                     }
         "signOff"   { timeDesign -signOff -outDir timingReports -expandedViews
                       timeDesign -signOff -hold -outDir timingReports -expandedViews
                     }
    }
}


proc amsPlace how {
   ##-- Placement
   switch $how {
      "ntd"   { 
                 setPlaceMode -timingdriven false -reorderScan false -congEffort medium \
                              -modulePlan false
                 placeDesign -noPrePlaceOpt
              }
      "td"    { 
                 setPlaceMode -timingdriven true -reorderScan false -congEffort medium \
                              -modulePlan false
                 placeDesign -noPrePlaceOpt
              }
      "opt"   {
                 setPlaceMode -timingdriven true -reorderScan true -congEffort high \
                               -modulePlan true
                 placeDesign -prePlaceOpt
              }
   }
   amsSave placed

}

proc amsCts {} {
   global topcellname
   set filename [format "CONSTRAINTS/%s.ctstch" $topcellname]
   cleanupSpecifyClockTree
   ##-- Specify Clock tree
   specifyClockTree -file $filename

   ##-- delete existing buffers
   #deleteClockTree -clk  <clockroot>

   ##-- Run CTS
   clockDesign -specFile $filename -outDir clock_report -fixedInstBeforeCTS

   changeClockStatus -all -noFixedNetWires

   amsSave clkplaced
}

proc amsCcopt {} {
   set_ccopt_mode -integration native
   set_ccopt_mode -cts_target_slew 1.0
   set_ccopt_mode -cts_target_nonleaf_slew 2.0
   setLimitedAccessFeature ccopt_native_cts 1
   set_ccopt_property buffer_cells {CLKBUFX*}
   set_ccopt_property inverter_cells {CLKINVX*}
   ##-- Create Clock Tree Spec inMemory
   create_ccopt_clock_tree_spec -immediate
   ##-- Create Clock Tree Spec File and load this file
   #create_ccopt_clock_tree_spec -file ccopt.spec
   #source ccopt.spec
   setCTSMode -routeBottomPreferredLayer MET1 -routeLeafBottomPreferredLayer MET1 \
              -routeLeafTopPreferredLayer MET4 -routeTopPreferredLayer MET4
   #set_ccopt_mode -modify_clock_latency false
   ##-- Ignore a clock from SDC during CTS
   #set_ccopt_property opt_ignore -clock_tree <clkname> true
   #set_ccopt_property target_insertion_delay <value>
   
   ccopt_design -cts
   
   report_ccopt_clock_trees -file ccopt_postCTS.report
   report_ccopt_skew_groups -file ccopt_postCTS_skew.report
   
}
   
proc amsUnfixClockNets {} { 
   set fixedNetsCnt 0
   set fixedWireCnt 0
   set fixedViaCnt 0
   foreach net [dbget top.nets] {
      set fixedNet 0
      if {[dbget $net.isClock] == 1 } {
         foreach wire [dbget $net.wires] {
            if {[dbget $wire.status] == "fixed"} {
               set fixedNet 1
               set fixedWireCnt [expr $fixedWireCnt + 1]
               dbSet $wire.status routed
            }
         }
         foreach via [dbget $net.vias] {
            if {[dbget $via.status] == "fixed"} {
               set fixedNet 1
               set fixedViaCnt [expr $fixedViaCnt + 1]
               dbSet $via.status routed
            }
         }
         if {$fixedNet == 1} {
            set fixedNetsCnt [expr $fixedNetsCnt + 1]
         }
      }
   }
   puts "---# $fixedNetsCnt Clock Nets unfixed!"
   puts "---# $fixedWireCnt Clock Wires and $fixedViaCnt Vias unfixed!"
}

proc amsIncrRoute {maxerror} {
  set fehler  1000
  set filename [getLogFileName]
  clearDrc
  set step 0
  set lastfehler 1000 
  while {$fehler > $maxerror} {
     if { $step < 4 } {
	       print "---# amsIncrRoute : start in incrFinal Mode ($step)"
        wroute -mode incrFinal -topLayerLimit 3
     } else {
	       print "---# amsIncrRoute : start in incrGlobalAndFinal Mode ($step)"
        wroute -mode incrGlobalAndFinal -topLayerLimit 3
	       set step 0
     }
     set chan [open $filename]
     while {[gets $chan line] >= 0} {
         if {[scan $line "Total number of violations           =        %d" f] == 1} {
            set fehler $f
         }
     }
     if {$fehler > $lastfehler} {
	       set step [expr $step + 1]
     } else {
        set step 0
        set lastfehler $fehler
	       amsSave routedIncr
     }
     close $chan
     if {$fehler > $maxerror} { 
        print "---# Still $fehler errors - starting wroute again"
     } else { 
        print "---# amsIncrRroute stopped with $fehler errors"
     }
  }
}

proc amsDefIn { defFile {rowtype "standard"} {l 2} {t 2} {r 2} {b 2} {addwidth 0} {addheight 0}} {
  
  global topcellname

  # open DEF File
  # find diearea
  set chan [open $defFile]
  while {[gets $chan line] >= 0} {
     # units for dividing coordinates
     if {[scan $line " UNITS DISTANCE MICRONS %d" u] == 1} {
            set units $u
	    print "---# DEF Units: $units"
     }
     # diearea 
     if {[scan $line " DIEAREA ( %f %f ) ( %f %f )" x1 y1 x2 y2] == 4} {
         set llx [expr ($x1 / $units)]
	 set lly [expr $y1 / $units]
	 set urx [expr $x2 / $units]
	 set ury [expr $y2 / $units]
	 print "---# DEF DieArea: $llx:$lly/$urx:$ury"
     }
  }
  close $chan
  # calculate core area for rows
  set llxc [expr $llx + $l]
  set llyc [expr $lly + $b]
  set urxc [expr $urx - $r]
  set uryc [expr $ury - $t]
  #floorPlan -b $llx $lly $urx $ury 
  floorPlan -site $rowtype -b $llx $lly $urx $ury \
                                   $llx $lly $urx $ury \
                                   $llxc $llyc $urxc $uryc
  # load def file
  defIn $defFile


  # if the die size should be changed
  if {$addwidth != 0 || $addheight != 0} {
     print "---# Adding width: $addwidth"
     print "---# Adding height: $addheight"
     # write IO-File to get a pin locations file
     set filename [format "%s_save.io" $topcellname]
     saveIoFile -locations $filename

     # new die sizes
     set llx [expr $x1 / $units]
     set lly [expr $y1 / $units]
     set urx [expr ($x2 / $units) + $addwidth]
     set ury [expr ($y2 / $units) + $addheight]
     set llxc [expr $llx + $l]
     set llyc [expr $lly + $b]
     set urxc [expr $urx - $r]
     set uryc [expr $ury - $t]
     floorPlan -site $rowtype -b $llx $lly $urx $ury \
                                 $llx $lly $urx $ury \
                                 $llxc $llyc $urxc $uryc
     # load pin positions
     loadIoFile $filename
 
  }

}

proc amsPortList {filename} {
  print "---# Write PinList to File: $filename"
  deselectAll
  selectIOPin *
  reportSelect
  deselectAll
  print "---# End Write PinList"
  print "---# Writing Ports to File now: $filename"

  set logFile [getLogFileName]


  set pins 0
  set chan [open $logFile]
  while {[gets $chan line] >= 0} {
     if {[regexp "<CMD" $line] != 1 &&[regexp "^---# Write PinList to File" $line] == 1} {
        set pins 1
        set ochan [open $filename w]
        set nrofpins 0
     }
     if {$pins == 1} {
       if {[scan $line " Name : %s " n] == 1} {
         set pinname $n
       }
       if {[scan $line " Layer : %s " l] == 1} {
         set pinlayer $l
       }
       if {[scan $line " Location : %f %f " x y] == 2} {
         set xCoord $x
         set yCoord $y
         puts $ochan "$pinname $pinlayer $xCoord $yCoord"
         incr nrofpins
       }
     }
     if {[regexp "<CMD" $line] != 1 && [regexp "^---# End Write PinList" $line] == 1} {
        set pins 0
        close $ochan
     }
  }
  print "---# $nrofpins Ports found"

}


proc amsStat projname {
   global topcellname

   set statdir [format "%s_%s_stat" $projname $topcellname]
   print "####"
   print "---# Creating Statistics in directory $statdir";
   system mkdir -p $statdir
   print "---#    Directory $statdir created";
   print "---#    running defStat.pl -> $statdir/$statdir.txt";
   defOut -floorplan -netlist -routing $statdir/$topcellname.def
   system defStatv2.pl -d $statdir/$topcellname.def \
                       -p $projname \
                       -t c35b4 \
                       /opt/cad/designkits/ams/v410/cds/HK_C35/LEF/c35b4/CORELIB.lef \
                       /opt/cad/designkits/ams/v410/cds/HK_C35/LEF/c35b4/IOLIB_4M.lef \
		              ./LEF/*.lef > $statdir/$statdir.txt
   system mv bar.html $statdir
   print "---#    Creating Screen Dump $statdir/$topcellname.gif";
   fit
   dumpToGIF $statdir/$topcellname.gif
   print "---#    Creating Wire Statistics $statdir/$topcellname.wires";
   reportWire -detail $statdir/$topcellname.wires
   print "---# Finished";
   print "####"

}

proc removeTmpoalibs {} {
   print "---# Remove tmo_oa_db... libs from cds.lib"
   system mv cds.lib cds.lib.bck
   system grep -v tmp_oa_db cds.lib.bck > cds.lib
}

proc amsOptDesign {dstep} {
   timeDesign -$dstep 
   print "---# Should Setup optmization run (Y/N):"
   set eini [gets stdin]
   if { $eini == "y" || $eini == "Y"} {
      print "---# Running optDesign -$dstep"
      optDesign -$dstep
   }
   print "---# Continue with hold check (Y/N):"
   set goon [gets stdin]

   if {$goon == "y" || $goon == "Y"} {
      timeDesign -$dstep -hold
      print "---# Should Hold optmization run (Y/N):"
      set eini [gets stdin]
      if { $eini == "y" || $eini == "Y"} {
         print "---# Running optDesign -$dstep -hold"
         optDesign -$dstep -hold
      }
   }
   print "---# Continue WC-Hold Check (Y/N):"
   set goon [gets stdin]

   if {$goon == "y" || $goon == "Y"} {
      # check hold in WC
      print "---# Change analysis views for TYP-WC check"
      amsSetAnalysisView max {func}
      timeDesign -$dstep -hold
      print "---# Should Hold optmization run (Y/N):"
      set eini [gets stdin]
      if { $eini == "y" || $eini == "Y"} {
         print "---# Running optDesign -$dstep -hold"
         optDesign -$dstep -hold
      }
   }

   print "---# Continue with changing back to minmax Analysis (Y/N):"
   set goon [gets stdin]

   if {$goon == "y" || $goon == "Y"} {
      print "---# Change analysis views for mimax check"
      amsSetAnalysisView minmax {func}
   }
}
proc amsWriteSDF3 {} {
 #  setDelayCalMode -engine aae
 #  setAnalysisMode -cppr none -clockGatingCheck 1 \
 #                -timeBorrowing 1 -useOutputPinCap 1 \
	#	   -sequentialConstProp 0 -timingSelfLoopsNoSkew 0 \
	#	   -enableMultipleDriveNet 1 -clkSrcPath 1 \
	#	   -warn 1 -usefulSkew 0 \
	#	   -analysisType onChipVariation \
	#	   -log 1

   amsSetAnalysisView max {func}
   timeDesign -signOff
   timeDesign -signOff -hold
   amsWriteSDF4View {func_max}

   amsSetAnalysisView typ {func}
   timeDesign -signOff
   timeDesign -signOff -hold
   amsWriteSDF4View {func_typ}

   amsSetAnalysisView min {func}
   timeDesign -signOff
   timeDesign -signOff -hold
   amsWriteSDF4View {func_min}

   amsSetAnalysisView minmax {func}
}

  print "---# TCL Script amsSetup.tcl loaded"
##-- End of First Encounter TCL command file

