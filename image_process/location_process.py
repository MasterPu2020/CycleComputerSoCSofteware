
# ---------------------------------------------------------------------
# Title: ELEC6231 VLSI Design Project 2023 : OLED Block Location Process
# Author: Clark PU
# Version: 1.0  2023/Fool's Day
# Comment: Not a submission file. All rights remained by Clark Pu
# ---------------------------------------------------------------------

locations = []
last_x = 0
last_y = 0
with open('location.txt', 'r') as txt:
    for line in txt.readlines():
        if len(line.split()) > 1:
            if line.split()[0] == 'follow':
                if line.split()[1] == 'left':
                    locations.append([last_x + 8, last_y])
                    last_x = last_x + 8
                elif line.split()[1] == 'down':
                    locations.append([last_x, last_y + 13])
                    last_y = last_y + 13
            else:
                locations.append([int(line.split()[0]), int(line.split()[1])])  # x y
                last_x = int(line.split()[0])
                last_y = int(line.split()[1])

code = ''
index = 0
for pair in locations:
    x = hex(pair[0])[2:].upper()
    y = hex(pair[1])[2:].upper()
    if len(x) != 2:
        x = '0' + x
    if len(y) != 2:
        y = '0' + y
    if index < 10:
        code += "assign location_rom[ " + str(index) + "] = 16'h" + y + x + ";\n"
    else:
        code += "assign location_rom[" + str(index) + "] = 16'h" + y + x + ";\n"
    index += 1
print(code)
with open('location.sv', 'w') as sv:
    sv.write(code)
