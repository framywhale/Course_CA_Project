/*
  ------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  Copyright (c) 2016, Loongson Technology Corporation Limited.

  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

  3. Neither the name of Loongson Technology Corporation Limited nor the names of
  its contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
  TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
 */

module decode_stage(
    input  wire                     clk,
    input  wire                     rst,
    // data passing from IF stage
    input  wire [31:0]       Inst_IF_ID,
    input  wire [31:0]         PC_IF_ID,
    input  wire [31:0]   PC_add_4_IF_ID,
    // interaction with the Register files
    output wire [ 4:0]     RegRaddr1_ID,
    output wire [ 4:0]     RegRaddr2_ID,
    input  wire [31:0]     RegRdata1_ID,
    input  wire [31:0]     RegRdata2_ID,
    // control signals passing to
    // PC caculate module
    input  wire [31:0]     ALUResult_EXE,
    input  wire [31:0]     ALUResult_MEM,
    input  wire [31:0]       RegWdata_WB,
    // regdata passed back
    input  wire [ 1:0]     RegRdata1_src,
    input  wire [ 1:0]     RegRdata2_src,
    input  wire             ID_EXE_Stall,
    // control signals from bypass module
    output wire                    JSrc,
    output wire [ 1:0]            PCSrc,
    // data passing to PC calculate module
    output wire [31:0]      J_target_ID,
    output wire [31:0]     JR_target_ID,
    output wire [31:0]     Br_target_ID,
    // control signals passing to EXE stage
    output reg  [ 1:0]   ALUSrcA_ID_EXE,
    output reg  [ 1:0]   ALUSrcB_ID_EXE,
    output reg  [ 3:0]     ALUop_ID_EXE,
    output reg  [ 3:0]  RegWrite_ID_EXE,
    output reg  [ 3:0]  MemWrite_ID_EXE,
    output reg             MemEn_ID_EXE,
    output reg          MemToReg_ID_EXE,
    // data transfering to EXE stage
    output reg  [ 4:0]  RegWaddr_ID_EXE,
    output reg  [31:0]  PC_add_4_ID_EXE,
    output reg  [31:0]        PC_ID_EXE,
    output reg  [31:0] RegRdata1_ID_EXE,
    output reg  [31:0] RegRdata2_ID_EXE,
    output reg  [31:0]        Sa_ID_EXE,
    output reg  [31:0] SgnExtend_ID_EXE,
    output reg  [31:0]   ZExtend_ID_EXE,

    output wire           is_rs_read_ID,
    output wire           is_rt_read_ID
  );

