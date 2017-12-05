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
    input                             clk,
    input                             rst,
    // control signals transfering from EXE stage
    input                   MemEn_EXE_MEM,
    input                MemToReg_EXE_MEM,
    input        [ 3:0]  MemWrite_EXE_MEM,
    input        [ 3:0]  RegWrite_EXE_MEM,
    input        [ 1:0]      MFHL_EXE_MEM,
    input                      LB_EXE_MEM, 
    input                     LBU_EXE_MEM, 
    input                      LH_EXE_MEM, 
    input                     LHU_EXE_MEM, 
    input        [ 1:0]        LW_EXE_MEM, 
    input        [ 2:0]    s_size_EXE_MEM,
    // data passing from EXE stage
    input        [31:0]   s_vaddr_EXE_MEM,
    input        [ 4:0]  RegWaddr_EXE_MEM,
    input        [31:0] ALUResult_EXE_MEM,
    input        [31:0]  MemWdata_EXE_MEM,
    input        [31:0] RegRdata2_EXE_MEM, 
    input        [31:0]        PC_EXE_MEM,
    // interaction with the data_sram
    output       [31:0]      MemWdata_MEM,
    output                      MemEn_MEM,
    output       [ 3:0]      MemWrite_MEM,
    output       [31:0]    data_sram_addr,
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

    output       [31:0]        Bypass_MEM,  //Bypass
    
    input        [31:0]  cp0Rdata_EXE_MEM,
    input                    mfc0_EXE_MEM,
    output reg   [31:0]   cp0Rdata_MEM_WB,
    output reg                mfc0_MEM_WB,
    output reg   [31:0]   MemRdata_MEM_WB,

    input                      wb_allowin,
    output                    mem_allowin,
    output                       data_req,
    input                   data_rdata_ok,

    input        [31:0]     mem_axi_rdata,
    input                   mem_axi_rvalid,
    output                  mem_axi_rready,

    output       [31:0]     mem_axi_araddr,
    output       [ 2:0]     mem_axi_arsize,
    input                   mem_axi_arready,
    output                  mem_axi_arvalid,

    output       [31:0]     mem_axi_awaddr,
    output       [ 2:0]     mem_axi_awsize,
    output                  mem_axi_awvalid,
    input                   mem_axi_awready,

    output       [31:0]     mem_axi_wdata,
    output       [ 3:0]     mem_axi_wstrb,
    output                  mem_axi_wvalid,

    output                  mem_axi_bready,
    input                   mem_axi_bvalid
  );

    // interaction of signals and data with data_sram
    assign MemEn_MEM       =     MemEn_EXE_MEM ;
    assign MemWrite_MEM    =  MemWrite_EXE_MEM ;
    assign data_sram_addr  = ALUResult_EXE_MEM ;
    assign MemWdata_MEM    =  MemWdata_EXE_MEM ;
    assign Bypass_MEM      =      mfc0_EXE_MEM ? 
                              cp0Rdata_EXE_MEM : ALUResult_EXE_MEM;

    assign mem_axi_wstrb   =  MemWrite_EXE_MEM;
    assign mem_axi_wdata   = RegRdata2_EXE_MEM;
    assign mem_axi_wvalid  = /*如果是store类型的指令*/;


    assign mem_axi_awvalid = /*如果是store类型的指令*/;
    assign mem_axi_awaddr  = s_vaddr_EXE_MEM;
    assign mem_axi_awsize  =  s_size_EXE_MEM;/*根据SW,SB,SH,SWL,SWR来改*/


    assign mem_axi_araddr  = {ALUResult_EXE_MEM[31:2],2'b00};
    assign mem_axi_arsize  = (|LW_EXE_MEM)|
                               LH_EXE_MEM | LHU_EXE_MEM |
                               LB_EXE_MEM | LBU_EXE_MEM ? 3'b010 : 3'b00; /*根据LW,LB,LH来改*/
    assign mem_axi_arvalid = ;

    assign mem_allowgo = wb_allowin  & mem_axi_rvalid;
    assign mem_allowin = mem_allowgo & wb_allowin;

    // output data to WB stage
    always @(posedge clk)
    if (~rst) begin
        if (mem_allowgo) begin
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
            if (data_rdata_ok)
                MemRdata_MEM_WB <=  mem_axi_rdata;
        else begin
            PC_MEM_WB        <=         PC_MEM_WB;
            RegWaddr_MEM_WB  <=   RegWaddr_MEM_WB;
            MemToReg_MEM_WB  <=   MemToReg_MEM_WB;
            RegWrite_MEM_WB  <=   RegWrite_MEM_WB;
            ALUResult_MEM_WB <=  ALUResult_MEM_WB;
            RegRdata2_MEM_WB <=  RegRdata2_MEM_WB;
            cp0Rdata_MEM_WB  <=   cp0Rdata_MEM_WB;
            MFHL_MEM_WB      <=       MFHL_MEM_WB;
            LB_MEM_WB        <=         LB_MEM_WB;
            LBU_MEM_WB       <=        LBU_MEM_WB;
            LH_MEM_WB        <=         LH_MEM_WB;
            LHU_MEM_WB       <=        LHU_MEM_WB;
            LW_MEM_WB        <=         LW_MEM_WB;
            mfc0_MEM_WB      <=       mfc0_MEM_WB;
            MemRdata_MEM_WB  <=   MemRdata_MEM_WB;            
        end
    end
    else
        { 
                 PC_MEM_WB,  RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, 
          ALUResult_MEM_WB, RegRdata2_MEM_WB, cp0Rdata_MEM_WB,     MFHL_MEM_WB, 
                 LB_MEM_WB,       LBU_MEM_WB,       LH_MEM_WB,      LHU_MEM_WB,
                 LW_MEM_WB,      mfc0_MEM_WB, MemRdata_MEM_WB
        } <= 'd0;

endmodule //memory_stage
