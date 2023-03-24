clc;

% Customize hex and bin file paths
HexFileLoc = 'D:\Vscode_Code\ARM_SoC_Project\CycleComputerSoCSofteware\chip_place_and_route\software\code.txt';
BinFileLoc = 'D:\Vscode_Code\ARM_SoC_Project\CycleComputerSoCSofteware\chip_place_and_route\software\code.bin';

%------------------------------------------------------------------------------------
% Main Function
%------------------------------------------------------------------------------------
BinFileCon = [];
FileID = fopen(HexFileLoc, 'r','b');
[BinFileCon,count] = fread(FileID, Inf, "ubit32")

if FileID == -1
  disp("Failed to open file.");
else
  disp("Open file successfully.");
end

fclose(FileID);
