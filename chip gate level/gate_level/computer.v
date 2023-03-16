/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : K-2015.06-SP5
// Date      : Thu Mar 16 00:27:36 2023
/////////////////////////////////////////////////////////////


module computer ( nMode, DnC, ScanEnable, nReset, nDigit, SDI, Test, SDIN, 
        nCrank, SegF, SCLK, DP, SegC, SegE, nCS, SegD, nTrip, SegA, SDO, SegB, 
        nFork, Clock, SegG );
  output [3:0] nDigit;
  input nMode, ScanEnable, nReset, SDI, Test, nCrank, nTrip, nFork, Clock;
  output DnC, SDIN, SegF, SCLK, DP, SegC, SegE, nCS, SegD, SegA, SDO, SegB,
         SegG;
  wire   CORE_SDI, CORE_SDO, CORE_nMode, CORE_nTrip, CORE_nFork, CORE_nCrank,
         CORE_SegF, CORE_SegG, CORE_DP, CORE_Clock, CORE_SegA, CORE_SegB,
         CORE_SegC, CORE_SegD, CORE_SegE, CORE_nReset, CORE_SCLK, CORE_nCS,
         CORE_DnC, CORE_SDIN, CORE_Test, CORE_ScanEnable, n1, n2;
  wire   [3:0] CORE_nDigit;

  ICP PAD_SDI ( .PAD(SDI), .Y(CORE_SDI) );
  BU8P PAD_SDO ( .A(CORE_SDO), .PAD(SDO) );
  ICP PAD_nMode ( .PAD(nMode), .Y(CORE_nMode) );
  ICP PAD_nTrip ( .PAD(nTrip), .Y(CORE_nTrip) );
  ICP PAD_nFork ( .PAD(nFork), .Y(CORE_nFork) );
  ICP PAD_nCrank ( .PAD(nCrank), .Y(CORE_nCrank) );
  BU8P PAD_SegF ( .A(CORE_SegF), .PAD(SegF) );
  BU8P PAD_SegG ( .A(CORE_SegG), .PAD(SegG) );
  BU8P PAD_DP ( .A(CORE_DP), .PAD(DP) );
  BU8P PAD_nDigit_0 ( .A(CORE_nDigit[0]), .PAD(nDigit[0]) );
  BU8P PAD_nDigit_1 ( .A(CORE_nDigit[1]), .PAD(nDigit[1]) );
  BU8P PAD_nDigit_2 ( .A(CORE_nDigit[2]), .PAD(nDigit[2]) );
  BU8P PAD_nDigit_3 ( .A(CORE_nDigit[3]), .PAD(nDigit[3]) );
  ICP PAD_Clock ( .PAD(Clock), .Y(CORE_Clock) );
  BU8P PAD_SegA ( .A(CORE_SegA), .PAD(SegA) );
  BU8P PAD_SegB ( .A(CORE_SegB), .PAD(SegB) );
  BU8P PAD_SegC ( .A(CORE_SegC), .PAD(SegC) );
  BU8P PAD_SegD ( .A(CORE_SegD), .PAD(SegD) );
  BU8P PAD_SegE ( .A(CORE_SegE), .PAD(SegE) );
  ICP PAD_nReset ( .PAD(nReset), .Y(CORE_nReset) );
  BU8P PAD_SCLK ( .A(CORE_SCLK), .PAD(SCLK) );
  BU8P PAD_nCS ( .A(CORE_nCS), .PAD(nCS) );
  BU8P PAD_DnC ( .A(CORE_DnC), .PAD(DnC) );
  BU8P PAD_SDIN ( .A(CORE_SDIN), .PAD(SDIN) );
  ICP PAD_Test ( .PAD(Test), .Y(CORE_Test) );
  ICP PAD_ScanEnable ( .PAD(ScanEnable), .Y(CORE_ScanEnable) );
  DFC1 RESET_SYNC_FF1 ( .D(n1), .C(CORE_Clock), .RN(n2) );
  DFC1 RESET_SYNC_FF2 ( .D(n1), .C(CORE_Clock), .RN(n2), .Q(CORE_nReset) );
  LOGIC1 U4 ( .Q(n1) );
  LOGIC0 U5 ( .Q(n2) );
  comp_core COMP_core ( .nMode(CORE_nMode), .DnC(CORE_DnC), .ScanEnable(
        CORE_ScanEnable), .nReset(CORE_nReset), .nDigit(CORE_nDigit), .SDI(
        CORE_SDI), .Test(CORE_Test), .SDIN(CORE_SDIN), .nCrank(CORE_nCrank), 
        .SegF(CORE_SegF), .SCLK(CORE_SCLK), .DP(CORE_DP), .SegC(CORE_SegC), 
        .SegE(CORE_SegE), .nCS(CORE_nCS), .SegD(CORE_SegD), .nTrip(CORE_nTrip), 
        .SegA(CORE_SegA), .SDO(CORE_SDO), .SegB(CORE_SegB), .nFork(CORE_nFork), 
        .Clock(CORE_Clock), .SegG(CORE_SegG) );
endmodule

