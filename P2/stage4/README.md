# Computer Architecture Project2 -- Stage3

### 小组成员
勾凌睿: [CA_P2_S3_Go](https://github.com/Lingrui98/CA_P2_S4_Go)

吴嘉皓: [CA_P2_S3_Wu](https://github.com/framywhale/CA_P2_S4_Wu)

### 实验要求：
在 **阶段一**（[勾凌睿](https://github.com/Lingrui98/CA_P2_S1)、[吴嘉皓](https://github.com/framywhale/CA-Project02_Stage01)）,
  **阶段二**（[勾凌睿](https://github.com/Lingrui98/CA_P2_S2_Go)、[吴嘉皓](https://github.com/framywhale/CA_P2_S3_Wu)）以及
  **阶段三** ([勾凌睿](https://github.com/Lingrui98/CA_P2_S3_Go)、[吴嘉皓](https://github.com/framywhale/CA_P2_S3_Wu)）的基础上:

1. 增加15条指令：**LB、LBU、LH、LHU、LWL、LWR、SB、SH、SWL、SWR**
2. 要求仿真和上板运行 **lab3_func_4** 通过
3. 要求仿真和上板运行通过 **Dhrystone** 的测试
4. 要求仿真和上板运行通过 **dhrystone** 的测试

### （阶段四） 32位五级流水的MPIS处理器数据通路图：

![Datapath_version2.3](https://github.com/framywhale/CA_P2_S3_Wu/blob/master/Datapath_version2.3.PNG)

### 控制信号（Stage3）

|Inst | Opcode |Func |Rt |RegWrite|RegDst|MemWrite|MemEn|MemToReg|ALUSrcA|ALUSrcB|PCSrc|JSrc|ALUOp |MULT|DIV |MFHL|MTHL|
|:-:  | :-:    |:-:  |:-:|:-:     |:-:   |:-:     |:-:  |  :-:   |:-:    |:-:    |:-:  |:-: |:-:   |:-: |:-: |:-: |:-: |
| LB  | 100000 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| LBU | 100100 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| LH  | 100001 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| LHU | 100101 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| LWL | 100010 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| LWR | 100110 |  X  | X |  1111  |  00  |  0000  |  1  |   1    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| SB  | 101000 |  X  | X |  0000  |  00  |  0001  |  1  |   0    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| SH  | 101001 |  X  | X |  0000  |  00  |  0011  |  1  |   0    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| SWL | 101010 |  X  | X |  0000  |  00  |  1111  |  1  |   0    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
| SWR | 101110 |  X  | X |  0000  |  00  |  1111  |  1  |   0    |  00   |   00  | 00  | 0  | 0010 | 00 | 00 | 00 | 00 |
