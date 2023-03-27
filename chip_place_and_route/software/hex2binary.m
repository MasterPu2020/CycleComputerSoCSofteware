%------------------------------------------------------------------------------
%   Title: Binary Code Conversion Matlab Script
%  Author: Paiyun Chen (Circle)
%    Team: C4 Chip Designed
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
BinFileName  = 'code';

%------------------------------------------------------------------------------------
% Main Function
%------------------------------------------------------------------------------------
IntFileConTxt = [];
RowNum = 0;

%------------------------------------------------------------------
% Read hex file
%------------------------------------------------------------------
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

%------------------------------------------------------------------
% Read vmem file
%------------------------------------------------------------------
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

    BinFileCon = dec2bin(hex2dec(VmemFileRealCon));

    for i = 1:(32-length(BinFileCon))
      BinFileCon = sprintf('%d%s',0, BinFileCon);
    end
    IntFileConTxt = sprintf('%s%s',IntFileConTxt, BinFileCon);
  end
end

fclose(FileID);

%------------------------------------------------------------------
% Write bin file(s)
%------------------------------------------------------------------
BinFileNum = ceil(RowNum/512);
RowNumWritten = 0;

for n = 1:ceil(BinFileNum)
  BinFileNameSeries = sprintf('%s%d%s',BinFileName,n,'.bin');
  FileID = fopen([BinFileLoc,BinFileNameSeries],'w','b');

  for m = 1:512
    if (RowNumWritten < RowNum)
      for l = 1:32
        WrittingConTxt = IntFileConTxt(l + 32*(RowNumWritten));
        WrittingConBin = fix(str2double(WrittingConTxt));
        fwrite(FileID, WrittingConBin);
      end
    else
      for l = 1:32
        fwrite(FileID, 0);
      end
    end
    fprintf(FileID, '\n');
    RowNumWritten = m + 512*(n-1);
  end
  fclose(FileID);
end

BinFileNameWhole = sprintf('%s%s',BinFileName,'.txt');
FileID = fopen([BinFileLoc,BinFileNameWhole],'w','b');

for n = 1:RowNum
  for m = 1:32
    fwrite(FileID,IntFileConTxt(m + 32*(n-1)),'ubit1');
  end
  fprintf(FileID, '\n');
end

fclose(FileID);

fprintf('Writing bin file(s) complete. %d bin file(s) written(excluding summary file %s). %d real instruction(s) written(excluding the final additional NOPs).',BinFileNum,BinFileNameWhole,RowNum);