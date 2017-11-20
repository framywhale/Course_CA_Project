/*----------------------------------------------------------------*
// Filename      :  memory_stage.v
// Description   :  5 pipelined CPU memory stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module memory_stage(
    input  wire                       clk,
    input  wire                       rst,
    // control signals transfering from EXE stage
    input  wire             MemEn_EXE_MEM,
    input  wire          MemToReg_EXE_MEM,
    input  wire  [ 3:0]  MemWrite_EXE_MEM,
    input  wire  [ 3:0]  RegWrite_EXE_MEM,
    input  wire  [ 1:0]      MFHL_EXE_MEM,
    input  wire                LB_EXE_MEM, 
    input  wire               LBU_EXE_MEM, 
    input  wire                LH_EXE_MEM, 
    input  wire               LHU_EXE_MEM, 
    input  wire  [ 1:0]        LW_EXE_MEM, 
    // data passing from EXE stage
    input  wire  [ 4:0]  RegWaddr_EXE_MEM,
    input  wire  [31:0] ALUResult_EXE_MEM,
    input  wire  [31:0]  MemWdata_EXE_MEM,
    input  wire  [31:0] RegRdata2_EXE_MEM, 
    input  wire  [31:0]        PC_EXE_MEM,
    // interaction with the data_sram
    output wire  [31:0]      MemWdata_MEM,
    output wire                 MemEn_MEM,
    output wire  [ 3:0]      MemWrite_MEM,
    output wire  [31:0]    data_sram_addr,
    // output control signals to WB stage
    output reg            MemToReg_MEM_WB,
    output reg   [ 3:0]   RegWrite_MEM_WB,
    output reg   [ 1:0]       MFHL_MEM_WB,
    output reg                  LB_MEM_WB,
    output reg                 LBU_MEM_WB,
    output reg                  LH_MEM_WB,
    output reg                 LHU_MEM_WB,
    output reg   [ 1:0]         LW_MEM_WB,

    // output data to WB stage
    output reg   [ 4:0]   RegWaddr_MEM_WB,
    output reg   [31:0]  ALUResult_MEM_WB,
    output reg   [31:0]  RegRdata2_MEM_WB, 
    output reg   [31:0]         PC_MEM_WB,

    output wire  [31:0]        Bypass_MEM,  //Bypass
    
    input  wire  [31:0] cp0Rdata_EXE_MEM,
    input  wire             mfc0_EXE_MEM,
    output reg   [31:0]  cp0Rdata_MEM_WB,
    output reg               mfc0_MEM_WB
    
  );

    // interaction of signals and data with data_sram
    assign MemEn_MEM      =     MemEn_EXE_MEM;
    assign MemWrite_MEM   =  MemWrite_EXE_MEM;
    assign data_sram_addr = ALUResult_EXE_MEM;
    assign MemWdata_MEM   =  MemWdata_EXE_MEM;

    assign Bypass_MEM  = mfc0_EXE_MEM ? cp0Rdata_EXE_MEM : ALUResult_EXE_MEM;

    // output data to WB stage
    always @(posedge clk)
    if (~rst) begin
        PC_MEM_WB        <=        PC_EXE_MEM;
        RegWaddr_MEM_WB  <=  RegWaddr_EXE_MEM;
        MemToReg_MEM_WB  <=  MemToReg_EXE_MEM;
        RegWrite_MEM_WB  <=  RegWrite_EXE_MEM;
        ALUResult_MEM_WB <= ALUResult_EXE_MEM;
        RegRdata2_MEM_WB <= RegRdata2_EXE_MEM;
        cp0Rdata_MEM_WB  <=  cp0Rdata_EXE_MEM;
        MFHL_MEM_WB      <=      MFHL_EXE_MEM;
        LB_MEM_WB        <=        LB_EXE_MEM;
        LBU_MEM_WB       <=       LBU_EXE_MEM;
        LH_MEM_WB        <=        LH_EXE_MEM;
        LHU_MEM_WB       <=       LHU_EXE_MEM;
        LW_MEM_WB        <=        LW_EXE_MEM;
        mfc0_MEM_WB      <=      mfc0_EXE_MEM;

    end
    else
        { 
                 PC_MEM_WB,  RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, 
          ALUResult_MEM_WB, RegRdata2_MEM_WB, cp0Rdata_MEM_WB,     MFHL_MEM_WB, 
                 LB_MEM_WB,       LBU_MEM_WB,       LH_MEM_WB,      LHU_MEM_WB,
                 LW_MEM_WB,      mfc0_MEM_WB
        } <= 'd0;

endmodule //memory_stage
