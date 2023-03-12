
# system.tcl

database -open waves.shm -default

simvision {

  source /opt/cad/bim/fcde/tcl/routines.tcl
  source /opt/cad/bim/fcde/tcl/read_fig.tcl

  ecsWaves  {
    system.Clock
    system.nReset
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
    system.mode_index
    } "Waves for Any Cycle Computer Design"


}

# =========================================================================
# Probe

  # Any signals included in register window but not in waveform window
  # should be probed

# =========================================================================
