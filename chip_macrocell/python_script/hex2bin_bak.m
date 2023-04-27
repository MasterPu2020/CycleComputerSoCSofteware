%------------------------------------------------------------------------------
%   Title: Binary Code Conversion Matlab Script
%  Author: Paiyun Chen (Circle)
%    Team: C4 Chip Designed
% Version: General Purpose
%------------------------------------------------------------------------------
clear;
clc;

%------------------------------------------------------------------------------------
% Customize vmem and bin file paths and names
%------------------------------------------------------------------------------------
VmemFileLoc  = 'H:\design\system_on_chip\cycle_computer\chip\python_memory';
VmemFileName = 'code.vmem';
BinFileLoc   = 'H:\design\system_on_chip\cycle_computer\chip\python_memory\macro_cell_code\';
BinFileName  = 'code';

%------------------------------------------------------------------------------------
% Main Function
%------------------------------------------------------------------------------------

%------------------------------------------------------------------
% Read vmem file
%------------------------------------------------------------------
IntFileConTxt = [];
RowNum = 0;

BinFileNameSeries = sprintf('%s%d%s',BinFileName,1,'.bin');
WFileID = fopen([BinFileLoc,BinFileNameSeries],'w','b');

RFileID = fopen([VmemFileLoc, VmemFileName],'r','b','UTF-8');
if RFileID == -1
  disp("Failed to open vmem file.");
else
  disp("Open vmem file successfully.");
end

while ~feof(RFileID)
  RowNum = RowNum + 1;
  VmemFileCon = fgetl(RFileID);
  if (RowNum == 1)
    VmemFileRealCon = VmemFileCon(28:35);
  else
    VmemFileRealCon = VmemFileCon((28 + fix(log10(RowNum - 1))) : (35 + fix(log10(RowNum - 1))));
  end
  
  % deal with uint data
  DecFileCon = hex2dec(VmemFileRealCon);
  class(DecFileCon);
  IntFileCon = uint32(DecFileCon);
  fwrite(WFileID, IntFileCon, 'uint');
end 


fclose(WFileID);