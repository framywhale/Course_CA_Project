# Computer Architecture Project2 -- Stage3

### 小组成员
勾凌睿: [CA_P2_S3_Go](https://github.com/Lingrui98/CA_P2_S3_Go)

吴嘉皓: [CA_P2_S3_Wu](https://github.com/framywhale/CA_P2_S3_Wu)

### 实验要求：
在**阶段一**（[勾凌睿](https://github.com/Lingrui98/CA_P2_S1)、[吴嘉皓](https://github.com/framywhale/CA-Project02_Stage01)）和**阶段二**（[勾凌睿](https://github.com/Lingrui98/CA_P2_S2_Go)、[吴嘉皓](https://github.com/framywhale/CA_P2_S3_Wu)）的基础上:

1. 增加15条指令：**DIV、DIVU、MULT、MULTU、MFHI、MFLO、MTHI、MTLO、BGEZ、BGTZ、BLEZ、BLTZ、BLTZAL、BGEZAL、JALR**
2. 具体描述，参见勾凌睿的[README](https://github.com/Lingrui98/CA_P2_S3_Go)

### （阶段三） 32位五级流水的MPIS处理器数据通路图：（暂为）

![Datapath_version2.3](https://github.com/framywhale/CA_P2_S3_Wu/blob/master/Datapath_version2.3.PNG)

### 控制信号（Stage3）

| Inst  | Opcode |  Func  | rt    | RegWrite | RegDst | MemWrite| MemEn |MemToReg| ALUSrcA | ALUSrcB|PCSrc|JSrc | ALUOp |MULT|DIV|MFHL|MTHL|
|:-:    | :-:    |:-:     |:-:    |:-:       |:-:     | :-:     |:-:    |:-:     |:-:      |:-:     |:-:  |:-:  |:-:    |:-:|:-:|:-:|:-:|
| BGEZ  | 000001 |    X   | 00001 |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| BGTZ  | 000111 |    X   | 00000 |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| BLEZ  | 000110 |    X   | 00000 |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| BLTZ  | 000001 |    X   | 00000 |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| BGEZAL| 000001 |    X   | 10001 |   1111   |   10   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| BLTZAL| 000001 |    X   | 10000 |   1111   |   10   |   0000  |   0   |   0    |    00   |   00   |  10 |  0  |  0000 |00 |00 |00 |00|
| JALR  | R-Type | 001001 |   X   |   1111   |   01   |   0000  |   0   |   0    |    00   |   00   |  01 |  1  |  0000 |00 |00 |00 |00|
| MULT  | R-Type | 011000 |   X   |   0000   |   01   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |01 |00 |00 |00|
| MULTU | R-Type | 011001 |   X   |   0000   |   01   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |10 |00 |00 |00|
| DIV   | R-Type | 011010 |   X   |   0000   |   01   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |01 |00 |00|
| DIVU  | R-Type | 011011 |   X   |   0000   |   01   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |10 |00 |00|
| MFHI  | R-Type | 010000 |   X   |   1111   |   10   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |00 |10 |00|
| MFLO  | R-Type | 010010 |   X   |   1111   |   10   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |00 |01 |00|
| MTHI  | R-Type | 010001 |   X   |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |00 |00 |01|
| MTLO  | R-Type | 010011 |   X   |   0000   |   00   |   0000  |   0   |   0    |    00   |   00   |  00 |  0  |  0000 |00 |00 |00 |10|
