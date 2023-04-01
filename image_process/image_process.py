
# ---------------------------------------------------------------------
# Title: ELEC6231 VLSI Design Project 2023 : OLED Block Image Process
# Author: Clark PU
# Version: 1.0  2023/Fool's Day
# Comment: Not a submission file. All rights remained by Clark Pu
# ---------------------------------------------------------------------

from PIL import Image
import os


def generate_template(file_path):
    image = Image.new('RGB', (8, 13), (255, 255, 255))  # white
    # image = Image.new('RGB', (8, 13), (0, 196, 226))  # blue
    # for y in range(0, 13):
    #     for x in range(3, 5):
    #         image.putpixel((x, y), (255, 255, 255))  # white
    # for y in range(3, 5):
    #     for x in range(0, 8):
    #         image.putpixel((x, y), (255, 255, 255))  # white
    # image.show()  # debug
    image.save(file_path)


def extract_bit_list(file_path):
    image = Image.open(file_path)
    if image.size[0] == 8 and image.size[1] == 13:
        # image.show()  # debug
        image_data = ''
        for y in range(0, image.size[1]):
            for x in range(0, image.size[0]):
                # print(image.getpixel((x, y)))  # Debug
                red = image.getpixel((x, y))[0]
                green = image.getpixel((x, y))[1]
                blue = image.getpixel((x, y))[2]
                if blue > 210 and red < 100 and green < 210:  # colour is blue
                    image_data += '1'
                elif blue > 230 and red > 230 and green > 230:  # colour is white
                    image_data += '0'
                else:  # colour unknown
                    image_data += 'x'
                    print(' WARNING: Pixel colour unknown, file location: ', file_path, '. Colour is ', image.getpixel((x, y)))
        return image_data
    else:
        return 'size not correct'


path = './Assets'
generate_template(path + '/empty.png')
error = 0
data_index = 0
rom_code = []
c_code = []
all_image_data_log = []
for file in os.listdir(path):
    if file.endswith('.png') or file.endswith('.jpg'):
        data = extract_bit_list(path + '/' + file)
        all_image_data_log.append('File name: ' + file + ' Bit Stream: ' + data)
        all_pixel_is_known = True
        for bit in data:
            if bit == 'x':
                all_pixel_is_known = False
        if not all_pixel_is_known:
            print(' ERROR: Image contain unknown colour, file location: ', path + '/' + file)
            error += 1
        elif data == 'size not correct':
            print(' ERROR: Image size not correct, file location: ', path + '/' + file)
            error += 1
        else:
            # print(data)  # Debug
            data_reverse = '0b' + data[::-1]
            bit_stream = hex(int(data_reverse, 2)).upper()[2:]
            if len(bit_stream) < 26:
                for empty_bit in range(26 - len(bit_stream)):
                    bit_stream = '0' + bit_stream
            # print(len(bit_stream))  # Debug
            # print(' MESSAGE: [File Number]', data_index, ' [File Name]', file, ' [Bit Stream]', bit_stream, ' [Length/Bit]', len(data))
            if data_index < 10:
                str_index = ' ' + str(data_index)
            else:
                str_index = str(data_index)
            rom_code.append("assign resource_rom[" + str_index + "] = 104'h" + bit_stream + '; // File Name: ' + file + '\n')
            c_code.append("# define " + "IMG_" + file.strip('.png') + " " + str_index + '\n')
            data_index += 1

data_index = 0
if error != 0:
    with open('error.log', 'w') as log:
        for data in all_image_data_log:
            log.write(data + '\n')
            data_index += 1
    print('\n Failed: Find ', error, 'error(s) in', data_index, 'files. Generate error log.')
else:
    with open('resource_rom.sv', 'w') as sv:
        for line in rom_code:
            data_index += 1
            sv.write(line)
    with open('define.c', 'w') as c:
        for line in c_code:
            c.write(line)
    print('\n Finished: Generate', data_index, 'line(s) system verilog code.')
