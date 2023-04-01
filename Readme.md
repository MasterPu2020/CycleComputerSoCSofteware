# 这是一个放置 Cycle Computer 设计代码的Github远程仓库

## Team C4 Chip

***

## 文件目录

***

### image_process 文件夹下是 python图像处理工程文件夹与OLED图像素材

- [pyhton图像处理代码](./image_process/image_process.py)
- [图像素材库](./image_process/Assets)

### chip behavioural 文件夹下是 "Behavioural milestone (DDL)" 的工作文件

- [SoC硬件代码](./chip%20behavioural/behavioural)
- [SoC软件代码](./chip%20behavioural/software/code/main.c)
- [SoC仿真文件](./chip%20behavioural/system2/stimulus.sv)

### chip gate level 文件夹下是 "Gate level milestone (DDL)" 的工作文件

- [SoC硬件代码](./chip%20gate%20level/behavioural)
- [SoC软件代码](./chip%20gate%20level/software/code/main.c)
- [SoC仿真文件](./chip%20gate%20level/system2/stimulus.sv)

### chip_palce_and_route 文件夹下是 "Palce And Route milestone (DDL)" 的工作文件

- [SoC综合脚本(有scan path)](./chip_place_and_route/synthesis/synthesis_dft.tcl)
- [SoC硬件代码](./chip_place_and_route/behavioural/)
- [SoC软件代码](./chip_place_and_route/software/code/main.c)
- [SoC仿真文件](./chip_place_and_route/system2/stimulus.sv)

***

## Gate level Simulation Command Explanatory Documentation

### 1. Some Explanations

1. +GateLevel  : Use computer.v, options.sv, system.sv, and include sdf file in the gate_level directory.
            Without this command, simulation will use all the files in the behavioural directory instead.
2. +ScanPath   : Enable scan_enable macro and disable no_scan_signals macro.
            If you don't want to simulate scanpath, use no_scan_signals macro instead.
3. +OLED       : Enable include_oled macro.
            Without this command, simulation will use LED only.
4. -no_graphics: No graphics simulation.
            Without this command, simulation will create graphic user interface instead.
5. Notice      : The sequence of the arguments should be in the reverse sequence of the options.
                  (说人话：选项的顺序和后面给的参数的顺序应当相反。例子见下面指令。)

### 2. Simulation Instructions for different versions

1. Complete Gate Level (No Graphics) Version: +GateLevel +ScanPath +OLED +NoGraphics

```shell
    ./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
    +define+clock_period=30517.6ns \
    +define+scan_enable \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+include_oled \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

2. Complete Gate Level (with Graphics) Version: +GateLevel +ScanPath +OLED

```shell
    ./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
    +define+clock_period=30517.6ns \
    +define+scan_enable \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+include_oled \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

3. LED only Gate Level (No Graphics) Version: +GateLevel +ScanPath +NoGraphics

```shell
    ./simulate -no_graphics -gate -sdf ./gate_level/computer.sdf ./gate_level \
    +define+clock_period=30517.6ns \
    +define+scan_enable \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

4. LED only Gate Level (with Graphics) Version: +GateLevel +ScanPath

```shell
    ./simulate -gate -sdf ./gate_level/computer.sdf ./gate_level \
    +define+clock_period=30517.6ns \
    +define+scan_enable \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

5. LED only Behavioural (No Graphics) Version: +NoGraphics

```shell
    ./simulate -no_graphics ./behavioural 200s \
    +define+clock_period=30517.6ns \
    +define+no_scan_signals \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

6. LED only Behavioural (with Graphics) Version:

```shell
    ./simulate ./behavioural 200s \
    +define+clock_period=30517.6ns \
    +define+no_scan_signals \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
```

7. Macro Cell Version:

```shell
    ./simulate ./behavioural 200s \
    +define+clock_period=30517.6ns \
    +define+no_scan_signals \
    +define+external_pullup \
    +define+start_up_time=110ms \
    +define+num_modes=4 \
    +define+Mode0=Distance \
    +define+Mode1=Duration \
    +define+Mode2=Speed \
    +define+Mode3=Cadence \
    +define+stimulus=system2/stimulus.sv
    +define+functional
```

***

## Git使用说明

***

### 如何初始化你的工作区

1. 请首先安装git软件

2. 然后打开 VS code，点击左侧竖直栏的源代码管理，将git与VScode工具绑定

3. 然后选择克隆github仓库，选择存放地址，复制当前远程仓库http协议链接进行clone

### 如何上传你的修改

1. 打开源代码管理，点击提交按钮

2. 输入你修改内容的介绍

3. 点击右上角小勾勾提交

4. 解决冲突: 若你的代码与云端代码产生了冲突，请手动合并冲突。若不会合并冲突，请观看teams上“github合并”教学

***

## 留言区

**Comment by Yue:** *test 3/16 for git by Yue Hu*

**Comment by Circle:** *优化了代码，但没完全优化，Bug越De越Bug*

**Comment by Clark:** *什么玩意？*

**Comment by Clark:** *“奖励你的组员西班牙一周游”*