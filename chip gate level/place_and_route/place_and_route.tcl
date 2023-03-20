#prepare_edi wrap_dice place_and_route
#cd place_and_route
#delete those two files in the CONSTRAINTS folder
#ln -s ../../constraints/computer.sdc CONSTRAINTS/computer_func.sdc
#ln -s ../../constraints/computer.sdc CONSTRAINTS/computer_test.sdc

# set the io file name and boolean for scan path (these lines will need to be customised)

    set io_filename ../padring/computer.io
    set scan_path_included true

# load custom script

    source edi_custom_c35b4.tcl

# initialise the database (load in the design)

    amsDbSetup

# if your design supports one, specify a scan chain

    if { $scan_path_included } { specifyScanChain ScanChain0 -start SDI -stop SDO }

# timing setup

    amsSetMMMC
    amsSetAnalysisView minmax {func test}

# Place the pad cells (including corners and power)

    if { ! [file exists $io_filename] } {
      print "NO I/O FILE: $io_filename - GIVING UP"
      return
    }

    loadIoFile $io_filename

# view design in gui

    fit

# create some space for the power rings
# 60um spacing is plenty for 2x 20 um power rings

    floorPlan -r 1 0.7 60 60 60 60

# Snap the pad cells to the 0.1 um grid with spacing divisible by 1 um

    snap_ams_pads

# Snap the pad cells to the 0.1 um grid
   amsUserGrid


# Now ensure the spaces between cells are multiples of 1.0 umicron
   set pad_height 340.4
   set scale [dbGet head.dbUnits]
   set snap_grid [ expr int( 1.0 * $scale ) ]
   foreach pad [concat [dbGet -p2 top.insts.cell.baseClass pad] [dbGet -p2 top.insts.cell.baseClass corner] ] {
     set name [dbGet $pad.Name]
     set master [dbGet $pad.cell.Name]
     set orient [dbGet $pad.orient]
     set x [dbGet $pad.pt_x]
     set y [dbGet $pad.pt_y]
     if { $x != 0 } {
       set xint [ expr int( ($x - $pad_height) * $scale ) ]
       set xrem [ expr $xint % $snap_grid ]
       if { $xrem != 0 } {
         puts "Found off-grid instance (x): $name $master $x $y $orient"
         set newx [ expr ( double(( $xint / $snap_grid ) * $snap_grid) / $scale ) + $pad_height ]
         dbSet $pad.pt_x $newx
         puts "  x position corrected $x -> $newx"
         set x $newx
       }
     }
     if { $y != 0 } {
       set yint [ expr int( ($y - $pad_height) * $scale ) ]
       set yrem [ expr $yint % $snap_grid ]
       if { $yrem != 0 } {
         puts "Found off-grid instance (y): $name $master $x $y $orient"
         set newy [ expr ( double(( $yint / $snap_grid ) * $snap_grid) / $scale ) + $pad_height ]
         dbSet $pad.pt_y $newy
         puts "  y position corrected $y -> $newy"
         set y $newy
       }
     }
   }

# Add peripheral filler cells

    amsFillperi

# specify the connectivity of for the power nets

    amsGlobalConnect both

    globalNetConnect gnd! -type pgpin -pin A -inst CORE_GND_* -module {}
    globalNetConnect vdd! -type pgpin -pin A -inst CORE_VDD_* -module {}

# add the power rings (note a 20um ring is classed as "wide metal" - >10um)
# spacing of 2um is minimum for thick MET4

    addRing \
      -type core_rings \
      -nets {gnd! vdd!} \
      -center 1 \
      -layer {bottom MET3 top MET3 right MET4 left MET4} \
      -width 20 -spacing 2

# add power and ground routing (special route)

    sroute \
      -connect { blockPin padPin padRing corePin floatingStripe } \
      -layerChangeRange { MET1 MET4 } \
      -blockPinTarget { nearestTarget } \
      -padPinPortConnect { allPort oneGeom } \
      -padPinTarget { nearestTarget } \
      -corePinTarget { firstAfterRowEnd } \
      -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } \
      -allowJogging 1 \
      -crossoverViaLayerRange { MET1 MET4 } \
      -nets { vdd! gnd! } \
      -allowLayerChange 1 \
      -blockPin useLef \
      -targetViaLayerRange { MET1 MET4 }

