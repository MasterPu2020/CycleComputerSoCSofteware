
with open('code.vmem', 'r') as vmem:
    line_index = 0
    code_file = []
    code = ''
    for line in vmem.readlines():
        command = bin(int('0x' + line[-10:-2], 16))[2:]
        for bit in range(32 - len(command)):
            command = '0' + command
        code += command + '\n'
        line_index += 1
        if line_index == 512:
            line_index = 0
            code_file.append(code)
            code = ''
    if line_index < 512:
        for empty_line in range(512 - line_index):
            code += '00000000000000000000000000000000\n'
        code_file.append(code)

file_index = 0
for code in code_file:
    with open('./macro_cell_code/code' + str(file_index) + '.bin', 'w') as bin_file:
        bin_file.write(code)
    file_index += 1
