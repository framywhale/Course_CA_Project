/*----------------------------------------------------------------*
// Filename      :  mycpu_top.v
// Description   :  5 pipelined CPU top
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`define SIMU_DEBUG
`define MEM_ARID  4'd1
`define INST_ARID 4'd0
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

wire                     JSrc;
wire [ 1:0]             PCSrc;

wire [ 4:0]         RegRaddr1;
wire [ 4:0]         RegRaddr2;
wire [31:0]         RegRdata1;
wire [31:0]         RegRdata2;

wire                   DSI_ID;
wire                DSI_IF_ID;

wire [31:0]           PC_next;
wire [31:0]          PC_IF_ID;
wire [31:0]    PC_add_4_IF_ID;
wire            PC_AdEL_IF_ID;
wire                  PC_AdEL;
wire [31:0]          IR_IF_ID;

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

wire [ 1:0]           DIV_EXE;
wire [ 1:0]          MULT_EXE;

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
wire [ 1:0]   s_vaddr_EXE_MEM;
wire [ 2:0]    s_size_EXE_MEM;

wire [ 1:0]          MULT_MEM;
wire [ 1:0]          MTHL_MEM;

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
wire [31:0]         PC_MEM_WB;
wire [31:0]             PC_WB;
wire [31:0]       RegWdata_WB;
wire [ 4:0]       RegWaddr_WB;
wire [ 3:0]       RegWrite_WB;
wire [31:0]   MemRdata_MEM_WB;

wire [31:0] RegWdata_Bypass_WB;


wire [63:0]  MULT_Result     ;
wire [31:0]  DIV_quotient    ;
wire [31:0]  DIV_remainder   ;
wire DIV_Busy                ;
wire DIV_Complete            ;



wire [31:0] HI_in            ;
wire [31:0] LO_in            ;
wire [ 1:0] HILO_Write       ;
wire [31:0] HI_out           ;
wire [31:0] LO_out           ;
// HILO IO

wire [ 4:0] CP0Raddr         ;
wire [31:0] CP0Rdata         ;
wire [ 4:0] CP0Waddr         ;
wire [31:0] CP0Wdata         ;
wire        CP0Write         ;
wire [31:0]      epc         ;
// CP0Reg IO

wire [ 4:0] rd               ;
wire [31:0] RegRdata2_Final  ;

wire [31:0] cp0Rdata_EXE_MEM ;
wire [31:0] cp0Rdata_MEM_WB  ;
wire           mfc0_ID_EXE   ;
wire           mfc0_EXE_MEM  ;
wire           mfc0_MEM_WB   ;

wire [31:0] Bypass_EXE       ;
wire [31:0] Bypass_MEM       ;

wire [31:0] Exc_BadVaddr     ;
wire [31:0] Exc_EPC          ;
wire [ 5:0] Exc_Cause        ;

wire        ex_int_handle    ;
wire        ex_int_handling  ;
wire        eret_handle      ;
wire        eret_handling    ;
wire        DSI_ID_EXE       ;                
wire        eret_ID_EXE      ;                 
wire        cp0_Write_ID_EXE ;                      
wire        Exc_BD           ;            
wire [ 6:0] Exc_Vec          ;
wire [ 4:0] Rd_ID_EXE        ;
wire [ 3:0] Exc_vec_ID_EXE   ;

wire [31:0]  PC_buffer       ;
wire PC_refresh              ;

wire [ 1:0] data_r_req       ;               
wire do_req_raddr            ;           
wire mem_read_req;    

wire [31:0] PC               ;
wire [31:0] mem_axi_rdata    ;                 
wire        mem_axi_rvalid   ;                 
wire [ 3:0] mem_axi_rid      ;                 
wire        mem_axi_rready   ;                 
wire [ 3:0] mem_axi_arid     ;                 
wire [31:0] mem_axi_araddr   ;                 
wire [ 2:0] mem_axi_arsize   ;                 
wire        mem_axi_arready  ;                 
wire        mem_axi_arvalid  ;                 
wire [ 3:0] mem_axi_awid     ;                 
wire [31:0] mem_axi_awaddr   ;                 
wire [ 2:0] mem_axi_awsize   ;                 
wire        mem_axi_awvalid  ;                 
wire        mem_axi_awready  ;                 
wire [ 3:0] mem_axi_wid      ;                 
wire [31:0] mem_axi_wdata    ;                 
wire [ 3:0] mem_axi_wstrb    ;                 
wire        mem_axi_wvalid   ;                 
wire        mem_axi_wready   ;                 
wire        mem_axi_bready   ;                 
wire [ 3:0] mem_axi_bid      ;                 
wire        mem_axi_bvalid   ;   
wire [ 1:0] mem_axi_bresp    ;
wire        fetch_axi_rready ;           
wire        fetch_axi_rvalid ;           
wire        fetch_axi_rdata  ;           
wire [ 3:0] fetch_axi_rid    ;           
wire        fetch_axi_arready;           
wire        fetch_axi_arvalid;           
wire [ 2:0] fetch_axi_arsize ;           
wire        fetch_axi_arid   ;           
wire        decode_allowin   ;    

wire        exe_allowin;
wire        mem_allowin;
wire        wb_allowin;
                     
wire        fe_to_de_valid;
wire        de_to_exe_valid;
wire        exe_to_mem_valid;
wire        mem_to_wb_valid;

wire        de_valid;
wire        exe_valid;
wire        mem_valid;
wire        wb_valid;

wire        exe_refresh;
wire        exe_ready_go;

wire        IR_buffer_valid;

wire         j_or_b_ID;
wire         tlbp_ID_EXE;
wire         tlbr_ID_EXE;
wire        tlbwi_ID_EXE;

wire       tlb_invalid_l;
wire       tlb_refill_l; 
wire       tlb_invalid_s;
wire       tlb_refill_s; 
wire       tlb_modified; 

wire  [31:0]  l_paddr;
wire  [31:0]  s_paddr;
wire  [32:0]  s_vaddr;

wire  [31:0]    index_r2t;
wire  [31:0]  entryhi_r2t;
wire  [31:0] entrylo0_r2t;
wire  [31:0] entrylo1_r2t;
wire  [31:0] pagemask_r2t;
wire  [31:0]    index_t2r;
wire  [31:0]  entryhi_t2r;
wire  [31:0] entrylo0_t2r;
wire  [31:0] entrylo1_t2r;
wire  [31:0] pagemask_t2r;

reg  arvalid_r;
reg  first_fetch;
reg  [31:0] do_araddr;
reg  [ 3:0] do_arid;
reg  [ 2:0] do_arsize;
reg  [ 1:0] do_r_req;
//reg  do_arvalid;
wire [ 3:0] do_r_req_pos;

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

    .PC_AdEL           (           PC_AdEL), // O  1
    .ex_int_handle     (     ex_int_handle), // I  1
    .PC                (                PC), // O 32

    .PC_buffer         (         PC_buffer), // O 32 
    .PC_refresh        (        PC_refresh)  // I  1
  );


fetch_stage fe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .DSI_ID            (           DSI_ID), // I  1
    .IRWrite           (          IRWrite), // I  1
    .PC_AdEL           (          PC_AdEL), // I  1 
    .PC_IF_ID          (         PC_IF_ID), // O 32
    .PC_add_4_IF_ID    (   PC_add_4_IF_ID), // O 32
    .IR_IF_ID          (         IR_IF_ID), // O 32
    .PC_buffer         (        PC_buffer), // I 32
    .PC_AdEL_IF_ID     (    PC_AdEL_IF_ID), // O  1
    .DSI_IF_ID         (        DSI_IF_ID), // O  1
   
    .data_r_req        (       data_r_req), // I  2      
             
    .fetch_axi_rready  (fetch_axi_rready ), // O  1
    .fetch_axi_rvalid  (      cpu_rvalid ), // I  1
    .fetch_axi_rdata   (      cpu_rdata  ), // I 32       
    .fetch_axi_rid     (      cpu_rid    ), // I  4            
    .fetch_axi_arready (      cpu_arready), // I  1    

    .fe_to_de_valid    (   fe_to_de_valid), // O  1
    .decode_allowin    (decode_allowin   ), // I  1         

    .IR_buffer_valid   (  IR_buffer_valid)
  );


decode_stage de_stage(
    .clk               (               clk), // I  1
    .rst               (               rst), // I  1
    .Inst_IF_ID        (          IR_IF_ID), // I 32
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

    .ex_int_handling   (   ex_int_handling),
    .eret_handling     (     eret_handling),

    .de_to_exe_valid   (   de_to_exe_valid), // O  1
    .decode_allowin    (    decode_allowin), // O  1
    .fe_to_de_valid    (    fe_to_de_valid), // I  1
    .exe_allowin       (       exe_allowin), // I  1      

    .exe_refresh       (       exe_refresh),
    .decode_stage_valid(          de_valid),
    .tlbp_ID_EXE       (       tlbp_ID_EXE),
    .tlbr_ID_EXE       (       tlbr_ID_EXE), 
    .tlbwi_ID_EXE      (      tlbwi_ID_EXE)
  );


execute_stage exe_stage (
    .clk               ( clk               ),    
    .rst               ( rst               ),    
    .PC_add_4_ID_EXE   ( PC_add_4_ID_EXE   ),                
    .PC_ID_EXE         ( PC_ID_EXE         ),          
    .RegRdata1_ID_EXE  ( RegRdata1_ID_EXE  ),                 
    .RegRdata2_ID_EXE  ( RegRdata2_ID_EXE  ),                 
    .Sa_ID_EXE         ( Sa_ID_EXE         ),          
    .SgnExtend_ID_EXE  ( SgnExtend_ID_EXE  ),                 
    .ZExtend_ID_EXE    ( ZExtend_ID_EXE    ),               
    .RegWaddr_ID_EXE   ( RegWaddr_ID_EXE   ),                
    .DSI_ID_EXE        ( DSI_ID_EXE        ),           
    .Exc_vec_ID_EXE    ( Exc_vec_ID_EXE    ),               
    .cp0_Write_ID_EXE  ( cp0_Write_ID_EXE  ),                 
    .MemEn_ID_EXE      ( MemEn_ID_EXE      ),             
    .is_signed_ID_EXE  ( is_signed_ID_EXE  ),                 
    .MemToReg_ID_EXE   ( MemToReg_ID_EXE   ),                
    .ALUSrcA_ID_EXE    ( ALUSrcA_ID_EXE    ),               
    .ALUSrcB_ID_EXE    ( ALUSrcB_ID_EXE    ),               
    .ALUop_ID_EXE      ( ALUop_ID_EXE      ),             
    .MemWrite_ID_EXE   ( MemWrite_ID_EXE   ),                
    .RegWrite_ID_EXE   ( RegWrite_ID_EXE   ),                
    .DIV_ID_EXE        ( DIV_ID_EXE        ),           
    .MULT_ID_EXE       ( MULT_ID_EXE       ),            
    .MFHL_ID_EXE       ( MFHL_ID_EXE       ),            
    .MTHL_ID_EXE       ( MTHL_ID_EXE       ),            
    .LB_ID_EXE         ( LB_ID_EXE         ),          
    .LBU_ID_EXE        ( LBU_ID_EXE        ),           
    .LH_ID_EXE         ( LH_ID_EXE         ),          
    .LHU_ID_EXE        ( LHU_ID_EXE        ),           
    .LW_ID_EXE         ( LW_ID_EXE         ),          
    .SW_ID_EXE         ( SW_ID_EXE         ),          
    .SB_ID_EXE         ( SB_ID_EXE         ),          
    .SH_ID_EXE         ( SH_ID_EXE         ),          
    .MemEn_EXE_MEM     ( MemEn_EXE_MEM     ),              
    .MemToReg_EXE_MEM  ( MemToReg_EXE_MEM  ),                 
    .MemWrite_EXE_MEM  ( MemWrite_EXE_MEM  ),                 
    .RegWrite_EXE_MEM  ( RegWrite_EXE_MEM  ),                 
    .MULT_EXE_MEM      ( MULT_EXE_MEM      ),             
    .MFHL_EXE_MEM      ( MFHL_EXE_MEM      ),             
    .MTHL_EXE_MEM      ( MTHL_EXE_MEM      ),             
    .LB_EXE_MEM        ( LB_EXE_MEM        ),           
    .LBU_EXE_MEM       ( LBU_EXE_MEM       ),            
    .LH_EXE_MEM        ( LH_EXE_MEM        ),           
    .LHU_EXE_MEM       ( LHU_EXE_MEM       ),            
    .LW_EXE_MEM        ( LW_EXE_MEM        ),           
    .RegWaddr_EXE_MEM  ( RegWaddr_EXE_MEM  ),                 
    .ALUResult_EXE_MEM ( ALUResult_EXE_MEM ),                  
    .MemWdata_EXE_MEM  ( MemWdata_EXE_MEM  ),                 
    .PC_EXE_MEM        ( PC_EXE_MEM        ),           
    .RegRdata1_EXE_MEM ( RegRdata1_EXE_MEM ),                  
    .RegRdata2_EXE_MEM ( RegRdata2_EXE_MEM ),                  
    .s_vaddr_EXE_MEM   ( s_vaddr_EXE_MEM   ),                
    .s_size_EXE_MEM    ( s_size_EXE_MEM    ),               
    .Bypass_EXE        ( Bypass_EXE        ),           
    .Rd_ID_EXE         ( Rd_ID_EXE         ),          
    .mfc0_ID_EXE       ( mfc0_ID_EXE       ),            
    .cp0Rdata_EXE_MEM  ( cp0Rdata_EXE_MEM  ),                 
    .mfc0_EXE_MEM      ( mfc0_EXE_MEM      ),             
    .Exc_BadVaddr      ( Exc_BadVaddr      ),             
    .Exc_EPC           ( Exc_EPC           ),        
    .Exc_BD            ( Exc_BD            ),       
    .Exc_Vec           ( Exc_Vec           ),        
    .cp0Rdata_EXE      ( CP0Rdata          ),         
    .ex_int_handle     ( ex_int_handle     ),              
    .ex_int_handling   ( ex_int_handling   ),                
    .eret_handling     ( eret_handling     ),              
    .mem_allowin       ( mem_allowin       ),            
    .de_to_exe_valid   ( de_to_exe_valid   ),                
    .exe_allowin       ( exe_allowin       ),            
    .exe_to_mem_valid  ( exe_to_mem_valid  ),                 
 
    .cp0_Write_EXE     ( CP0Write          ),         
    .exe_ready_go      ( exe_ready_go      ),             
 
    .exe_stage_valid   ( exe_valid         ),          
    .ID_EXE_Stall      ( ID_EXE_Stall      ),             
 
    .DIV_EXE           ( DIV_EXE           ),        
    .MULT_EXE          ( MULT_EXE          ),         
 
    .eret_ID_EXE       ( eret_ID_EXE       ),            
 
    .epc_value         ( epc               ),    
    .PC                ( PC                ),

    .tlbp_ID_EXE       ( tlbp_ID_EXE       ),            
    .tlbr_ID_EXE       ( tlbr_ID_EXE       ),             
    .tlbwi_ID_EXE      ( tlbwi_ID_EXE      ),

    .tlb_invalid_l     ( tlb_invalid_l     ),          
    .tlb_refill_l      ( tlb_refill_l      ),         
    .tlb_invalid_s     ( tlb_invalid_s     ),          
    .tlb_refill_s      ( tlb_refill_s      ),         
    .tlb_modified      ( tlb_modified      ),
    .s_vaddr           ( s_vaddr           )          
);


memory_stage mem_stage (
    .clk               ( clk               ),  
    .rst               ( rst               ),  
    .MemEn_EXE_MEM     ( MemEn_EXE_MEM     ),            
    .MemToReg_EXE_MEM  ( MemToReg_EXE_MEM  ),               
    .MemWrite_EXE_MEM  ( MemWrite_EXE_MEM  ),               
    .RegWrite_EXE_MEM  ( RegWrite_EXE_MEM  ),               
    .MFHL_EXE_MEM      ( MFHL_EXE_MEM      ),           
    .LB_EXE_MEM        ( LB_EXE_MEM        ),         
    .LBU_EXE_MEM       ( LBU_EXE_MEM       ),          
    .LH_EXE_MEM        ( LH_EXE_MEM        ),         
    .LHU_EXE_MEM       ( LHU_EXE_MEM       ),          
    .LW_EXE_MEM        ( LW_EXE_MEM        ),         
    .RegWaddr_EXE_MEM  ( RegWaddr_EXE_MEM  ),               
    .ALUResult_EXE_MEM ( ALUResult_EXE_MEM ),                
    .MemWdata_EXE_MEM  ( MemWdata_EXE_MEM  ),               
    .RegRdata2_EXE_MEM ( RegRdata2_EXE_MEM ),                
    .PC_EXE_MEM        ( PC_EXE_MEM        ),         
    .s_vaddr_EXE_MEM   ( s_vaddr_EXE_MEM   ),              
    .s_size_EXE_MEM    ( s_size_EXE_MEM    ),             
 
    .MULT_EXE_MEM      ( MULT_EXE_MEM      ),           
    .MTHL_EXE_MEM      ( MTHL_EXE_MEM      ),           
    .MULT_MEM          ( MULT_MEM          ),       
    .MTHL_MEM          ( MTHL_MEM          ),       
 
    .MemToReg_MEM_WB   ( MemToReg_MEM_WB   ),              
    .RegWrite_MEM_WB   ( RegWrite_MEM_WB   ),              
    .MFHL_MEM_WB       ( MFHL_MEM_WB       ),          
    .LB_MEM_WB         ( LB_MEM_WB         ),        
    .LBU_MEM_WB        ( LBU_MEM_WB        ),         
    .LH_MEM_WB         ( LH_MEM_WB         ),        
    .LHU_MEM_WB        ( LHU_MEM_WB        ),         
    .LW_MEM_WB         ( LW_MEM_WB         ),        
    .RegWaddr_MEM_WB   ( RegWaddr_MEM_WB   ),              
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB  ),               
    .RegRdata2_MEM_WB  ( RegRdata2_MEM_WB  ),               
    .PC_MEM_WB         ( PC_MEM_WB         ),        
    .MemRdata_MEM_WB   ( MemRdata_MEM_WB   ),              
    .Bypass_MEM        ( Bypass_MEM        ),         
    .cp0Rdata_EXE_MEM  ( cp0Rdata_EXE_MEM  ),               
    .mfc0_EXE_MEM      ( mfc0_EXE_MEM      ),           
    .cp0Rdata_MEM_WB   ( cp0Rdata_MEM_WB   ),              
    .mfc0_MEM_WB       ( mfc0_MEM_WB       ),          
    .wb_allowin        ( wb_allowin        ),         
    .exe_to_mem_valid  ( exe_to_mem_valid  ),               
    .mem_allowin       ( mem_allowin       ),          
    .mem_to_wb_valid   ( mem_to_wb_valid   ),              
    .data_r_req        ( data_r_req        ),         
    .do_req_raddr      ( do_req_raddr      ),           
    .mem_axi_rdata     ( mem_axi_rdata     ),            
    .mem_axi_rvalid    ( mem_axi_rvalid    ),             
    .mem_axi_rid       ( mem_axi_rid       ),          
    .mem_axi_rready    ( mem_axi_rready    ),             
    .mem_axi_arid      ( mem_axi_arid      ),           
    .mem_axi_araddr    ( mem_axi_araddr    ),             
    .mem_axi_arsize    ( mem_axi_arsize    ),             
    .mem_axi_arready   ( mem_axi_arready   ),              
    .mem_axi_arvalid   ( mem_axi_arvalid   ),              
    .mem_axi_awid      ( mem_axi_awid      ),           
    .mem_axi_awaddr    ( mem_axi_awaddr    ),             
    .mem_axi_awsize    ( mem_axi_awsize    ),             
    .mem_axi_awvalid   ( mem_axi_awvalid   ),              
    .mem_axi_awready   ( mem_axi_awready   ),              
    .mem_axi_wid       ( mem_axi_wid       ),          
    .mem_axi_wdata     ( mem_axi_wdata     ),            
    .mem_axi_wstrb     ( mem_axi_wstrb     ),            
    .mem_axi_wvalid    ( mem_axi_wvalid    ),             
    .mem_axi_wready    ( mem_axi_wready    ),             
    .mem_axi_bready    ( mem_axi_bready    ),             
    .mem_axi_bid       ( mem_axi_bid       ),          
    .mem_axi_bvalid    ( mem_axi_bvalid    ),             
 
    .cpu_arid          ( cpu_arid          ),       
    .mem_read_req      ( mem_read_req      ),           
 
    .mem_stage_valid   ( mem_valid         )               
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
    .MemRdata_MEM_WB   (  MemRdata_MEM_WB), // I 32
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
    .wb_allowin        (       wb_allowin), // O  1
    .wb_stage_valid    (         wb_valid)  
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
    .rs_ID              (  IR_IF_ID[25:21]),
    .rt_ID              (  IR_IF_ID[20:16]),
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
    .RegRdata2_src      (    RegRdata2_src),

    .de_valid           (         de_valid),
    .wb_valid           (         wb_valid),
    .exe_valid          (        exe_valid),
    .mem_valid          (        mem_valid),
    
    .is_j_or_b          (           DSI_ID)
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
    .wen               (         CP0Write), // I  1
    .wdata             (         CP0Wdata), // I 32
    .epc_in            (          Exc_EPC), // I 32
    .Exc_BadVaddr      (     Exc_BadVaddr), // I 32
    .rdata             (         CP0Rdata), // O 32
    .epc_value         (              epc), // O 32
    .ex_int_handle     (    ex_int_handle), // O  1
    .eret_handle       (      eret_handle), // O  1

    .exe_ready_go      (     exe_ready_go),
    .exe_refresh       (      exe_refresh), // I  1

    .index_r2t         (        index_r2t),          
    .entryhi_r2t       (      entryhi_r2t),          
    .entrylo0_r2t      (     entrylo0_r2t),          
    .entrylo1_r2t      (     entrylo1_r2t),          
    .pagemask_r2t      (     pagemask_r2t), 
    .index_t2r         (        index_t2r),          
    .entryhi_t2r       (      entryhi_t2r),          
    .entrylo0_t2r      (     entrylo0_t2r),          
    .entrylo1_t2r      (     entrylo1_t2r),          
    .pagemask_t2r      (     pagemask_t2r),
    .tlbp              (      tlbp_ID_EXE),
    .tlbr              (      tlbr_ID_EXE)       

);

multiplyer mul(
    .x          (         RegRdata1_ID_EXE ),
    .y          (         RegRdata2_ID_EXE ),
    .mul_clk    (                      clk ),
    .resetn     (                   resetn ),
    .clken      (                |MULT_EXE ),
    .mul_signed ( MULT_EXE[0]&~MULT_EXE[1] ),
    .result     (              MULT_Result )
);

divider div(
    .div_clk    (                    clk ),
    .rst        (                    rst ),
    .x          (       RegRdata1_ID_EXE ),
    .y          (       RegRdata2_ID_EXE ),
    .div        (               |DIV_EXE ),
    .div_signed ( DIV_EXE[0]&~DIV_EXE[1] ),
    .s          (           DIV_quotient ),
    .r          (          DIV_remainder ),
    .busy       (               DIV_Busy ),
    .complete   (           DIV_Complete )
);

HILO HILO(
    .clk        (        clk ),
    .rst        (        rst ),
    .HI_in      (      HI_in ),
    .LO_in      (      LO_in ),
    .HILO_Write ( HILO_Write ),
    .HI_out     (     HI_out ),
    .LO_out     (     LO_out )
);

tlb inst_tlb (
    .clk           ( clk           ),
    .tlbp          ( tlbp_ID_EXE   ), 
    .tlbr          ( tlbr_ID_EXE   ), 
    .tlbwi         ( tlbwi_ID_EXE  ),  
    .l_vaddr       ( do_araddr     ),    
    .s_vaddr       ( s_vaddr       ),    
    .index_r2t     ( index_r2t     ),      
    .entryhi_r2t   ( entryhi_r2t   ),        
    .entrylo0_r2t  ( entrylo0_r2t  ),         
    .entrylo1_r2t  ( entrylo1_r2t  ),         
    .pagemask_r2t  ( pagemask_r2t  ),         
    .tlb_invalid_l ( tlb_invalid_l ),          
    .tlb_refill_l  ( tlb_refill_l  ),         
    .tlb_invalid_s ( tlb_invalid_s ),          
    .tlb_refill_s  ( tlb_refill_s  ),         
    .tlb_modified  ( tlb_modified  ),         
    .l_paddr       ( l_paddr       ),    
    .s_paddr       ( s_paddr       ),    
    .index_t2r     ( index_t2r     ),      
    .entryhi_t2r   ( entryhi_t2r   ),        
    .entrylo0_t2r  ( entrylo0_t2r  ),         
    .entrylo1_t2r  ( entrylo1_t2r  ),         
    .pagemask_t2r  ( pagemask_t2r  )         
);



assign HI_in = |MULT_MEM        ? MULT_Result[63:32] :
                MTHL_MEM[1]     ? RegRdata1_EXE_MEM  :
                DIV_Complete    ? DIV_remainder      : 'd0;
assign LO_in = |MULT_MEM        ? MULT_Result[31: 0] :
                MTHL_MEM[0]     ? RegRdata1_EXE_MEM  :
                DIV_Complete    ? DIV_quotient       : 'd0;
assign HILO_Write[1] = |MULT_MEM | DIV_Complete | MTHL_MEM[1];
assign HILO_Write[0] = |MULT_MEM | DIV_Complete | MTHL_MEM[0];

assign CP0Waddr = Rd_ID_EXE;
assign CP0Wdata = RegRdata2_ID_EXE;
assign CP0Raddr = Rd_ID_EXE;



`ifdef SIMU_DEBUG
assign debug_wb_pc       = PC_WB;
assign debug_wb_rf_wen   = RegWrite_WB;
assign debug_wb_rf_wnum  = RegWaddr_WB;
assign debug_wb_rf_wdata = RegWdata_WB;
`endif





assign cpu_arid     =  do_arid;
assign cpu_araddr   =  do_araddr;
assign cpu_arlen    =  8'd0;
assign cpu_arsize   =  do_arsize;
assign cpu_arburst  =  2'd1;
assign cpu_arlock   =  2'd0;
assign cpu_arcache  =  4'd0;
assign cpu_arprot   =  3'd0;
assign cpu_arvalid  =  |do_r_req;

assign mem_axi_arready = cpu_arready;
assign fetch_axi_arready = cpu_arready;

assign mem_axi_rid = cpu_rid;
assign fetch_axi_rid = cpu_rid;

assign mem_axi_rdata = cpu_rdata;
assign fetch_axi_rdata = cpu_rdata;

assign mem_axi_rvalid = cpu_rvalid;
assign fetch_axi_rvalid = cpu_rvalid;

assign cpu_rready   =  fetch_axi_rready || mem_axi_rready;
assign cpu_awid     =  mem_axi_awid;
assign cpu_awaddr   =  mem_axi_awaddr;
assign cpu_awlen    =  8'd0;
assign cpu_awsize   =  mem_axi_awsize;
assign cpu_awburst  =  2'd1;
assign cpu_awlock   =  2'd0;
assign cpu_awcache  =  2'd0;
assign cpu_awprot   =  4'd0;
assign cpu_awvalid  =  mem_axi_awvalid;
assign mem_axi_awready = cpu_awready;
assign cpu_wid      =  mem_axi_wid;
assign cpu_wdata    =  mem_axi_wdata;
assign cpu_wstrb    =  mem_axi_wstrb;
assign cpu_wlast    =  1'd1;
assign cpu_wvalid   =  mem_axi_wvalid;
assign mem_axi_wready = cpu_wready;
assign mem_axi_bid   = cpu_bid;
assign mem_axi_bresp = cpu_bresp;
assign mem_axi_bvalid = cpu_bvalid;
assign cpu_bready   =  mem_axi_bready;

assign PC_refresh = cpu_arvalid && cpu_arready && cpu_arid==4'd0;

always @(posedge clk) begin   // arvalid_r only deals with inst
  if (rst) begin 
    arvalid_r   <= 1'b0;
    first_fetch <= 1'b1;
  end
  else if (cpu_arready&&cpu_arvalid&&cpu_arid==4'd0) begin 
    arvalid_r   <= 1'b0;
    first_fetch <= 1'b0;
  end
  else if (cpu_rready&&cpu_rvalid&&cpu_rid==4'd0) begin
    arvalid_r   <= 1'b1;
    first_fetch <= 1'b0;
  end
end


always @ (posedge clk) begin
    if (rst) begin
        do_r_req <= 2'd0;
    end
    else begin
        if (do_r_req==2'd0) begin
            if (first_fetch) begin
                do_r_req <= 2'd1;
            end
            else if (do_req_raddr) begin
                do_r_req <= 2'd3;
            end
            else if (arvalid_r&&(data_r_req!=2'd2||data_r_req!=2'd1)&&!IR_buffer_valid&&!ID_EXE_Stall) begin
                do_r_req <= 2'd2;
            end
        end
        else begin
            if (do_r_req==2'd1||do_r_req==2'd2) begin
                if (cpu_arready&&cpu_arid==4'd0) begin
                    do_r_req <= 2'd0;
                end
            end
            if (do_r_req==2'd3) begin
                if (cpu_arready&&cpu_arid==4'd1) begin
                    do_r_req <= 2'd0;
                end
            end
        end
    end
end

assign do_r_req_pos[0] = 1'b0;
assign do_r_req_pos[1] = do_r_req==2'd0 && first_fetch;
assign do_r_req_pos[2] = do_r_req==2'd0 && !ID_EXE_Stall && arvalid_r&&(data_r_req!=2'd2||data_r_req!=2'd1)&&!IR_buffer_valid;
assign do_r_req_pos[3] = do_r_req==2'd0 && do_req_raddr;


always @ (posedge clk) begin
    if (rst) begin
        do_arid   <= 'd0;
        do_arsize <= 'd0;
        do_araddr <= 'd0;
    end
    else begin
        if (do_r_req_pos[1]||do_r_req_pos[2]) begin
            do_arid   <= `INST_ARID;
            do_arsize <= 3'd2;
            do_araddr <= {PC[31:2],2'd0};
        end
        if (do_r_req_pos[3]) begin
            do_arid   <= `MEM_ARID;
            do_arsize <= mem_axi_arsize;
            do_araddr <= mem_axi_araddr;
        end
    end
end




endmodule //mycpu_top
