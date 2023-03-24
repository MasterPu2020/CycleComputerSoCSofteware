proc snap_ams_pads {} {

# This procedure snaps the pad cells initially to the 0.1 um grid
# and then adjusts pad-to-pad gaps so that they are multiples of 1.0 micron

# set constant for pad height
   set pad_height 340.4

# Snap the pad cells to the 0.1 um grid
   amsUserGrid


# Now ensure the spaces between cells are multiples of 1.0 micron
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

}
