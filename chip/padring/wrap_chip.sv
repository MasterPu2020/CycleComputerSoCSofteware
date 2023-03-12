module wrap_chip (
  input nMode,
  output DnC,
  input ScanEnable,
  input nReset,
  output [3:0] nDigit,
  input SDI,
  input Test,
  output SDIN,
  output SegF,
  input nCrank,
  output SCLK,
  output DP,
  output SegC,
  output SegE,
  output SegD,
  output nCS,
  input nTrip,
  output SegA,
  input SDO,
  output SegB,
  input Clock,
  input nFork,
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
  wire CORE_SegF;
  wire CORE_nCrank;
  wire CORE_SCLK;
  wire CORE_DP;
  wire CORE_SegC;
  wire CORE_SegE;
  wire CORE_SegD;
  wire CORE_nCS;
  wire CORE_nTrip;
  wire CORE_SegA;
  wire CORE_SDO;
  wire CORE_SegB;
  wire CORE_Clock;
  wire CORE_nFork;
  wire CORE_SegG;

  ICP PAD_nFork ( .PAD(nFork), .Y(CORE_nFork) );
  ICP PAD_nCrank ( .PAD(nCrank), .Y(CORE_nCrank) );
  ICP PAD_SDI ( .PAD(SDI), .Y(CORE_SDI) );
  ICP PAD_Test ( .PAD(Test), .Y(CORE_Test) );
  ICP PAD_ScanEnable ( .PAD(ScanEnable), .Y(CORE_ScanEnable) );
  ICP PAD_nTrip ( .PAD(nTrip), .Y(CORE_nTrip) );
  ICP PAD_nMode ( .PAD(nMode), .Y(CORE_nMode) );
  ICCK2P PAD_Clock ( .PAD(Clock), .Y(CORE_Clock) );
  ICP PAD_nReset ( .PAD(nReset), .Y(CORE_nReset) );
  ICP PAD_SDO ( .PAD(SDO), .Y(CORE_SDO) );
  BU8P PAD_nCS ( .PAD(nCS), .A(CORE_nCS) );
  BU8P PAD_DnC ( .PAD(DnC), .A(CORE_DnC) );
  BU8P PAD_SDIN ( .PAD(SDIN), .A(CORE_SDIN) );
  BU8P PAD_SCLK ( .PAD(SCLK), .A(CORE_SCLK) );
  BU8P PAD_SegA ( .PAD(SegA), .A(CORE_SegA) );
  BU8P PAD_SegB ( .PAD(SegB), .A(CORE_SegB) );
  BU8P PAD_SegC ( .PAD(SegC), .A(CORE_SegC) );
  BU8P PAD_SegD ( .PAD(SegD), .A(CORE_SegD) );
  BU8P PAD_SegE ( .PAD(SegE), .A(CORE_SegE) );
  BU8P PAD_SegF ( .PAD(SegF), .A(CORE_SegF) );
  BU8P PAD_SegG ( .PAD(SegG), .A(CORE_SegG) );
  BU8P PAD_DP ( .PAD(DP), .A(CORE_DP) );
  BU8P PAD_nDigit_0 ( .PAD(nDigit[0]), .A(CORE_nDigit[0]) );
  BU8P PAD_nDigit_1 ( .PAD(nDigit[1]), .A(CORE_nDigit[1]) );
  BU8P PAD_nDigit_2 ( .PAD(nDigit[2]), .A(CORE_nDigit[2]) );
  BU8P PAD_nDigit_3 ( .PAD(nDigit[3]), .A(CORE_nDigit[3]) );

  chip core_inst (
    .nMode(CORE_nMode),
    .DnC(CORE_DnC),
    .ScanEnable(CORE_ScanEnable),
    .nReset(CORE_nReset),
    .nDigit(CORE_nDigit),
    .SDI(CORE_SDI),
    .Test(CORE_Test),
    .SDIN(CORE_SDIN),
    .SegF(CORE_SegF),
    .nCrank(CORE_nCrank),
    .SCLK(CORE_SCLK),
    .DP(CORE_DP),
    .SegC(CORE_SegC),
    .SegE(CORE_SegE),
    .SegD(CORE_SegD),
    .nCS(CORE_nCS),
    .nTrip(CORE_nTrip),
    .SegA(CORE_SegA),
    .SDO(CORE_SDO),
    .SegB(CORE_SegB),
    .Clock(CORE_Clock),
    .nFork(CORE_nFork),
    .SegG(CORE_SegG)
  );

endmodule
