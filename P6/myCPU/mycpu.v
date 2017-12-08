/*----------------------------------------------------------------*
// Filename      :  mycpu_top.v
// Description   :  5 pipelined CPU top
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`define SIMU_DEBUG
`timescale 10ns / 1ns

module mycpu_top(
    input              clk,
    input              resetn, 
    input       [ 5:0] int_i,
    // read address channel
    output      [ 3:0] cpu_arid,         // M->S 
    output      [31:0] cpu_araddr,       // M->S 
    output      [ 7:0] cpu_arlen,        // M->S 
    output      [ 2:0] cpu_arsize,       // M->S 
    output      [ 1:0] cpu_arburst,      // M->S 
    output      [ 1:0] cpu_arlock,       // M->S 
    output      [ 3:0] cpu_arcache,      // M->S 
    output      [ 2:0] cpu_arprot,       // M->S 
    output             cpu_arvalid,      // M->S 
    input              cpu_arready,      // S->M 
    // read data channel
    input       [ 3:0] cpu_rid,          // S->M 
    input       [31:0] cpu_rdata,        // S->M 
    input       [ 1:0] cpu_rresp,        // S->M 
    input              cpu_rlast,        // S->M 
    input              cpu_rvalid,       // S->M 
    output             cpu_rready,       // M->S
    // write address channel 
    output      [ 3:0] cpu_awid,         // M->S
    output      [31:0] cpu_awaddr,       // M->S
    output      [ 7:0] cpu_awlen,        // M->S
    output      [ 2:0] cpu_awsize,       // M->S
    output      [ 1:0] cpu_awburst,      // M->S
    output      [ 1:0] cpu_awlock,       // M->S
    output      [ 3:0] cpu_awcache,      // M->S
    output      [ 2:0] cpu_awprot,       // M->S
    output             cpu_awvalid,      // M->S
    input              cpu_awready,      // S->M
    // write data channel
    output      [ 3:0] cpu_wid,          // M->S
    output      [31:0] cpu_wdata,        // M->S
    output      [ 3:0] cpu_wstrb,        // M->S
    output             cpu_wlast,        // M->S
    output             cpu_wvalid,       // M->S
    input              cpu_wready,       // S->M
    // write response channel
    input       [ 3:0] cpu_bid,          // S->M 
    input       [ 1:0] cpu_bresp,        // S->M 
    input              cpu_bvalid,       // S->M 
    output             cpu_bready        // M->S 

    // debug signals
  `ifdef SIMU_DEBUG
   ,output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
  `endif    
  );

// we only need an inst ROM now
// assign inst_sram_wen   =  4'b0;
// assign inst_sram_wdata = 32'b0;

wire rst = ~resetn;

wire         JSrc;
wire [ 1:0] PCSrc;

wire [ 4:0] RegRaddr1;
wire [ 4:0] RegRaddr2;
wire [31:0] RegRdata1;
wire [31:0] RegRdata2;

wire                   DSI_ID;
wire                DSI_IF_ID;

wire [31:0]           PC_next;
wire [31:0]          PC_IF_ID;
wire [31:0]    PC_add_4_IF_ID;
wire            PC_AdEL_IF_ID;
wire                  PC_AdEL;
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
wire         is_signed_ID_EXE;
wire             MemEn_ID_EXE;
wire          MemToReg_ID_EXE;
wire [ 1:0]       MULT_ID_EXE;
wire [ 1:0]        DIV_ID_EXE;
wire [ 1:0]       MFHL_ID_EXE;
wire [ 1:0]       MTHL_ID_EXE;
wire                LB_ID_EXE; 
wire               LBU_ID_EXE; 
wire                LH_ID_EXE; 
wire               LHU_ID_EXE; 
wire [ 1:0]         LW_ID_EXE; 
wire [ 1:0]         SW_ID_EXE; 
wire                SB_ID_EXE; 
wire                SH_ID_EXE; 

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
wire [ 3:0]      RegWrite_EXE;
wire [ 4:0]  RegWaddr_EXE_MEM;
wire [ 1:0]      MULT_EXE_MEM;
wire [ 1:0]      MFHL_EXE_MEM;
wire [ 1:0]      MTHL_EXE_MEM;
wire               LB_EXE_MEM; 
wire              LBU_EXE_MEM; 
wire               LH_EXE_MEM; 
wire              LHU_EXE_MEM; 
wire [ 1:0]        LW_EXE_MEM; 
wire [31:0] ALUResult_EXE_MEM;
wire [31:0]  MemWdata_EXE_MEM;
wire [31:0]        PC_EXE_MEM;
wire [31:0] RegRdata1_EXE_MEM;
wire [31:0] RegRdata2_EXE_MEM;

wire          MemToReg_MEM_WB;
wire [ 3:0]   RegWrite_MEM_WB;
wire [ 4:0]   RegWaddr_MEM_WB;
wire [ 1:0]       MFHL_MEM_WB;
wire                LB_MEM_WB; 
wire               LBU_MEM_WB; 
wire                LH_MEM_WB; 
wire               LHU_MEM_WB; 
wire [ 1:0]         LW_MEM_WB; 


wire [31:0]  ALUResult_MEM_WB;
wire [31:0]  RegRdata2_MEM_WB;
//wire [31:0]   MemRdata_MEM_WB;
wire [31:0]         PC_MEM_WB;
wire [31:0]             PC_WB;
wire [31:0]       RegWdata_WB;
wire [ 4:0]       RegWaddr_WB;
wire [ 3:0]       RegWrite_WB;

wire [31:0] RegWdata_Bypass_WB;


wire [63:0]  MULT_Result;
wire [31:0]  DIV_quotient;
wire [31:0]  DIV_remainder;
wire DIV_Busy;
wire DIV_Complete;



wire [31:0] HI_in;
wire [31:0] LO_in;
wire [ 1:0] HILO_Write;
wire [31:0] HI_out;
wire [31:0] LO_out;
// HILO IO

wire [31:0] CP0Raddr;
wire [31:0] CP0Rdata;
wire [31:0] CP0Waddr;
wire [31:0] CP0Wdata;
wire [ 3:0] CP0Write;
wire [31:0]      epc;
// CP0Reg IO

wire [ 4:0] rd;
wire [31:0] RegRdata2_Final;

wire [31:0] cp0Rdata_EXE_MEM;
wire [31:0] cp0Rdata_MEM_WB;
wire           mfc0_ID_EXE;
wire           mfc0_EXE_MEM;
wire           mfc0_MEM_WB;

wire [31:0] Bypass_EXE;
wire [31:0] Bypass_MEM;

wire [31:0] Exc_BadVaddr;
wire [31:0] Exc_EPC;
wire [ 5:0] Exc_Cause;

wire ex_int_handle;
wire eret_handle;
wire [ 6:0] Exc_Vec;
wire DSI_ID_EXE,eret_ID_EXE,cp0_Write_ID_EXE,Exc_BD;
wire [ 4:0] Rd_ID_EXE;
wire [ 3:0] Exc_vec_ID_EXE;

wire PC_abnormal; //For delay slot that wasn't fetched
wire PC_buffer,PC_fresh;
wire do_load;
wire [31:0] inst_araddr;

nextpc_gen nextpc_gen(
    .clk               (               clk), // I  1
    .rst               (               rst), // I  1
    .PCWrite           (           PCWrite), // I  1  Stall
    .JSrc              (              JSrc), // I  1
    .PCSrc             (             PCSrc), // I  2
    .eret              (       eret_handle), // I  1
    .epc               (               epc), // I 32
    .JR_target         (      JR_target_ID), // I 32
    .J_target          (       J_target_ID), // I 32
    .Br_addr           (      Br_target_ID), // I 32

    .PC_next           (           PC_next), // O 32
    .PC_AdEL           (           PC_AdEL), // O  1
    .ex_int_handle     (     ex_int_handle), // I  1
    .PC_abnormal       (       PC_abnormal), // O  1 

    .inst_sram_addr    (       inst_araddr), // O 32

    .PC_buffer         (         PC_buffer), // O 32 
    .PC_fresh          (          PC_fresh)  // I  1
  );


fetch_stage fe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .DSI_ID            (           DSI_ID), // I  1
    .IRWrite           (          IRWrite), // I  1
    .PC_AdEL           (          PC_AdEL), // I  1 
    .PC_next           (          PC_next), // I 32
    .PC_abnormal       (      PC_abnormal), // I  1
    .inst_sram_en      (     inst_sram_en), // O  1
    .inst_sram_rdata   (  inst_sram_rdata), // I 32
    .PC_IF_ID          (         PC_IF_ID), // O 32
    .PC_add_4_IF_ID    (   PC_add_4_IF_ID), // O 32
    .Inst_IF_ID        (       Inst_IF_ID), // O 32
    .PC_AdEL_IF_ID     (    PC_AdEL_IF_ID), // O  1
    .DSI_IF_ID         (        DSI_IF_ID), // O  1

    .PC_buffer         (        PC_buffer), // I 32
    .do_load           (          do_load), // I  1    
    .data_req          (                 ), // I  1      
    .data_rdata_ok     (                 ), // I  1         
    .PC_fresh          (         PC_fresh), // O  1       
    .fetch_axi_rready  (                 ), // O  1
    .fetch_axi_rvalid  (                 ), // I  1
    .fetch_axi_rdata   (                 ), // I 32       
    .fetch_axi_rid     (                 ), // I  4            
    .fetch_axi_arready (                 ), // I  1
    .fetch_axi_arvalid (                 ), // I  1
    .fetch_axi_arsize  (                 ), // I  3          
    .fetch_axi_arid    (                 ), // I  4   

    .decode_allowin    (                 )  // I  1         
  );


decode_stage de_stage(
    .clk               (               clk), // I  1
    .rst               (               rst), // I  1
    .Inst_IF_ID        (        Inst_IF_ID), // I 32
    .PC_IF_ID          (          PC_IF_ID), // I 32
    .PC_add_4_IF_ID    (    PC_add_4_IF_ID), // I 32
    .DSI_IF_ID         (         DSI_IF_ID), // I  1   new delay slot instruction tag
    .PC_AdEL_IF_ID     (     PC_AdEL_IF_ID), // I  1   new
    
    .ex_int_handle_ID  (     ex_int_handle), // I  1

    .RegRaddr1_ID      (         RegRaddr1), // O  5
    .RegRaddr2_ID      (         RegRaddr2), // O  5
    .RegRdata1_ID      (         RegRdata1), // I 32
    .RegRdata2_ID      (         RegRdata2), // I 32

    .Bypass_EXE        (        Bypass_EXE), // I 32 Bypass
    .Bypass_MEM        (        Bypass_MEM), // I 32 Bypass
    .RegWdata_WB       (RegWdata_Bypass_WB), // I 32 Bypass
    .MULT_Result       (       MULT_Result), // I 64 Bypass
    .HI                (            HI_out), // I 32 Bypass
    .LO                (            LO_out), // I 32 Bypass
    .MFHL_ID_EXE_1     (       MFHL_ID_EXE), // I  2 Bypass
    .MFHL_EXE_MEM      (      MFHL_EXE_MEM), // I  2 Bypass
    .MFHL_MEM_WB       (       MFHL_MEM_WB), // I  2 Bypass
    .MULT_EXE_MEM      (      MULT_EXE_MEM), // I  2 Bypass
    .RegRdata1_src     (     RegRdata1_src), // I  2 Bypass
    .RegRdata2_src     (     RegRdata2_src), // I  2 Bypass
    .ID_EXE_Stall      (      ID_EXE_Stall), // I  1 Stall
    .DIV_Complete      (      DIV_Complete), // I  1 Stall
    .JSrc              (              JSrc), // O  1
    .PCSrc             (             PCSrc), // O  2
    .J_target_ID       (       J_target_ID), // O 32
    .JR_target_ID      (      JR_target_ID), // O 32
    .Br_target_ID      (      Br_target_ID), // O 32

    .ALUSrcA_ID_EXE    (    ALUSrcA_ID_EXE), // O  2
    .ALUSrcB_ID_EXE    (    ALUSrcB_ID_EXE), // O  2
    .ALUop_ID_EXE      (      ALUop_ID_EXE), // O  4
    .RegWrite_ID_EXE   (   RegWrite_ID_EXE), // O  4
    .MemWrite_ID_EXE   (   MemWrite_ID_EXE), // O  4
    .MemEn_ID_EXE      (      MemEn_ID_EXE), // O  1
    .MemToReg_ID_EXE   (   MemToReg_ID_EXE), // O  1
    .is_signed_ID_EXE  (  is_signed_ID_EXE), // O  1  help ALU to judge Overflow
    .MULT_ID_EXE       (       MULT_ID_EXE), // O  2
    .DIV_ID_EXE        (        DIV_ID_EXE), // O  2
    .MFHL_ID_EXE       (       MFHL_ID_EXE), // O  2
    .MTHL_ID_EXE       (       MTHL_ID_EXE), // O  2
    .LB_ID_EXE         (         LB_ID_EXE), // O  1 
    .LBU_ID_EXE        (        LBU_ID_EXE), // O  1 
    .LH_ID_EXE         (         LH_ID_EXE), // O  1 
    .LHU_ID_EXE        (        LHU_ID_EXE), // O  1 
    .LW_ID_EXE         (         LW_ID_EXE), // O  2 
    .SW_ID_EXE         (         SW_ID_EXE), // O  2 
    .SB_ID_EXE         (         SB_ID_EXE), // O  1 
    .SH_ID_EXE         (         SH_ID_EXE), // O  1 
    .DSI_ID_EXE        (        DSI_ID_EXE), // O  1 delay slot instruction tag
    .eret_ID_EXE       (       eret_ID_EXE), // O  1 NEW   
    .Rd_ID_EXE         (         Rd_ID_EXE), // O  5 NEW
    .Exc_vec_ID_EXE    (    Exc_vec_ID_EXE), // I  4 NEW
    .RegWaddr_ID_EXE   (   RegWaddr_ID_EXE), // O  5
    .PC_add_4_ID_EXE   (   PC_add_4_ID_EXE), // O 32
    .PC_ID_EXE         (         PC_ID_EXE), // O 32
    .RegRdata1_ID_EXE  (  RegRdata1_ID_EXE), // O 32
    .RegRdata2_ID_EXE  (  RegRdata2_ID_EXE), // O 32
    .Sa_ID_EXE         (         Sa_ID_EXE), // O 32
    .SgnExtend_ID_EXE  (  SgnExtend_ID_EXE), // O 32
    .ZExtend_ID_EXE    (    ZExtend_ID_EXE), // O 32
    .cp0_Write_ID_EXE  (  cp0_Write_ID_EXE), // O  1
    .mfc0_ID_EXE       (       mfc0_ID_EXE), // O  1

    .is_rs_read_ID     (        is_rs_read), // O  1
    .is_rt_read_ID     (        is_rt_read), // O  1

    .is_j_or_br_ID     (            DSI_ID), // O  1 NEW

    .decode_allowin    (    decode_allowin), // O  1
    .exe_allowin       (       exe_allowin)  // I  1      
  );


execute_stage exe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .PC_add_4_ID_EXE   (  PC_add_4_ID_EXE), // I 32
    .cp0_Write_ID_EXE  ( cp0_Write_ID_EXE), // I  1
    .PC_ID_EXE         (        PC_ID_EXE), // I 32
    .RegRdata1_ID_EXE  ( RegRdata1_ID_EXE), // I 32
    .RegRdata2_ID_EXE  ( RegRdata2_ID_EXE), // I 32
    .Sa_ID_EXE         (        Sa_ID_EXE), // I 32
    .SgnExtend_ID_EXE  ( SgnExtend_ID_EXE), // I 32
    .ZExtend_ID_EXE    (   ZExtend_ID_EXE), // I 32
    .RegWaddr_ID_EXE   (  RegWaddr_ID_EXE), // I  5
    .MemEn_ID_EXE      (     MemEn_ID_EXE), // I  1
    .MemToReg_ID_EXE   (  MemToReg_ID_EXE), // I  1 
    .is_signed_ID_EXE  ( is_signed_ID_EXE), // I  1 help ALU to judge Overflow
    .DSI_ID_EXE        (       DSI_ID_EXE), // I  1 delay slot instruction tag
    .Rd_ID_EXE         (        Rd_ID_EXE), // I  5 NEW
    .Exc_vec_ID_EXE    (   Exc_vec_ID_EXE), // I  4 NEW
    .ALUSrcA_ID_EXE    (   ALUSrcA_ID_EXE), // I  2
    .ALUSrcB_ID_EXE    (   ALUSrcB_ID_EXE), // I  2
    .ALUop_ID_EXE      (     ALUop_ID_EXE), // I  4
    .MemWrite_ID_EXE   (  MemWrite_ID_EXE), // I  4
    .RegWrite_ID_EXE   (  RegWrite_ID_EXE), // I  4
    .MULT_ID_EXE       (      MULT_ID_EXE), // I  2
    .MFHL_ID_EXE       (      MFHL_ID_EXE), // I  2
    .MTHL_ID_EXE       (      MTHL_ID_EXE), // I  2
    .LB_ID_EXE         (        LB_ID_EXE), // I  1 
    .LBU_ID_EXE        (       LBU_ID_EXE), // I  1 
    .LH_ID_EXE         (        LH_ID_EXE), // I  1 
    .LHU_ID_EXE        (       LHU_ID_EXE), // I  1 
    .LW_ID_EXE         (        LW_ID_EXE), // I  2 
    .SW_ID_EXE         (        SW_ID_EXE), // I  2 
    .SB_ID_EXE         (        SB_ID_EXE), // I  1 
    .SH_ID_EXE         (        SH_ID_EXE), // I  1 
    .MemEn_EXE_MEM     (    MemEn_EXE_MEM), // O  1
    .MemToReg_EXE_MEM  ( MemToReg_EXE_MEM), // O  1
    .MemWrite_EXE_MEM  ( MemWrite_EXE_MEM), // O  4
    .RegWrite_EXE_MEM  ( RegWrite_EXE_MEM), // O  4
    .MULT_EXE_MEM      (     MULT_EXE_MEM), // O  2
    .MFHL_EXE_MEM      (     MFHL_EXE_MEM), // O  2
    .MTHL_EXE_MEM      (     MTHL_EXE_MEM), // O  2
    .LB_EXE_MEM        (       LB_EXE_MEM), // O  1 
    .LBU_EXE_MEM       (      LBU_EXE_MEM), // O  1 
    .LH_EXE_MEM        (       LH_EXE_MEM), // O  1 
    .LHU_EXE_MEM       (      LHU_EXE_MEM), // O  1 
    .LW_EXE_MEM        (       LW_EXE_MEM), // O  2 
    .RegWaddr_EXE_MEM  ( RegWaddr_EXE_MEM), // O  5
    .ALUResult_EXE_MEM (ALUResult_EXE_MEM), // O 32
    .MemWdata_EXE_MEM  ( MemWdata_EXE_MEM), // O 32
    .PC_EXE_MEM        (       PC_EXE_MEM), // O 32
    .RegRdata1_EXE_MEM (RegRdata1_EXE_MEM), // O 32
    .RegRdata2_EXE_MEM (RegRdata2_EXE_MEM), // O 32 
    .Bypass_EXE        (       Bypass_EXE), // O 32

    .cp0Rdata_EXE      (         CP0Rdata), // I 32
    .mfc0_ID_EXE       (      mfc0_ID_EXE), // I  1
    .mfc0_EXE_MEM      (     mfc0_EXE_MEM), // O  1
    .cp0Rdata_EXE_MEM  ( cp0Rdata_EXE_MEM), // O 32

    .Exc_BadVaddr      (     Exc_BadVaddr), // O 32
    .Exc_EPC           (          Exc_EPC), // O 32
    .Exc_Vec           (          Exc_Vec), // O  7
    .Exc_BD            (          Exc_BD ), // O  1
    
    .ex_int_handle     (    ex_int_handle), // I  1

    .mem_allowin       (      mem_allowin), // I  1
    .exe_allowin       (      exe_allowin)  // O  1

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
    .RegRdata2_EXE_MEM (RegRdata2_EXE_MEM), // I 32 
    .PC_EXE_MEM        (       PC_EXE_MEM), // I 32
    .MFHL_EXE_MEM      (     MFHL_EXE_MEM), // I  2
    .LB_EXE_MEM        (       LB_EXE_MEM), // I  1 
    .LBU_EXE_MEM       (      LBU_EXE_MEM), // I  1 
    .LH_EXE_MEM        (       LH_EXE_MEM), // I  1 
    .LHU_EXE_MEM       (      LHU_EXE_MEM), // I  1 
    .LW_EXE_MEM        (       LW_EXE_MEM), // I  2 
    .MemEn_MEM         (     data_sram_en), // O  1
    .MemWrite_MEM      (    data_sram_wen), // O  4
    .data_sram_addr    (   data_sram_addr), // O 32

    .MemWdata_MEM      (  data_sram_wdata), // O 32
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // O  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // O  4
    .LB_MEM_WB         (        LB_MEM_WB), // O  1 
    .LBU_MEM_WB        (       LBU_MEM_WB), // O  1 
    .LH_MEM_WB         (        LH_MEM_WB), // O  1 
    .LHU_MEM_WB        (       LHU_MEM_WB), // O  1 
    .LW_MEM_WB         (        LW_MEM_WB), // O  2 
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // O  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // O 32
    .RegRdata2_MEM_WB  ( RegRdata2_MEM_WB), // O 32 
    .PC_MEM_WB         (        PC_MEM_WB), // O 32
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // O  2

    .Bypass_MEM        (       Bypass_MEM), // O 32
    
    .cp0Rdata_MEM_WB   (  cp0Rdata_MEM_WB), // O 32
    .mfc0_MEM_WB       (      mfc0_MEM_WB), // O  1
    .mfc0_EXE_MEM      (     mfc0_EXE_MEM), // I  1
    .cp0Rdata_EXE_MEM  ( cp0Rdata_EXE_MEM), // I 32

    .wb_allowin        (       wb_allowin),                
    .mem_allowin       (      mem_allowin),              
    .data_req          (         data_req),          
    .data_rdata_ok     (    data_rdata_ok),   

    .mem_axi_rdata     ( mem_axi_rdata   ),       
    .mem_axi_rvalid    ( mem_axi_rvalid  ),           
    .mem_axi_rid       ( mem_axi_rid     ),       
    .mem_axi_rready    ( mem_axi_rready  ),           
    .mem_axi_arid      ( mem_axi_arid    ),        
    .mem_axi_araddr    ( mem_axi_araddr  ), 
    .mem_axi_arsize    ( mem_axi_arsize  ), 
    .mem_axi_arready   ( mem_axi_arready ),       
    .mem_axi_arvalid   ( mem_axi_arvalid ),       
    .mem_axi_awid      ( mem_axi_awid    ),           
    .mem_axi_awaddr    ( mem_axi_awaddr  ),              
    .mem_axi_awsize    ( mem_axi_awsize  ),          
    .mem_axi_awvalid   ( mem_axi_awvalid ),           
    .mem_axi_awready   ( mem_axi_awready ),         
    .mem_axi_wid       ( mem_axi_wid     ),              
    .mem_axi_wdata     ( mem_axi_wdata   ),          
    .mem_axi_wstrb     ( mem_axi_wstrb   ),              
    .mem_axi_wvalid    ( mem_axi_wvalid  ),  
    .mem_axi_wready    ( mem_axi_wready  ),  
    .mem_axi_bready    ( mem_axi_bready  ),  
    .mem_axi_bid       ( mem_axi_bid     ),           
    .mem_axi_bvalid    ( mem_axi_bvalid  ),
    .do_load           (          do_load)    
  );


writeback_stage wb_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // I  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // I  4
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // I  2
    .LB_MEM_WB         (        LB_MEM_WB), // I  1 
    .LBU_MEM_WB        (       LBU_MEM_WB), // I  1 
    .LH_MEM_WB         (        LH_MEM_WB), // I  1 
    .LHU_MEM_WB        (       LHU_MEM_WB), // I  1 
    .LW_MEM_WB         (        LW_MEM_WB), // I  2 
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // I  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // I 32
    .RegRdata2_MEM_WB  ( RegRdata2_MEM_WB), // I 32
    .MemRdata_MEM_WB   (  data_sram_rdata), // I 32
    .PC_MEM_WB         (        PC_MEM_WB), // I 32
    .HI_MEM_WB         (           HI_out), // I 32
    .LO_MEM_WB         (           LO_out), // I 32
    .RegWdata_WB       (      RegWdata_WB), // O 32
    .RegWdata_Bypass_WB(RegWdata_Bypass_WB),
    .RegWaddr_WB       (      RegWaddr_WB), // O  5
    .RegWrite_WB       (      RegWrite_WB), // O  4
    .PC_WB             (            PC_WB), // O 32
    
    .cp0Rdata_MEM_WB   (  cp0Rdata_MEM_WB), // I 32
    .mfc0_MEM_WB       (      mfc0_MEM_WB), // I  1

    .mem_to_wb_valid   (  mem_to_wb_valid), // I  1 
    .wb_allowin        (       wb_allowin)  // O  1  
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
    
    .DIV_Busy           (         DIV_Busy),
    .DIV                (      |DIV_ID_EXE),
    
    .ex_int_handle      (    ex_int_handle),
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

cp0reg cp0(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .eret              (      eret_ID_EXE), // I  1
    .int               (            int_i), // I  6
    .Exc_BD            (           Exc_BD), // I  1
    .Exc_Vec           (          Exc_Vec), // I  7
    .waddr             (         CP0Waddr), // I  5
    .raddr             (         CP0Raddr), // I  5
    .wen               ( cp0_Write_ID_EXE), // I  1
    .wdata             (         CP0Wdata), // I 32
    .epc_in            (          Exc_EPC), // I 32
    .Exc_BadVaddr      (     Exc_BadVaddr), // I 32
    .rdata             (         CP0Rdata), // O 32
    .epc_value         (              epc), // O 32
    .ex_int_handle     (    ex_int_handle), // O  1
    .eret_handle       (      eret_handle)  // O  1

);

multiplyer mul(
    .x          (              RegRdata1_ID_EXE),
    .y          (              RegRdata2_ID_EXE),
    .mul_clk    (                           clk),
    .resetn     (                        resetn),
    .clken      (                  |MULT_ID_EXE),
    .mul_signed (MULT_ID_EXE[0]&~MULT_ID_EXE[1]),
    .result     (                   MULT_Result)
);

divider div(
    .div_clk    (                           clk),
    .rst        (                           rst),
    .x          (              RegRdata1_ID_EXE),
    .y          (              RegRdata2_ID_EXE),
    .div        (                   |DIV_ID_EXE),
    .div_signed (  DIV_ID_EXE[0]&~DIV_ID_EXE[1]),
    .s          (                  DIV_quotient),
    .r          (                 DIV_remainder),
    .busy       (                      DIV_Busy),
    .complete   (                  DIV_Complete)
);

HILO HILO(
    .clk        (                           clk),
    .rst        (                           rst),
    .HI_in      (                         HI_in),
    .LO_in      (                         LO_in),
    .HILO_Write (                    HILO_Write),
    .HI_out     (                        HI_out),
    .LO_out     (                        LO_out)
);


assign HI_in = |MULT_EXE_MEM    ? MULT_Result[63:32] :
                MTHL_EXE_MEM[1] ? RegRdata1_EXE_MEM  :
                DIV_Complete    ? DIV_remainder      : 'd0;
assign LO_in = |MULT_EXE_MEM    ? MULT_Result[31: 0] :
                MTHL_EXE_MEM[0] ? RegRdata1_EXE_MEM  :
                DIV_Complete    ? DIV_quotient       : 'd0;
assign HILO_Write[1] = |MULT_EXE_MEM | DIV_Complete | MTHL_EXE_MEM[1];
assign HILO_Write[0] = |MULT_EXE_MEM | DIV_Complete | MTHL_EXE_MEM[0];

assign CP0Waddr = Rd_ID_EXE;
assign CP0Wdata = RegRdata2_ID_EXE;
assign CP0Raddr = Rd_ID_EXE;



`ifdef SIMU_DEBUG
assign debug_wb_pc       = PC_WB;
assign debug_wb_rf_wen   = RegWrite_WB;
assign debug_wb_rf_wnum  = RegWaddr_WB;
assign debug_wb_rf_wdata = RegWdata_WB;
`endif

endmodule //mycpu_top
