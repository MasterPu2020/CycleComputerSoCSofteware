module computer (
  input nMode,
  output DnC,
  input ScanEnable,
  input nReset,
  output [3:0] nDigit,
  input SDI,
  input Test,
  output SDIN,
  input nCrank,
  output SegF,
  output SCLK,
  output DP,
  output SegC,
  output SegE,
  output nCS,
  output SegD,
  input nTrip,
  output SegA,
  output SDO,
  output SegB,
  input nFork,
  input Clock,
  output SegG
);

  wire CORE_nMode;
  wire CORE_DnC;
  wire CORE_ScanEnable;
  wire CORE_nReset;
  wire [3:0] CORE_nDigit;
  wire CORE_SDI;
  wire CORE_Test;
  wire CORE_SDIN;
  wire CORE_nCrank;
  wire CORE_SegF;
  wire CORE_SCLK;
  wire CORE_DP;
  wire CORE_SegC;
  wire CORE_SegE;
  wire CORE_nCS;
  wire CORE_SegD;
  wire CORE_nTrip;
  wire CORE_SegA;
  wire CORE_SDO;
  wire CORE_SegB;
  wire CORE_nFork;
  wire CORE_Clock;
  wire CORE_SegG;

  // synopsys dc_tcl_script_begin
  //   set_dont_touch [get_cells RESET_SYNC_FF*]
  // synopsys dc_tcl_script_end

  // Reset Synchronization
  wire SYNC_IN_nReset, SYNC_MID_nReset;
  DFC1 RESET_SYNC_FF1   ( .D('1),              .Q(SYNC_MID_nReset), .C(CORE_Clock), .RN(SYNC_IN_nReset));
  DFC1 RESET_SYNC_FF2   ( .D(SYNC_MID_nReset), .Q(CORE_nReset),     .C(CORE_Clock), .RN(SYNC_IN_nReset));

  // Input Synchronization
  wire SYNC_IN_nFork, SYNC_MID_nFork;
  DFP1 FORK_SYNC_FF1    ( .D(SYNC_IN_nFork),   .Q(SYNC_MID_nFork),  .C(CORE_Clock), .SN(CORE_nReset));
  DFP1 FORK_SYNC_FF2    ( .D(SYNC_MID_nFork),  .Q(CORE_nFork),      .C(CORE_Clock), .SN(CORE_nReset));

  wire SYNC_IN_nCrank, SYNC_MID_nCrank;
  DFP1 CRANK_SYNC_FF1   ( .D(SYNC_IN_nCrank),  .Q(SYNC_MID_nCrank), .C(CORE_Clock), .SN(CORE_nReset));
  DFP1 CRANK_SYNC_FF2   ( .D(SYNC_MID_nCrank), .Q(CORE_nCrank),     .C(CORE_Clock), .SN(CORE_nReset));

  wire SYNC_IN_nTrip, SYNC_MID_nTrip;
  DFP1 TRIP_SYNC_FF1    ( .D(SYNC_IN_nTrip),   .Q(SYNC_MID_nTrip),  .C(CORE_Clock), .SN(CORE_nReset));
  DFP1 TRIP_SYNC_FF2    ( .D(SYNC_MID_nTrip),  .Q(CORE_nTrip),      .C(CORE_Clock), .SN(CORE_nReset));
  
  wire SYNC_IN_nMode, SYNC_MID_nMode;
  DFP1 MODE_SYNC_FF1    ( .D(SYNC_IN_nMode),   .Q(SYNC_MID_nMode),  .C(CORE_Clock), .SN(CORE_nReset));
  DFP1 MODE_SYNC_FF2    ( .D(SYNC_MID_nMode),  .Q(CORE_nMode),      .C(CORE_Clock), .SN(CORE_nReset));

  // Pad
  ICP PAD_SDI ( .PAD(SDI), .Y(CORE_SDI) );
  BU8P PAD_SDO ( .PAD(SDO), .A(CORE_SDO) );
  ICUP PAD_nMode ( .PAD(nMode), .Y(SYNC_IN_nMode) );
  ICUP PAD_nTrip ( .PAD(nTrip), .Y(SYNC_IN_nTrip) );
  ICUP PAD_nFork ( .PAD(nFork), .Y(SYNC_IN_nFork) );
  ICUP PAD_nCrank ( .PAD(nCrank), .Y(SYNC_IN_nCrank) );
  BU8P PAD_SegF ( .PAD(SegF), .A(CORE_SegF) );
  BU8P PAD_SegG ( .PAD(SegG), .A(CORE_SegG) );
  BU8P PAD_DP ( .PAD(DP), .A(CORE_DP) );
  BU8P PAD_nDigit_0 ( .PAD(nDigit[0]), .A(CORE_nDigit[0]) );
  BU8P PAD_nDigit_1 ( .PAD(nDigit[1]), .A(CORE_nDigit[1]) );
  BU8P PAD_nDigit_2 ( .PAD(nDigit[2]), .A(CORE_nDigit[2]) );
  BU8P PAD_nDigit_3 ( .PAD(nDigit[3]), .A(CORE_nDigit[3]) );
  BU8P PAD_SegA ( .PAD(SegA), .A(CORE_SegA) );
  ICCK2P PAD_Clock ( .PAD(Clock), .Y(CORE_Clock) );
  BU8P PAD_SegB ( .PAD(SegB), .A(CORE_SegB) );
  BU8P PAD_SegC ( .PAD(SegC), .A(CORE_SegC) );
  BU8P PAD_SegD ( .PAD(SegD), .A(CORE_SegD) );
  BU8P PAD_SegE ( .PAD(SegE), .A(CORE_SegE) );
  ICP PAD_nReset ( .PAD(nReset), .Y(SYNC_IN_nReset) );
  BU8P PAD_SCLK ( .PAD(SCLK), .A(CORE_SCLK) );
  BU8P PAD_nCS ( .PAD(nCS), .A(CORE_nCS) );
  BU8P PAD_DnC ( .PAD(DnC), .A(CORE_DnC) );
  BU8P PAD_SDIN ( .PAD(SDIN), .A(CORE_SDIN) );
  ICP PAD_Test ( .PAD(Test), .Y(CORE_Test) );
  ICP PAD_ScanEnable ( .PAD(ScanEnable), .Y(CORE_ScanEnable) );

  comp_core COMP_core (
    .nMode(CORE_nMode),
    .DnC(CORE_DnC),
    // .ScanEnable(CORE_ScanEnable),
    .nReset(CORE_nReset),
    .nDigit(CORE_nDigit),
    // .SDI(CORE_SDI),
    // .Test(CORE_Test),
    .SDIN(CORE_SDIN),
    .nCrank(CORE_nCrank),
    .SegF(CORE_SegF),
    .SCLK(CORE_SCLK),
    .DP(CORE_DP),
    .SegC(CORE_SegC),
    .SegE(CORE_SegE),
    .nCS(CORE_nCS),
    .SegD(CORE_SegD),
    .nTrip(CORE_nTrip),
    .SegA(CORE_SegA),
    // .SDO(CORE_SDO),
    .SegB(CORE_SegB),
    .nFork(CORE_nFork),
    .Clock(CORE_Clock),
    .SegG(CORE_SegG)
  );

endmodule
