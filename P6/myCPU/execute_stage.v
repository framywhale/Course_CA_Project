/*----------------------------------------------------------------*
// Filename      :  execute_stage.v
// Description   :  5 pipelined CPU execute stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 23:25:19
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module execute_stage(
    input                            clk,
    input                            rst, 
    // data transferring from ID stage
    input       [31:0]   PC_add_4_ID_EXE,
    input       [31:0]         PC_ID_EXE,
    input       [31:0]  RegRdata1_ID_EXE,
    input       [31:0]  RegRdata2_ID_EXE,
    input       [31:0]         Sa_ID_EXE,
    input       [31:0]  SgnExtend_ID_EXE,
    input       [31:0]    ZExtend_ID_EXE,
    input       [ 4:0]   RegWaddr_ID_EXE,
    input                     DSI_ID_EXE,
    input       [ 3:0]    Exc_vec_ID_EXE, // new -> exception vector
    input               cp0_Write_ID_EXE,           
    // control signals passing from ID stage
    input                   MemEn_ID_EXE,
    input               is_signed_ID_EXE,
    input                MemToReg_ID_EXE,
    input       [ 1:0]    ALUSrcA_ID_EXE,
    input       [ 1:0]    ALUSrcB_ID_EXE,
    input       [ 3:0]      ALUop_ID_EXE,
    input       [ 3:0]   MemWrite_ID_EXE,
    input       [ 3:0]   RegWrite_ID_EXE,
    input       [ 1:0]       MULT_ID_EXE,
    input       [ 1:0]       MFHL_ID_EXE,
    input       [ 1:0]       MTHL_ID_EXE,

    input                      LB_ID_EXE,
    input                     LBU_ID_EXE,
    input                      LH_ID_EXE,
    input                     LHU_ID_EXE,
    input       [ 1:0]         LW_ID_EXE,
    input       [ 1:0]         SW_ID_EXE,
    input                      SB_ID_EXE,
    input                      SH_ID_EXE,

    // control signals passing to MEM stage
    output reg             MemEn_EXE_MEM,
    output reg          MemToReg_EXE_MEM,
    output reg  [ 3:0]  MemWrite_EXE_MEM,
    output reg  [ 3:0]  RegWrite_EXE_MEM,
    output reg  [ 1:0]      MULT_EXE_MEM,
    output reg  [ 1:0]      MFHL_EXE_MEM,
    output reg  [ 1:0]      MTHL_EXE_MEM,
    output reg                LB_EXE_MEM,
    output reg               LBU_EXE_MEM,
    output reg                LH_EXE_MEM,
    output reg               LHU_EXE_MEM,
    output reg  [ 1:0]        LW_EXE_MEM,

    // data passing to MEM stage
    output reg  [ 4:0]  RegWaddr_EXE_MEM,
    output reg  [31:0] ALUResult_EXE_MEM,
    output reg  [31:0]  MemWdata_EXE_MEM,
    output reg  [31:0]        PC_EXE_MEM,
    output reg  [31:0] RegRdata1_EXE_MEM,
    output reg  [31:0] RegRdata2_EXE_MEM,

    output      [31:0]        Bypass_EXE, // Bypass
    input       [ 4:0]         Rd_ID_EXE,
    input                    mfc0_ID_EXE,

    output reg  [31:0]  cp0Rdata_EXE_MEM,
    output reg              mfc0_EXE_MEM,

    output      [31:0]      Exc_BadVaddr,   
    output      [31:0]      Exc_EPC ,
    output                  Exc_BD,
    output      [ 6:0]      Exc_Vec,
    input       [31:0]      cp0Rdata_EXE,
    
    input                   ex_int_handle,

    input                   mem_allowin,
    output                  exe_allowin
);

    wire        AdEL_EXE,AdES_EXE;
    wire        ACarryOut,AOverflow,AZero;     
    wire [31:0] ALUA,ALUB;
    wire [ 4:0] RegWaddr_EXE;
    wire [31:0] ALUResult_EXE,BadVaddr_EXE;

    wire [ 3:0] MemWrite_Final;
//    wire [ 3:0] RegWrite_Final;

    wire [31:0] MemWdata;
    // Exception Signals
    assign BadVaddr_EXE = ALUResult_EXE & {32{AdEL_EXE|AdES_EXE}};
    // Exc_vec_ID_EXE[3]: PC_AdEL
    // Exc_vec_ID_EXE[2]: Reserved Instruction
    // Exc_vec_ID_EXE[1]: syscall
    // Exc_vec_ID_EXE[0]: breakpoint
    assign Exc_BadVaddr = Exc_vec_ID_EXE[3] ? PC_ID_EXE : BadVaddr_EXE; // if PC is wrong
    assign Exc_EPC      = DSI_ID_EXE ? PC_ID_EXE - 32'd4: PC_ID_EXE;
    // Exc_vector[7]: interrupt
    // Exc_vector[6]: PC_AdEL
    // Exc_vector[5]: Reserved Instruction
    // Exc_vector[4]: OverFlow
    // Exc_vector[3]: syscall
    // Exc_vector[2]: breakpoint
    // Exc_vector[1]: AdEL
    // Exc_vector[0]: AdES
    assign Exc_Vec      = {Exc_vec_ID_EXE[3:2], AOverflow,
                           Exc_vec_ID_EXE[1:0], AdEL_EXE,AdES_EXE};

    assign RegWaddr_EXE = RegWaddr_ID_EXE;

    assign Bypass_EXE = mfc0_ID_EXE ? cp0Rdata_EXE : ALUResult_EXE;
    
    assign Exc_BD = DSI_ID_EXE;

    assign exe_allowin = mem_allowin;
    
    always @(posedge clk)
    if (~rst) begin
        // control signals passing to MEM stage
        MemWrite_EXE_MEM  <=   MemWrite_Final & {4{~ex_int_handle}};
           MemEn_EXE_MEM  <=     MemEn_ID_EXE & ~ex_int_handle;
        MemToReg_EXE_MEM  <=  MemToReg_ID_EXE & ~ex_int_handle;
        RegWrite_EXE_MEM  <=  RegWrite_ID_EXE & {4{~ex_int_handle}};
            MULT_EXE_MEM  <=      MULT_ID_EXE & {2{~ex_int_handle}};
            MFHL_EXE_MEM  <=      MFHL_ID_EXE & {2{~ex_int_handle}};
            MTHL_EXE_MEM  <=      MTHL_ID_EXE & {2{~ex_int_handle}};
              LB_EXE_MEM  <=        LB_ID_EXE & ~ex_int_handle;
             LBU_EXE_MEM  <=       LBU_ID_EXE & ~ex_int_handle;
              LH_EXE_MEM  <=        LH_ID_EXE & ~ex_int_handle;
             LHU_EXE_MEM  <=       LHU_ID_EXE & ~ex_int_handle;
              LW_EXE_MEM  <=        LW_ID_EXE & {2{~ex_int_handle}};
            mfc0_EXE_MEM  <=      mfc0_ID_EXE & ~ex_int_handle;
        // data passing to MEM stage
        RegWaddr_EXE_MEM  <=     RegWaddr_EXE;
       ALUResult_EXE_MEM  <=    ALUResult_EXE;
        MemWdata_EXE_MEM  <=         MemWdata;
              PC_EXE_MEM  <=        PC_ID_EXE;
       RegRdata1_EXE_MEM  <= RegRdata1_ID_EXE;
       RegRdata2_EXE_MEM  <= RegRdata2_ID_EXE;
        cp0Rdata_EXE_MEM  <=     cp0Rdata_EXE; //cp0Rdata_ID_EXE;
    end
    else begin
      {
           MemEn_EXE_MEM,  MemToReg_EXE_MEM,  MemWrite_EXE_MEM, RegWrite_EXE_MEM, 
        RegWaddr_EXE_MEM,      MULT_EXE_MEM,      MFHL_EXE_MEM,     MTHL_EXE_MEM, 
              LB_EXE_MEM,       LBU_EXE_MEM,        LH_EXE_MEM,      LHU_EXE_MEM, 
              LW_EXE_MEM,      mfc0_EXE_MEM, ALUResult_EXE_MEM, MemWdata_EXE_MEM,
              PC_EXE_MEM, RegRdata1_EXE_MEM, RegRdata2_EXE_MEM, cp0Rdata_EXE_MEM
      } <= 'd0;
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
         .A         (            ALUA),
         .B         (            ALUB),
         .is_signed (is_signed_ID_EXE),
         .ALUop     (    ALUop_ID_EXE),
         .Overflow  (       AOverflow),
         .CarryOut  (       ACarryOut),
         .Zero      (           AZero),
         .Result    (   ALUResult_EXE)
    );

    MemWrite_Sel MemW (
         .MemWrite_ID_EXE (    MemWrite_ID_EXE),
         .SB_ID_EXE       (          SB_ID_EXE),
         .SH_ID_EXE       (          SH_ID_EXE),
         .SW_ID_EXE       (          SW_ID_EXE),
         .vaddr           ( ALUResult_EXE[1:0]),
         .MemWrite        (     MemWrite_Final)
    );

    Store_sel Store (
         .vaddr        (  ALUResult_EXE[1:0]),
         .SW           (           SW_ID_EXE),
         .SB           (           SB_ID_EXE),
         .SH           (           SH_ID_EXE),
         .Rt_read_data (    RegRdata2_ID_EXE),
         .MemWdata     (            MemWdata)
    );

    Addr_error ADELS(
         .is_lh        (LH_ID_EXE|LHU_ID_EXE),  
         .is_lw        (          &LW_ID_EXE),
         .is_sh        (           SH_ID_EXE),
         .is_sw        (          &SW_ID_EXE),
         .address      (  ALUResult_EXE[1:0]),
         .AdEL_EXE     (            AdEL_EXE),
         .AdES_EXE     (            AdES_EXE)
    );

endmodule //execute_stage

//////////////////////////////////////////////////////////
//           Three input MUX of five bits               //
//////////////////////////////////////////////////////////
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

module MemWrite_Sel(
    input  [3:0] MemWrite_ID_EXE,
    input  [1:0]       SW_ID_EXE,
    input              SB_ID_EXE,
    input              SH_ID_EXE,
    input  [1:0]           vaddr,
    output [3:0]        MemWrite
);
    wire [3:0] MemW_L, MemW_R, MemW_SB, MemW_SH;
    wire [3:0] v;

    assign MemW_L[3] = &vaddr;
    assign MemW_L[2] = vaddr[1];
    assign MemW_L[1] = |vaddr;
    assign MemW_L[0] = 1'b1;

    assign MemW_R[3] = 1'b1;
    assign MemW_R[2] = ~(&vaddr);
    assign MemW_R[1] = ~vaddr[1];
    assign MemW_R[0] = ~(|vaddr);

    assign v[3] =  vaddr[1] &  vaddr[0];
    assign v[2] =  vaddr[1] & ~vaddr[0];
    assign v[1] = ~vaddr[1] &  vaddr[0];
    assign v[0] = ~vaddr[1] & ~vaddr[0];

    assign MemW_SB = ({4{v[0]}} & 4'b0001 | {4{v[1]}} & 4'b0010) |
                     ({4{v[2]}} & 4'b0100 | {4{v[3]}} & 4'b1000) ;

    assign MemW_SH = ({4{v[0]}} & 4'b0011) | ({4{v[2]}} & 4'b1100);

    //Generated directly from the truth table
    assign MemWrite = ( SW_ID_EXE[1] &~SW_ID_EXE[0]) ? MemW_L ://10
                      (~SW_ID_EXE[1] & SW_ID_EXE[0]) ? MemW_R ://01
                      ( SW_ID_EXE[1] & SW_ID_EXE[0]) ? MemWrite_ID_EXE ://11
                        SB_ID_EXE          ? MemW_SB :
                        SH_ID_EXE          ? MemW_SH : MemWrite_ID_EXE;
endmodule // MemWrite_Sel

module Store_sel(
    input  wire [ 1:0] vaddr,
    input  wire [ 1:0] SW,
    input  wire        SB,
    input  wire        SH,
    input  wire [31:0] Rt_read_data,
    output wire [31:0] MemWdata
  );
  wire swr = SW[0] & ~SW[1];
  wire swl = SW[1] & ~SW[0];
  wire sw  = &SW;

  wire [3:0] v;

  wire [31:0] swr_1,swr_2,swr_3,swr_4,swr_data;
  wire [31:0] swl_1,swl_2,swl_3,swl_4,swl_data;
  wire [31:0] sb_data, sh_data;

  assign v[3] =  vaddr[1] &  vaddr[0];
  assign v[2] =  vaddr[1] & ~vaddr[0];
  assign v[1] = ~vaddr[1] &  vaddr[0];
  assign v[0] = ~vaddr[1] & ~vaddr[0];

  assign swl_1 = {24'd0,Rt_read_data[31:24]};
  assign swl_2 = {16'd0,Rt_read_data[31:16]};
  assign swl_3 = { 8'd0,Rt_read_data[31: 8]};
  assign swl_4 = Rt_read_data;

  assign swl_data = (({32{v[0]}} & swl_1) | ({32{v[1]}} & swl_2)) |
                    (({32{v[2]}} & swl_3) | ({32{v[3]}} & swl_4)) ;

  assign swr_1 =  Rt_read_data;
  assign swr_2 = {Rt_read_data[23:0], 8'd0};
  assign swr_3 = {Rt_read_data[15:0],16'd0};
  assign swr_4 = {Rt_read_data[ 7:0],24'd0};

  assign swr_data = (({32{v[0]}} & swr_1) | ({32{v[1]}} & swr_2)) |
                    (({32{v[2]}} & swr_3) | ({32{v[3]}} & swr_4)) ;

  assign sb_data = ({32{v[0]}} & {24'd0,Rt_read_data[7:0]      } |
                    {32{v[1]}} & {16'd0,Rt_read_data[7:0], 8'd0}  )
                                          |
                   ({32{v[2]}} & { 8'd0,Rt_read_data[7:0],16'd0} |
                    {32{v[3]}} & {      Rt_read_data[7:0],24'd0}  ) ;

  assign sh_data = {32{v[0]}} & {16'd0,Rt_read_data[15:0]      } |
                   {32{v[2]}} & {      Rt_read_data[15:0],16'd0} ;

  assign MemWdata = (({32{sw }} & Rt_read_data) |
                     ({32{swl}} & swl_data    ))  |
                    (({32{swr}} & swr_data    ) |
                     ({32{SB }} & sb_data     ))  |
                     ({32{SH }} & sh_data     ) ;
endmodule // Store_sel

module Addr_error(
    input  wire        is_lh   ,  
    input  wire        is_lw   ,
    input  wire        is_sh   ,
    input  wire        is_sw   ,
    input  wire [ 1:0] address ,
    output wire        AdEL_EXE,
    output wire        AdES_EXE
  );
  wire   AdEL_LH, AdEL_LW, AdES_SH, AdES_SW;
  assign AdEL_LH = address[0] & is_lh;
  assign AdEL_LW = (|address) & is_lw;

  assign AdES_SH = address[0] & is_sh;
  assign AdES_SW = (|address) & is_sw;

  assign AdEL_EXE = AdEL_LH | AdEL_LW;
  assign AdES_EXE = AdES_SH | AdES_SW;

endmodule // Addr_error
