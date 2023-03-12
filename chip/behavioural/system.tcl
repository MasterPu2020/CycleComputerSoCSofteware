
# system.tcl

database -open waves.shm -default

simvision {

  source /opt/cad/bim/fcde/tcl/routines.tcl
  source /opt/cad/bim/fcde/tcl/read_fig.tcl

  ecsWaves  {
    system.Clock
    system.nReset
    system.mode_index
    system.ahb_addr
    system.write_data
    system.write
    system.sel_timer
    system.data_timer
    system.sel_segment
    system.data_segment
    system.sel_sensor
    system.data_sensor
    system.sel_button
    system.data_button
    system.sel_oled
    system.data_oled
    system.nMode
    system.nTrip
    system.nFork
    system.nCrank
    system.SegA
    system.SegB
    system.SegC
    system.SegD
    system.SegE
    system.SegF
    system.SegG
    system.DP
    system.nDigit
    } "Waves for Any Cycle Computer Design"


}

# =========================================================================
# Probe

  # Any signals included in register window but not in waveform window
  # should be probed

# =========================================================================
