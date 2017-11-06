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

module execute_stage(
    input  wire        clk,
    input  wire        rst,
    // data transfering from ID stage
    input  wire [31:0]   PC_add_4_ID_EXE,
    input  wire [31:0]         PC_ID_EXE,
    input  wire [31:0]  RegRdata1_ID_EXE,
    input  wire [31:0]  RegRdata2_ID_EXE,
    input  wire [31:0]         Sa_ID_EXE,
    input  wire [31:0]  SgnExtend_ID_EXE,
    input  wire [31:0]    ZExtend_ID_EXE,
    input  wire [31:0]   RegWaddr_ID_EXE,
    // control signals passing from ID stage
    input  wire             MemEn_ID_EXE,
    input  wire          MemToReg_ID_EXE,
    input  wire [ 1:0]    ALUSrcA_ID_EXE,
    input  wire [ 1:0]    ALUSrcB_ID_EXE,
    input  wire [ 3:0]      ALUop_ID_EXE,
    input  wire [ 3:0]   MemWrite_ID_EXE,
    input  wire [ 3:0]   RegWrite_ID_EXE,
    // control signals passing to MEM stage
    output reg             MemEn_EXE_MEM,
    output reg          MemToReg_EXE_MEM,
    output reg  [ 3:0]  MemWrite_EXE_MEM,
    output reg  [ 3:0]  RegWrite_EXE_MEM,
    // data passing to MEM stage
    output reg  [ 4:0]  RegWaddr_EXE_MEM,
    output reg  [31:0] ALUResult_EXE_MEM,
    output reg  [31:0]  MemWdata_EXE_MEM,
    output reg  [31:0]        PC_EXE_MEM,
    // pass to Bypass Unit
    output wire [31:0]  ALUResult_EXE
);

    wire        ACarryOut,AOverflow,AZero;
    wire [31:0] ALUA,ALUB;
    wire [ 4:0] RegWaddr_EXE;

    assign RegWaddr_EXE = RegWaddr_ID_EXE;

    always @(posedge clk) begin
        if (~rst) begin
            // control signals passing to MEM stage
            MemEn_EXE_MEM     <= MemEn_ID_EXE;
            MemToReg_EXE_MEM  <= MemToReg_ID_EXE;
            MemWrite_EXE_MEM  <= MemWrite_ID_EXE;
            RegWrite_EXE_MEM  <= RegWrite_ID_EXE;
            // data passing to MEM stage
            RegWaddr_EXE_MEM  <= RegWaddr_EXE;
            ALUResult_EXE_MEM <= ALUResult_EXE;
            MemWdata_EXE_MEM  <= RegRdata2_ID_EXE;
            PC_EXE_MEM        <= PC_ID_EXE;
        end
        else begin
            {MemEn_EXE_MEM, MemToReg_EXE_MEM, MemWrite_EXE_MEM,
             RegWrite_EXE_MEM, RegWaddr_EXE_MEM, ALUResult_EXE_MEM,
             MemWdata_EXE_MEM, PC_EXE_MEM} <= 'd0;
        end
    end

    MUX_4_32 ALUA_MUX(
        .Src1   (RegRdata1_ID_EXE),
        .Src2   ( PC_add_4_ID_EXE),
        .Src3   (       Sa_ID_EXE),
        .Src4   (           32'd0),
        .op     (  ALUSrcA_ID_EXE),
        .Result (            ALUA)
    );
    MUX_4_32 ALUB_MUX(
        .Src1   (RegRdata2_ID_EXE),
        .Src2   (SgnExtend_ID_EXE),
        .Src3   (           32'd4),
        .Src4   (  ZExtend_ID_EXE),
        .op     (  ALUSrcB_ID_EXE),
        .Result (            ALUB)
    );
    ALU ALU(
         .A        (         ALUA),
         .B        (         ALUB),
         .ALUop    ( ALUop_ID_EXE),
         .Overflow (    AOverflow),
         .CarryOut (    ACarryOut),
         .Zero     (        AZero),
         .Result   (ALUResult_EXE)
    );

endmodule //execute_stage

//////////////////////////////////////////////////////////
//Three input MUX of five bits
module MUX_3_5(
    input  [4:0] Src1,
    input  [4:0] Src2,
    input  [4:0] Src3,
    input  [1:0] op,
    output [4:0] Result
);
    wire [4:0] and1, and2, and3, op1, op1x, op0, op0x;

  assign op1  = {5{ op[1]}};
    assign op1x = {5{~op[1]}};
    assign op0  = {5{ op[0]}};
    assign op0x = {5{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;

    assign Result = and1 | and2 | and3;
endmodule