// `ifndef SIMU_DEBUG
// reg  [31:0] de_inst;        //instr code @decode stage
// `endif
    wire                 Zero_ID;
    wire             MemToReg_ID;
    wire                 JSrc_ID;
    wire [ 1:0]         MemEn_ID;
    wire [ 1:0]       ALUSrcA_ID;
    wire [ 1:0]       ALUSrcB_ID;
    wire [ 1:0]        RegDst_ID;
    wire [ 1:0]         PCSrc_ID;
    wire [ 3:0]         ALUop_ID;
    wire [ 3:0]      MemWrite_ID;
    wire [ 3:0]      RegWrite_ID;
    wire [31:0]     SgnExtend_ID;
    wire [31:0]       ZExtend_ID;
    wire [31:0] SgnExtend_LF2_ID;
    wire [31:0]      PC_add_4_ID;
    wire [31:0]            Sa_ID;
    wire [31:0]            PC_ID;
    wire [ 4:0]      RegWaddr_ID;

    // Bypassed regdata
    wire [31:0]  RegRdata1_Final_ID;
    wire [31:0]  RegRdata2_Final_ID;

    // temp, intend to remember easily
    wire [ 4:0]       rs,rt,rd,sa;
    assign rs = Inst_IF_ID[25:21];
    assign rt = Inst_IF_ID[20:16];
    assign rd = Inst_IF_ID[15:11];
    assign sa = Inst_IF_ID[10: 6];

    // interaction with Register files
    // tell read address to Register files
    assign RegRaddr1_ID = Inst_IF_ID[25:21];
    assign RegRaddr2_ID = Inst_IF_ID[20:16];

    // datapath
    assign SgnExtend_ID     = {{16{Inst_IF_ID[15]}},Inst_IF_ID[15:0]};
    assign   ZExtend_ID     = {{16'd0},Inst_IF_ID[15:0]};
    assign Sa_ID            = {{27{1'b0}}, Inst_IF_ID[10: 6]};
    assign SgnExtend_LF2_ID = SgnExtend_ID << 2;

    // signals passing to PC calculate module
    assign JSrc  =  JSrc_ID;
    assign PCSrc = PCSrc_ID;

    // data passing to PC calculate module
    assign  PC_add_4_ID = PC_add_4_IF_ID;
    assign  J_target_ID = {{PC_IF_ID[31:28]},{Inst_IF_ID[25:0]},{2'b00}};
    assign JR_target_ID =   RegRdata1_Final_ID;
    assign        PC_ID =       PC_add_4_IF_ID;

    Adder Branch_addr_Adder(
        .A         (      PC_add_4_ID),
        .B         ( SgnExtend_LF2_ID),
        .Result    (     Br_target_ID)
    );

    always @(posedge clk) begin
        if (~ID_EXE_Stall) begin
            // control signals passing to EXE stage
               MemEn_ID_EXE <=             MemEn_ID;
            MemToReg_ID_EXE <=          MemToReg_ID;
               ALUop_ID_EXE <=             ALUop_ID;
            RegWrite_ID_EXE <=          RegWrite_ID;
            MemWrite_ID_EXE <=          MemWrite_ID;
             ALUSrcA_ID_EXE <=           ALUSrcA_ID;
             ALUSrcB_ID_EXE <=           ALUSrcB_ID;
            RegWaddr_ID_EXE <=          RegWaddr_ID;
                  Sa_ID_EXE <=                Sa_ID;
                  PC_ID_EXE <=             PC_IF_ID;
            PC_add_4_ID_EXE <=       PC_add_4_IF_ID;
           RegRdata1_ID_EXE <=   RegRdata1_Final_ID;
           RegRdata2_ID_EXE <=   RegRdata2_Final_ID;
           SgnExtend_ID_EXE <=         SgnExtend_ID;
             ZExtend_ID_EXE <=           ZExtend_ID;
        end
        else begin
          {MemEn_ID_EXE, MemToReg_ID_EXE, ALUop_ID_EXE, RegWrite_ID_EXE,
           MemWrite_ID_EXE, ALUSrcA_ID_EXE, ALUSrcB_ID_EXE,RegWaddr_ID_EXE,
           Sa_ID_EXE, PC_ID_EXE, PC_add_4_ID_EXE, RegRdata1_ID_EXE,
           RegRdata2_ID_EXE, SgnExtend_ID_EXE, ZExtend_ID_EXE} <= 'd0;
        end
    end

    Zero_Cal Branch_Determination(
        .A         (     RegRdata1_Final_ID),
        .B         (     RegRdata2_Final_ID),
        .Result    (                Zero_ID)
    );
    Control_Unit Control(
        .rst       (              rst),
        .zero      (          Zero_ID),
        .op        (Inst_IF_ID[31:26]),
        .func      (Inst_IF_ID[ 5: 0]),
        .MemEn     (         MemEn_ID),
        .JSrc      (          JSrc_ID),
        .MemToReg  (      MemToReg_ID),
        .ALUop     (         ALUop_ID),
        .PCSrc     (         PCSrc_ID),
        .RegDst    (        RegDst_ID),
        .RegWrite  (      RegWrite_ID),
        .MemWrite  (      MemWrite_ID),
        .ALUSrcA   (       ALUSrcA_ID),
        .ALUSrcB   (       ALUSrcB_ID),
        .is_rs_read(    is_rs_read_ID),
        .is_rt_read(    is_rt_read_ID)
    );
    MUX_4_32 RegRdata1_MUX(
        .Src1      (      RegRdata1_ID),
        .Src2      (     ALUResult_EXE),
        .Src3      (     ALUResult_MEM),
        .Src4      (       RegWdata_WB),
        .op        (     RegRdata1_src),
        .Result    (RegRdata1_Final_ID)
    );
    MUX_4_32 RegRdata2_MUX(
        .Src1      (      RegRdata2_ID),
        .Src2      (     ALUResult_EXE),
        .Src3      (     ALUResult_MEM),
        .Src4      (       RegWdata_WB),
        .op        (     RegRdata2_src),
        .Result    (RegRdata2_Final_ID)
    );
    MUX_3_5 RegWaddr_MUX(
        .Src1   (           rt),
        .Src2   (           rd),
        .Src3   (     5'b11111),
        .op     (    RegDst_ID),
        .Result (  RegWaddr_ID)
    );
endmodule //decode_stage

module Zero_Cal(
    input [31:0] A,
    input [31:0] B,
    output       Result
);
    ALU Zero(
        .A     (      A),
        .B     (      B),
        .ALUop (4'b0110),   //SUB
        .Zero  ( Result)
    );
endmodule
