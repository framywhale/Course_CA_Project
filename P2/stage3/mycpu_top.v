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

`define SIMU_DEBUG

module mycpu_top(
    input  wire        clk,
    input  wire        resetn,            //low active

    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,

    output wire        data_sram_en,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata

  `ifdef SIMU_DEBUG
   ,output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
  `endif
);

// we only need an inst ROM now
assign inst_sram_wen   = 4'b0;
assign inst_sram_wdata = 32'b0;

wire   rst;
assign rst = ~resetn;

wire         JSrc;
wire [ 1:0] PCSrc;

wire [ 4:0] RegRaddr1;
wire [ 4:0] RegRaddr2;
wire [31:0] RegRdata1;
wire [31:0] RegRdata2;

wire [31:0]           PC_next;
wire [31:0]          PC_IF_ID;
wire [31:0]    PC_add_4_IF_ID;
wire [31:0]        Inst_IF_ID;

wire                  PCWrite;
wire                  IRWrite;

wire [31:0]       J_target_ID;
wire [31:0]      JR_target_ID;
wire [31:0]      Br_target_ID;
wire [31:0]       PC_add_4_ID;

wire [ 1:0]     RegRdata1_src;
wire [ 1:0]     RegRdata2_src;

wire               is_rs_read;
wire               is_rt_read;
wire             ID_EXE_Stall;

wire [31:0]         PC_ID_EXE;
wire [31:0]   PC_add_4_ID_EXE;
wire [ 1:0]     RegDst_ID_EXE;
wire [ 1:0]    ALUSrcA_ID_EXE;
wire [ 1:0]    ALUSrcB_ID_EXE;
wire [ 3:0]      ALUop_ID_EXE;
wire [ 3:0]   RegWrite_ID_EXE;
wire [ 3:0]   MemWrite_ID_EXE;
wire             MemEn_ID_EXE;
wire          MemToReg_ID_EXE;
//wire [ 4:0]         Rt_ID_EXE;
//wire [ 4:0]         Rd_ID_EXE;
wire [ 4:0]   RegWaddr_ID_EXE;
wire [31:0]     ALUResult_EXE;
wire [31:0]     ALUResult_MEM;

wire [31:0]  RegRdata1_ID_EXE;
wire [31:0]  RegRdata2_ID_EXE;
wire [31:0]         Sa_ID_EXE;
wire [31:0]  SgnExtend_ID_EXE;
wire [31:0]    ZExtend_ID_EXE;

wire            MemEn_EXE_MEM;
wire         MemToReg_EXE_MEM;
wire [ 3:0]  MemWrite_EXE_MEM;
wire [ 3:0]  RegWrite_EXE_MEM;
wire [ 4:0]  RegWaddr_EXE_MEM;
wire [31:0] ALUResult_EXE_MEM;
wire [31:0]  MemWdata_EXE_MEM;
wire [31:0]        PC_EXE_MEM;

wire          MemToReg_MEM_WB;
wire [ 3:0]   RegWrite_MEM_WB;
wire [ 4:0]   RegWaddr_MEM_WB;
wire [31:0]  ALUResult_MEM_WB;
//wire [31:0]   MemRdata_MEM_WB;
wire [31:0]         PC_MEM_WB;
wire [31:0]             PC_WB;
wire [31:0]       RegWdata_WB;
wire [ 4:0]       RegWaddr_WB;
wire [ 3:0]       RegWrite_WB;


nextpc_gen nextpc_gen(
    .clk               (               clk), // I  1
    .rst               (               rst), // I  1
    .PCWrite           (           PCWrite), // I  1  Stall
    .JSrc              (              JSrc), // I  1
    .PCSrc             (             PCSrc), // I  2
//    .inst_addr         (          PC_next), // I 32
    .JR_target         (      JR_target_ID), // I 32
    .J_target          (       J_target_ID), // I 32
    .Br_addr           (      Br_target_ID), // I 32
    .inst_sram_addr    (    inst_sram_addr),  // O 32
    .PC_next           (           PC_next)
  );


fetch_stage fe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .IRWrite           (          IRWrite), // I  1
    .PC_next           (          PC_next), // I 32
    .inst_sram_en      (     inst_sram_en), // O  1
    .inst_sram_rdata   (  inst_sram_rdata), // I 32
    .PC_IF_ID          (         PC_IF_ID), // O 32
    .PC_add_4_IF_ID    (   PC_add_4_IF_ID), // O 32
    .Inst_IF_ID        (       Inst_IF_ID)  // O 32
  );


decode_stage de_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .Inst_IF_ID        (       Inst_IF_ID), // I 32
    .PC_IF_ID          (         PC_IF_ID), // I 32
    .PC_add_4_IF_ID    (   PC_add_4_IF_ID), // I 32
    .RegRaddr1_ID      (        RegRaddr1), // O  5
    .RegRaddr2_ID      (        RegRaddr2), // O  5
    .RegRdata1_ID      (        RegRdata1), // I 32
    .RegRdata2_ID      (        RegRdata2), // I 32
    .ALUResult_EXE     (    ALUResult_EXE), // I 32 Bypass
    .ALUResult_MEM     (    ALUResult_MEM), // I 32 Bypass
    .RegWdata_WB       (      RegWdata_WB), // I 32 Bypass
    .RegRdata1_src     (    RegRdata1_src), // I  2 Bypass
    .RegRdata2_src     (    RegRdata2_src), // I  2 Bypass
    .ID_EXE_Stall      (     ID_EXE_Stall), // I  1 Stall
    .JSrc              (             JSrc), // O  1
    .PCSrc             (            PCSrc), // O  2
    .J_target_ID       (      J_target_ID), // O 32
    .JR_target_ID      (     JR_target_ID), // O 32
    .Br_target_ID      (     Br_target_ID), // O 32
//    .RegDst_ID_EXE     (    RegDst_ID_EXE), // O  2
    .ALUSrcA_ID_EXE    (   ALUSrcA_ID_EXE), // O  2
    .ALUSrcB_ID_EXE    (   ALUSrcB_ID_EXE), // O  2
    .ALUop_ID_EXE      (     ALUop_ID_EXE), // O  4
    .RegWrite_ID_EXE   (  RegWrite_ID_EXE), // O  4
    .MemWrite_ID_EXE   (  MemWrite_ID_EXE), // O  4
    .MemEn_ID_EXE      (     MemEn_ID_EXE), // O  1
    .MemToReg_ID_EXE   (  MemToReg_ID_EXE), // O  1
//    .Rt_ID_EXE         (        Rt_ID_EXE), // O  5
//    .Rd_ID_EXE         (        Rd_ID_EXE), // O  5
    .RegWaddr_ID_EXE   (  RegWaddr_ID_EXE), // O  5 
    .PC_add_4_ID_EXE   (  PC_add_4_ID_EXE), // O 32
    .PC_ID_EXE         (        PC_ID_EXE), // O 32
    .RegRdata1_ID_EXE  ( RegRdata1_ID_EXE), // O 32
    .RegRdata2_ID_EXE  ( RegRdata2_ID_EXE), // O 32
    .Sa_ID_EXE         (        Sa_ID_EXE), // O 32
    .SgnExtend_ID_EXE  ( SgnExtend_ID_EXE), // O 32
    .ZExtend_ID_EXE    (   ZExtend_ID_EXE), // O 32
    
    .is_rs_read_ID     (       is_rs_read),
    .is_rt_read_ID     (       is_rt_read)
  );


execute_stage exe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .PC_add_4_ID_EXE   (  PC_add_4_ID_EXE), // I 32
    .PC_ID_EXE         (        PC_ID_EXE), // I 32
    .RegRdata1_ID_EXE  ( RegRdata1_ID_EXE), // I 32
    .RegRdata2_ID_EXE  ( RegRdata2_ID_EXE), // I 32
    .Sa_ID_EXE         (        Sa_ID_EXE), // I 32
    .SgnExtend_ID_EXE  ( SgnExtend_ID_EXE), // I 32
    .ZExtend_ID_EXE    (   ZExtend_ID_EXE), // I 32
//    .Rt_ID_EXE         (        Rt_ID_EXE), // I  5
//    .Rd_ID_EXE         (        Rd_ID_EXE), // I  5
    .RegWaddr_ID_EXE   (  RegWaddr_ID_EXE), // I  5
    .MemEn_ID_EXE      (     MemEn_ID_EXE), // I  1
    .MemToReg_ID_EXE   (  MemToReg_ID_EXE), // I  1
//    .RegDst_ID_EXE     (    RegDst_ID_EXE), // I  2
    .ALUSrcA_ID_EXE    (   ALUSrcA_ID_EXE), // I  2
    .ALUSrcB_ID_EXE    (   ALUSrcB_ID_EXE), // I  2
    .ALUop_ID_EXE      (     ALUop_ID_EXE), // I  4
    .MemWrite_ID_EXE   (  MemWrite_ID_EXE), // I  4
    .RegWrite_ID_EXE   (  RegWrite_ID_EXE), // I  4
    .MemEn_EXE_MEM     (    MemEn_EXE_MEM), // O  1
    .MemToReg_EXE_MEM  ( MemToReg_EXE_MEM), // O  1
    .MemWrite_EXE_MEM  ( MemWrite_EXE_MEM), // O  4
    .RegWrite_EXE_MEM  ( RegWrite_EXE_MEM), // O  4
    .RegWaddr_EXE_MEM  ( RegWaddr_EXE_MEM), // O  5
    .ALUResult_EXE_MEM (ALUResult_EXE_MEM), // O 32
    .MemWdata_EXE_MEM  ( MemWdata_EXE_MEM), // O 32
    .PC_EXE_MEM        (       PC_EXE_MEM), // O 32
    .ALUResult_EXE     (    ALUResult_EXE)  // O 32
    );


memory_stage mem_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .MemEn_EXE_MEM     (    MemEn_EXE_MEM), // I  1
    .MemToReg_EXE_MEM  ( MemToReg_EXE_MEM), // I  1
    .MemWrite_EXE_MEM  ( MemWrite_EXE_MEM), // I  4
    .RegWrite_EXE_MEM  ( RegWrite_EXE_MEM), // I  4
    .RegWaddr_EXE_MEM  ( RegWaddr_EXE_MEM), // I  5
    .ALUResult_EXE_MEM (ALUResult_EXE_MEM), // I 32
    .MemWdata_EXE_MEM  ( MemWdata_EXE_MEM), // I 32
    .PC_EXE_MEM        (       PC_EXE_MEM), // I 32
    .MemEn_MEM         (     data_sram_en), // O  1
    .MemWrite_MEM      (    data_sram_wen), // O  4
    .data_sram_addr    (   data_sram_addr), // O 32
//    .data_sram_rdata   (  data_sram_rdata), // I 32
    .MemWdata_MEM      (  data_sram_wdata), // O 32
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // O  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // O  4
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // O  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // O 32
    .PC_MEM_WB         (        PC_MEM_WB), // O 32
//    .MemRdata_MEM_WB   (  MemRdata_MEM_WB)  // O 32
    .ALUResult_MEM     (    ALUResult_MEM)
  );


writeback_stage wb_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // I  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // I  4
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // I  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // I 32
    .MemRdata_MEM_WB   (  data_sram_rdata), // I 32
    .PC_MEM_WB         (        PC_MEM_WB), // I 32
    .RegWdata_WB       (      RegWdata_WB), // O 32
    .RegWaddr_WB       (      RegWaddr_WB), // O  5
    .RegWrite_WB       (      RegWrite_WB), // O  4
    .PC_WB             (            PC_WB)  // O 32
);

Bypass_Unit bypass_unit(
    .clk                (              clk),
    .rst                (              rst),
    // input IR recognize signals from Control Unit
    .is_rs_read         (       is_rs_read),
    .is_rt_read         (       is_rt_read),
    // Judge whether the instruction is LW
    .MemToReg_ID_EXE    (  MemToReg_ID_EXE),
    .MemToReg_EXE_MEM   ( MemToReg_EXE_MEM),
    .MemToReg_MEM_WB    (  MemToReg_MEM_WB),
    // Reg Write address in afterward stage
    .RegWaddr_EXE_MEM   ( RegWaddr_EXE_MEM),
    .RegWaddr_MEM_WB    (  RegWaddr_MEM_WB),
    .RegWaddr_ID_EXE    (  RegWaddr_ID_EXE),
    // Reg read address in ID stage
    .rs_ID              (Inst_IF_ID[25:21]),
    .rt_ID              (Inst_IF_ID[20:16]),
    // Reg write data in afterward stage
    .RegWrite_ID_EXE    (  RegWrite_ID_EXE),
    .RegWrite_EXE_MEM   ( RegWrite_EXE_MEM),
    .RegWrite_MEM_WB    (  RegWrite_MEM_WB),
    
    .ALUResult_EXE      (    ALUResult_EXE),
    .ALUResult_EXE_MEM  (ALUResult_EXE_MEM),
    .RegWdata_WB        (      RegWdata_WB),
    // output the stall signals
    .PCWrite            (          PCWrite),
    .IRWrite            (          IRWrite),
    .ID_EXE_Stall       (     ID_EXE_Stall),
    // output the real read data in ID stage
    .RegRdata1_src      (    RegRdata1_src),
    .RegRdata2_src      (    RegRdata2_src)
);

reg_file RegFile(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .waddr             (      RegWaddr_WB), // I  5
    .raddr1            (        RegRaddr1), // I  5
    .raddr2            (        RegRaddr2), // I  5
    .wen               (      RegWrite_WB), // I  4
    .wdata             (      RegWdata_WB), // I 32
    .rdata1            (        RegRdata1), // O 32
    .rdata2            (        RegRdata2)  // O 32
);

`ifdef SIMU_DEBUG
assign debug_wb_pc       = PC_WB;
assign debug_wb_rf_wen   = RegWrite_WB;
assign debug_wb_rf_wnum  = RegWaddr_WB;
assign debug_wb_rf_wdata = RegWdata_WB;
`endif

endmodule //mycpu_top
