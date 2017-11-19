/*----------------------------------------------------------------*
// Filename      :  decode_stage.v
// Description   :  5 pipelined CPU decode stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module decode_stage(
    input  wire                     clk,
    input  wire                     rst,
    // data passing from IF stage
    input  reg                DSI_IF_ID,  // delay slot instruction tag
    input  wire [31:0]       Inst_IF_ID,
    input  wire [31:0]         PC_IF_ID,
    input  wire [31:0]   PC_add_4_IF_ID,
    input  wire           PC_AdEL_IF_ID,  // new
    // interaction with the Register files
    output wire [ 4:0]     RegRaddr1_ID,
    output wire [ 4:0]     RegRaddr2_ID,
    input  wire [31:0]     RegRdata1_ID,
    input  wire [31:0]     RegRdata2_ID,
    
    input  wire [31:0]      cp0Rdata_ID,
    // control signals passing to Bypass unit
    input  wire [31:0]       Bypass_EXE,
    input  wire [31:0]       Bypass_MEM,
    input  wire [31:0]      RegWdata_WB,
    input  wire [63:0]      MULT_Result,
    input  wire [31:0]               HI,
    input  wire [31:0]               LO,
    // regdata passed back
    input  wire [ 1:0]     MFHL_ID_EXE_1,
    input  wire [ 1:0]     MFHL_EXE_MEM,
    input  wire [ 1:0]     MFHL_MEM_WB,
    input  wire [ 1:0]     MULT_EXE_MEM,

    input  wire [ 1:0]     RegRdata1_src,
    input  wire [ 1:0]     RegRdata2_src,
    input  wire             ID_EXE_Stall,
    input  wire             DIV_Complete,
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
    output reg  [ 1:0]      MULT_ID_EXE,
    output reg  [ 1:0]       DIV_ID_EXE,
    output reg  [ 1:0]      MFHL_ID_EXE,
    output reg  [ 1:0]      MTHL_ID_EXE,
    output reg                LB_ID_EXE,  
    output reg               LBU_ID_EXE,  
    output reg                LH_ID_EXE,  
    output reg               LHU_ID_EXE,  
    output reg  [ 1:0]        LW_ID_EXE,  
    output reg  [ 1:0]        SW_ID_EXE,  
    output reg                SB_ID_EXE,  
    output reg                SH_ID_EXE,  
    output reg              mfc0_ID_EXE,
    output reg         is_signed_ID_EXE,  // new
    output reg               DSI_ID_EXE,  // delay slot instruction
    // Exception vecter achieved in decode stage
    // Exc_vec[3]: PC_AdEL
    // Exc_vec[2]: Reserved Instruction
    // Exc_vec[1]: syscall
    // Exc_vec[0]: breakpoint
    output reg  [ 3:0]   Exc_vec_ID_EXE,  
    // data transfering to EXE stage
    output reg  [ 4:0]  RegWaddr_ID_EXE,
    output reg  [31:0]  PC_add_4_ID_EXE,
    output reg  [31:0]        PC_ID_EXE,
    output reg  [31:0] RegRdata1_ID_EXE,
    output reg  [31:0] RegRdata2_ID_EXE,
    output reg  [31:0]        Sa_ID_EXE,
    output reg  [31:0] SgnExtend_ID_EXE,
    output reg  [31:0]   ZExtend_ID_EXE,
    
    output reg  [31:0]  cp0Rdata_ID_EXE,

    output wire           is_j_or_br_ID,
    output wire           is_rs_read_ID,
    output wire           is_rt_read_ID,
    output wire           eret_ID,
    output wire           trap_ID,
    output wire           cp0_Write,
    output wire [ 4:0]    rd,
    output wire [31:0]    RegRdata2_Final_ID
  );

// `ifndef SIMU_DEBUG
// reg  [31:0] de_inst;        //instr code @decode stage
// `endif
    wire              BranchCond_ID;
    wire                    Zero_ID;
    wire                MemToReg_ID;
    wire                    JSrc_ID;
    wire                   MemEn_ID;
    wire [ 1:0]          ALUSrcA_ID;
    wire [ 1:0]          ALUSrcB_ID;
    wire [ 1:0]           RegDst_ID;
    wire [ 1:0]            PCSrc_ID;
    wire [ 3:0]            ALUop_ID;
    wire [ 3:0]         MemWrite_ID;
    wire [ 3:0]         RegWrite_ID;
    wire [31:0]        SgnExtend_ID;
    wire [31:0]          ZExtend_ID;
    wire [31:0]    SgnExtend_LF2_ID;
    wire [31:0]         PC_add_4_ID;
    wire [31:0]               Sa_ID;
    wire [31:0]               PC_ID;
    wire [ 4:0]         RegWaddr_ID;
    wire [ 5:0]           B_Type_ID;
    wire [ 1:0]             MULT_ID;
    wire [ 1:0]              DIV_ID;
    wire [ 1:0]             MFHL_ID;
    wire [ 1:0]             MTHL_ID;
    wire                      LB_ID;
    wire                     LBU_ID;
    wire                      LH_ID;
    wire                     LHU_ID;
    wire [ 1:0]               LW_ID;
    wire [ 1:0]               SW_ID;
    wire                      SB_ID;
    wire                      SH_ID;
    wire                    mfc0_ID;
    wire               is_signed_ID; // p4 new
    wire                      RI_ID;
    wire                     sys_ID;
    wire                      bp_ID;
    wire [31:0]  RegRdata1_Final_ID;
    wire [ 3:0]          Exc_vec_ID;

    reg                    Excpt_ID;  // mark exception
    reg                      DSI_ID;  // mark delay slot instruction
    reg               is_j_or_br_ID;  // new
    // Bypassed regdata

    wire [ 4:0]       rs,rt,sa;

    wire [31:0] ID_EXE_data;
    wire [31:0] EXE_MEM_data;
    wire [31:0] MEM_WB_data;

    assign Exc_vec_ID = {PC_AdEL_IF_ID,RI_ID,sys_ID,bp_ID};

    assign rs = Inst_IF_ID[25:21];
    assign rt = Inst_IF_ID[20:16];
    assign rd = Inst_IF_ID[15:11];
    assign sa = Inst_IF_ID[10: 6];
    // interaction with Register files
    // tell read address to Register files
    assign RegRaddr1_ID = Inst_IF_ID[25:21];
    assign RegRaddr2_ID = Inst_IF_ID[20:16];
    // datapath
    assign     SgnExtend_ID = {{16{Inst_IF_ID[15]}},Inst_IF_ID[15:0]};
    assign       ZExtend_ID = {{16'd0},Inst_IF_ID[15:0]};
    assign            Sa_ID = {{27{1'b0}}, Inst_IF_ID[10: 6]};
    assign SgnExtend_LF2_ID = SgnExtend_ID << 2;
    // signals passing to PC calculate module
    assign  JSrc =  JSrc_ID;
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
      if (rst) begin
        {    Excpt_ID,
             MemEn_ID_EXE,  MemToReg_ID_EXE,     ALUop_ID_EXE, RegWrite_ID_EXE, 
          MemWrite_ID_EXE,   ALUSrcA_ID_EXE,   ALUSrcB_ID_EXE,     MULT_ID_EXE, 
               DIV_ID_EXE,      MFHL_ID_EXE,      MTHL_ID_EXE,       LB_ID_EXE,
               LBU_ID_EXE,        LH_ID_EXE,       LHU_ID_EXE,       LW_ID_EXE, 
                SW_ID_EXE,        SB_ID_EXE,        SH_ID_EXE,     mfc0_ID_EXE,
          RegWaddr_ID_EXE,        Sa_ID_EXE,        PC_ID_EXE, PC_add_4_ID_EXE, 
         RegRdata1_ID_EXE, RegRdata2_ID_EXE, SgnExtend_ID_EXE,  ZExtend_ID_EXE, 
          cp0Rdata_ID_EXE, is_signed_ID_EXE,       DSI_ID_EXE,  Exc_vec_ID_EXE} <= 'd0;
       end
       else if (~ID_EXE_Stall) begin
          // control signals passing to EXE stage
            MemEn_ID_EXE  <=           MemEn_ID;
         MemToReg_ID_EXE  <=        MemToReg_ID;
            ALUop_ID_EXE  <=           ALUop_ID;
         RegWrite_ID_EXE  <=        RegWrite_ID;
         MemWrite_ID_EXE  <=        MemWrite_ID;
          ALUSrcA_ID_EXE  <=         ALUSrcA_ID;
          ALUSrcB_ID_EXE  <=         ALUSrcB_ID;
             MULT_ID_EXE  <=            MULT_ID;
              DIV_ID_EXE  <=             DIV_ID;
             MFHL_ID_EXE  <=            MFHL_ID;
             MTHL_ID_EXE  <=            MTHL_ID;
               LB_ID_EXE  <=              LB_ID;
              LBU_ID_EXE  <=             LBU_ID;
               LH_ID_EXE  <=              LH_ID;
              LHU_ID_EXE  <=             LHU_ID;
               LW_ID_EXE  <=              LW_ID;
               SW_ID_EXE  <=              SW_ID;
               SB_ID_EXE  <=              SB_ID;
               SH_ID_EXE  <=              SH_ID;
             mfc0_ID_EXE  <=            mfc0_ID;
        is_signed_ID_EXE  <=       is_signed_ID;
          Exc_vec_ID_EXE  <=         Exc_vec_ID;
              // delay slot 
              DSI_ID_EXE  <=          DSI_IF_ID;
        // data transfering to EXE stage
         RegWaddr_ID_EXE  <=        RegWaddr_ID;
               Sa_ID_EXE  <=              Sa_ID;
               PC_ID_EXE  <=           PC_IF_ID;
         PC_add_4_ID_EXE  <=     PC_add_4_IF_ID;
        RegRdata1_ID_EXE  <= RegRdata1_Final_ID;
        RegRdata2_ID_EXE  <= RegRdata2_Final_ID;
        SgnExtend_ID_EXE  <=       SgnExtend_ID;
          ZExtend_ID_EXE  <=         ZExtend_ID;
         cp0Rdata_ID_EXE  <=        cp0Rdata_ID;
      end
      else if (~(|DIV_ID_EXE)) begin
        {    MemEn_ID_EXE,  MemToReg_ID_EXE,      ALUop_ID_EXE, RegWrite_ID_EXE, 
          MemWrite_ID_EXE,   ALUSrcA_ID_EXE,    ALUSrcB_ID_EXE,     MULT_ID_EXE,     
               DIV_ID_EXE,      MFHL_ID_EXE,       MTHL_ID_EXE,       LB_ID_EXE, //control
               LBU_ID_EXE,        LH_ID_EXE,        LHU_ID_EXE,       LW_ID_EXE, 
                SW_ID_EXE,        SB_ID_EXE,         SH_ID_EXE,     mfc0_ID_EXE,            
          RegWaddr_ID_EXE,        Sa_ID_EXE,         PC_ID_EXE, PC_add_4_ID_EXE, 
         RegRdata1_ID_EXE, RegRdata2_ID_EXE,  SgnExtend_ID_EXE,  ZExtend_ID_EXE, 
          cp0Rdata_ID_EXE, is_signed_ID_EXE,        DSI_ID_EXE,  Exc_vec_ID_EXE} <= 'd0;
      end
      else if (~DIV_Complete) begin
        {   MemEn_ID_EXE,   MemToReg_ID_EXE,     ALUop_ID_EXE,  RegWrite_ID_EXE,
         MemWrite_ID_EXE,    ALUSrcA_ID_EXE,   ALUSrcB_ID_EXE,      MULT_ID_EXE,
             MFHL_ID_EXE,       MTHL_ID_EXE,        LB_ID_EXE,       LBU_ID_EXE, //control
               LH_ID_EXE,        LHU_ID_EXE,        LW_ID_EXE,        SW_ID_EXE, 
               SB_ID_EXE,         SH_ID_EXE,      mfc0_ID_EXE,  RegWaddr_ID_EXE, 
               Sa_ID_EXE,         PC_ID_EXE,  PC_add_4_ID_EXE, SgnExtend_ID_EXE, 
          ZExtend_ID_EXE,   cp0Rdata_ID_EXE, is_signed_ID_EXE,       DSI_ID_EXE,
          Exc_vec_ID_EXE} <= 'd0;  

              DIV_ID_EXE <=       DIV_ID_EXE;
        RegRdata1_ID_EXE <= RegRdata1_ID_EXE;
        RegRdata2_ID_EXE <= RegRdata2_ID_EXE;
      end
      else begin
           MemEn_ID_EXE   <=             MemEn_ID;
        MemToReg_ID_EXE   <=          MemToReg_ID;
           ALUop_ID_EXE   <=             ALUop_ID;
        RegWrite_ID_EXE   <=          RegWrite_ID;
        MemWrite_ID_EXE   <=          MemWrite_ID;
         ALUSrcA_ID_EXE   <=           ALUSrcA_ID;
         ALUSrcB_ID_EXE   <=           ALUSrcB_ID;
            MULT_ID_EXE   <=              MULT_ID;
             DIV_ID_EXE   <=               DIV_ID;
            MFHL_ID_EXE   <=              MFHL_ID;
            MTHL_ID_EXE   <=              MTHL_ID;
              LB_ID_EXE   <=                LB_ID;
             LBU_ID_EXE   <=               LBU_ID;
              LH_ID_EXE   <=                LH_ID;
             LHU_ID_EXE   <=               LHU_ID;
              LW_ID_EXE   <=                LW_ID;
              SW_ID_EXE   <=                SW_ID;
              SB_ID_EXE   <=                SB_ID;
              SH_ID_EXE   <=                SH_ID;
            mfc0_ID_EXE   <=              mfc0_ID;
       is_signed_ID_EXE   <=         is_signed_ID;
           Exc_vec_ID_EXE <=           Exc_vec_ID;
        // delay slot 
             DSI_ID_EXE   <=            DSI_IF_ID;  // DSI_ID is 
        // data transfering to EXE stage
         RegWaddr_ID_EXE  <=          RegWaddr_ID;
               Sa_ID_EXE  <=                Sa_ID;
               PC_ID_EXE  <=             PC_IF_ID;
         PC_add_4_ID_EXE  <=       PC_add_4_IF_ID;
        RegRdata1_ID_EXE  <=   RegRdata1_Final_ID;
        RegRdata2_ID_EXE  <=   RegRdata2_Final_ID;
        SgnExtend_ID_EXE  <=         SgnExtend_ID;
          ZExtend_ID_EXE  <=           ZExtend_ID;
         cp0Rdata_ID_EXE  <=          cp0Rdata_ID;
      end
    end // always region end here

    Branch_Cond Branch_Cond(
        .A           ( RegRdata1_Final_ID),
        .B           ( RegRdata2_Final_ID),
        .B_Type      (          B_Type_ID),
        .Cond        (      BranchCond_ID)
    );
    Control_Unit Control(
        .rst         (                rst),
        .BranchCond  (      BranchCond_ID),
        .op          (  Inst_IF_ID[31:26]),
        .func        (  Inst_IF_ID[ 5: 0]),
        .rs          (  Inst_IF_ID[25:21]),
        .rt          (                 rt),
        .MemEn       (           MemEn_ID),
        .JSrc        (            JSrc_ID),
        .MemToReg    (        MemToReg_ID),
        .ALUop       (           ALUop_ID),
        .PCSrc       (           PCSrc_ID),
        .RegDst      (          RegDst_ID),
        .RegWrite    (        RegWrite_ID),
        .MemWrite    (        MemWrite_ID),
        .ALUSrcA     (         ALUSrcA_ID),
        .ALUSrcB     (         ALUSrcB_ID),
        .is_rs_read  (      is_rs_read_ID),
        .is_rt_read  (      is_rt_read_ID),
        .B_Type      (          B_Type_ID),
        .MULT        (            MULT_ID),
        .DIV         (             DIV_ID),
        .MFHL        (            MFHL_ID),
        .MTHL        (            MTHL_ID),
        .LB          (              LB_ID),
        .LBU         (             LBU_ID),
        .LH          (              LH_ID),
        .LHU         (             LHU_ID),
        .LW          (              LW_ID),
        .SW          (              SW_ID),
        .SB          (              SB_ID),
        .SH          (              SH_ID),
        .mfc0        (            mfc0_ID),
        .trap        (            trap_ID),
        .eret        (            eret_ID),
        .cp0_Write   (          cp0_Write),
        .is_signed   (       is_signed_ID),
        .ri          (              RI_ID),
        .is_j_or_br  (      is_j_or_br_ID),
        .sys         (             sys_ID),
        .bp          (              bp_ID)
    );
    MUX_4_32 RegRdata1_MUX(
        .Src1        (       RegRdata1_ID),
        .Src2        (        ID_EXE_data),
        .Src3        (       EXE_MEM_data),
        .Src4        (        MEM_WB_data),
        .op          (      RegRdata1_src),
        .Result      ( RegRdata1_Final_ID)
    );
    MUX_4_32 RegRdata2_MUX(
        .Src1        (       RegRdata2_ID),
        .Src2        (        ID_EXE_data),
        .Src3        (       EXE_MEM_data),
        .Src4        (        MEM_WB_data),
        .op          (      RegRdata2_src),
        .Result      ( RegRdata2_Final_ID)
    );
    MUX_3_5 RegWaddr_MUX(
        .Src1        (                 rt),
        .Src2        (                 rd),
        .Src3        (           5'b11111),
        .op          (          RegDst_ID),
        .Result      (        RegWaddr_ID)
    );
  wire [31:0] MULT_HI_LO = {32{MFHL_ID_EXE_1[1]}}  & MULT_Result[63:32] | 
                           {32{MFHL_ID_EXE_1[0]}}  & MULT_Result[31: 0] ;
  wire [31:0]  EXE_HI_LO = {32{MFHL_ID_EXE_1[1]}}  &         HI         | 
                           {32{MFHL_ID_EXE_1[0]}}  &         LO         ;
  wire [31:0]  MEM_HI_LO = {32{MFHL_EXE_MEM[1]}}   &         HI         | 
                           {32{MFHL_EXE_MEM[0]}}   &         LO         ;
  wire [31:0]   WB_HI_LO = {32{MFHL_MEM_WB[1]}}    &         HI         | 
                           {32{MFHL_MEM_WB[0]}}    &         LO         ;

  assign ID_EXE_data  =  |MFHL_ID_EXE  ? (MULT_EXE_MEM ? MULT_HI_LO : EXE_HI_LO) : Bypass_EXE;
  assign EXE_MEM_data =  |MFHL_EXE_MEM ? MEM_HI_LO : Bypass_MEM;
  assign MEM_WB_data  =  |MFHL_MEM_WB  ?  WB_HI_LO : RegWdata_WB;

endmodule // decode_stage

module Branch_Cond(
    input [31:0] A,
    input [31:0] B,
    input [ 5:0] B_Type,   //blt ble bgt bge beq bne
    output       Cond
);
	wire zero, ge, gt, le, lt;
  assign zero = ~(|(A - B));
  assign ge = ~A[31];
  assign gt = ~A[31] &    |A[30:0];
  assign le =  A[31] | (&(~A[31:0]));
  assign lt =  A[31];

  assign Cond = ((B_Type[0] & ~zero | B_Type[1] & zero) | 
                 (B_Type[2] & ge    | B_Type[3] & gt    ))  | 
                 (B_Type[4] & le    | B_Type[5] & lt    );

endmodule // Branch_Cond