# Check to see if there are problems with the floorplan (e.g. gaps between pad cells)

    verifyGeometry

    if { [get_metric -value verify.geom.total] != 0 } {
      print "FLOORPLAN GEOMETRY CHECK FAILED - GIVING UP"
      return
    }

# Save intermediate design

    saveDesign floorplan.enc

# -------------------
# to start again here type:   encounter -init floorplan.enc -win
# -------------------

# Placement

    setDrawView place

    placeDesign
    amsAddEndCaps

# Add Tiehi/Tielo cells

    setTieHiLoMode -cell {LOGIC1 LOGIC0} -maxFanout 10
    addTieHiLo

# Save intermediate design

    saveDesign placed.enc

# -------------------
# to start again here type:   encounter -init placed.enc -win
# -------------------

# Pre-CTS Optimisation

    optDesign -preCTS

# Check Timing

   timeDesign -preCTS

   if { [get_metric -value timing.setup.numViolatingPaths.all] != 0 } {
     print "PRECTS SETUP CHECK FAILED - GIVING UP"
     return
   }


# Clock Tree Synthesis

    setCTSMode -engine ck

    setCTSMode -traceDPinAsLeaf true -traceIOPinAsLeaf true

    createClockTreeSpec \
      -bufferList {CLKBU2 CLKBU4 CLKBU6 CLKBU8 CLKBU12 CLKBU15 CLKIN0 CLKIN1 CLKIN2 CLKIN3 CLKIN4 CLKIN6 CLKIN8 CLKIN10 CLKIN12 CLKIN15} \
      -routeClkNet -output CONSTRAINTS/clock.clk

    specifyClockTree -file CONSTRAINTS/clock.clk

    ckSynthesis

# Save intermediate design

    saveDesign inc_clock_tree.enc

# -------------------
# to start again here type:   encounter -init inc_clock_tree.enc -win
# -------------------

# Post-CTS - update constraints

    set_interactive_constraint_modes {func test}

# replace predicted latency and transition with actual values through clock tree

    set_propagated_clock [all_clocks]

# set jitter to 0.5 ns (clock skew is no longer important)

    set_clock_uncertainty -setup 0.5 [get_clocks master_clock]
    set_clock_uncertainty -hold 0.1 [get_clocks master_clock]

# Post-CTS Optimisation

    set_analysis_view -setup {func_max func_typ func_min} -hold {func_max func_typ func_min}

    optDesign -postCTS -hold

# Check Timing

   timeDesign -postCTS -hold

   if { [get_metric -value timing.setup.numViolatingPaths.all] != 0 } {
     print "POSTCTS SETUP CHECK FAILED - GIVING UP"
     return
   }

   if { [get_metric -value timing.hold.numViolatingPaths.all] != 0 } {
     print "POSTCTS HOLD CHECK FAILED - GIVING UP"
     return
   }


# route with nanoRoute

    routeDesign -globalDetail

# Post-route optimisation

    setDelayCalMode -engine default -siAware true
    setAnalysisMode -analysisType onChipVariation

    optDesign -postRoute -hold
    optDesign -postRoute
    optDesign -postRoute -drv

# Check Timing

   timeDesign -postRoute -hold

   if { [get_metric -value timing.setup.numViolatingPaths.all] != 0 } {
     print "POSTROUTE SETUP CHECK FAILED - GIVING UP"
     return
   }

   if { [get_metric -value timing.hold.numViolatingPaths.all] != 0 } {
     print "POSTROUTE HOLD CHECK FAILED - GIVING UP"
     return
   }


# Add core filler cells after optimisation as suggested by Michael Nydegger (but not by RAL)

    amsFillcore

# Verify connectivity and geometry

    verifyConnectivity

    if { [get_metric -value verify.conn] != 0 } {
      print "CONNECTIVITY CHECK FAILED - GIVING UP"
      return
    }

    verifyGeometry

    if { [get_metric -value verify.geom.total] != 0 } {
      print "GEOMETRY CHECK FAILED - GIVING UP"
      return
    }

# Get size of design

    set size [ dbGet top.fPlan.boxes ]
    print "CHIP SIZE IS $size"

# Save final design

    saveDesign routed.enc
    amsWrite final
    amsWriteSDF4View {func_max}

# -------------------
# to start again here type:   encounter -init routed.enc -win
# -------------------

    print "PLACE AND ROUTE COMPLETED"

    saveOaDesign Computer_Verification Computer_IO layout
