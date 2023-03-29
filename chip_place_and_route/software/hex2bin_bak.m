%------------------------------------------------------------------------------
%   Title: Binary Code Conversion Matlab Script
%  Author: Paiyun Chen (Circle)
%    Team: C4 Chip Designed
% Version: General Purpose
%------------------------------------------------------------------------------
clear;
clc;

%------------------------------------------------------------------------------------
% Choose the conversion mode
% Comment: A mode variable value of 1 means that a hex file is converted to a bin file.
%          A mode variable value of 0 means that a vmem file is converted to a bin file.
%------------------------------------------------------------------------------------
Mode = 0;   %Hex2Bin = 1; Vmem2Bin = 0;

%------------------------------------------------------------------------------------
% Customize hex and bin file paths and names
%------------------------------------------------------------------------------------
HexFileLoc   = 'D:\Vscode_Code\ARM_SoC_Project\CycleComputerSoCSofteware\chip_place_and_route\software\';
HexFileName  = 'code.hex';
VmemFileLoc  = 'D:\Vscode_Code\ARM_SoC_Project\CycleComputerSoCSofteware\chip_place_and_route\software\';
VmemFileName = 'code.vmem';
BinFileLoc   = 'D:\Vscode_Code\ARM_SoC_Project\CycleComputerSoCSofteware\chip_place_and_route\software\';
BinFileName  = 'code1';

%------------------------------------------------------------------------------------
% Main Function
%------------------------------------------------------------------------------------
%------------------------------------------------------------------
% Read hex or vmem file
%------------------------------------------------------------------
IntFileConTxt = [];
RowNum = 0;

BinFileNameSeries = sprintf('%s%d%s',BinFileName,1,'.bin');
disp(BinFileNameSeries)
WFileID = fopen([BinFileLoc,BinFileNameSeries],'w','b');


if (Mode == 1)
  FileID = fopen([HexFileLoc, HexFileName],'r','b','UTF-8');
  if FileID == -1
    disp("Failed to open hex file.");
  else
    disp("Open hex file successfully.");
  end

  while ~feof(FileID)
    RowNum = RowNum + 1;
    HexFileCon = fgetl(FileID);
    BinFileCon = dec2bin(hex2dec(HexFileCon(6:14)));
    for i = 1:(32-length(BinFileCon))
      BinFileCon = sprintf('%d%s',0, BinFileCon);
    end
    IntFileConTxt = sprintf('%s%s',IntFileConTxt, BinFileCon);
  end
else
  FileID = fopen([VmemFileLoc, VmemFileName],'r','b','UTF-8');
  if FileID == -1
    disp("Failed to open vmem file.");
  else
    disp("Open vmem file successfully.");
  end

  while ~feof(FileID)
    RowNum = RowNum + 1;
    VmemFileCon = fgetl(FileID);
    if (RowNum == 1)
      VmemFileRealCon = VmemFileCon(28:35);
    else
      VmemFileRealCon = VmemFileCon((28 + fix(log10(RowNum - 1))) : (35 + fix(log10(RowNum - 1))));
    end
    
    % deal with uint data
    DecFileCon = hex2dec(VmemFileRealCon);
    IntFileCon = uint32(DecFileCon);
    fwrite(WFileID, IntFileCon, 'uint');
  end 
end


fclose(WFileID);