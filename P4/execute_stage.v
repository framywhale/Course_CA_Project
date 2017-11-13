/*
  --------------------------------------------------------------------------------
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
//    input  wire [ 4:0]         Rt_ID_EXE,
//    input  wire [ 4:0]         Rd_ID_EXE,
    input  wire [ 4:0]   RegWaddr_ID_EXE,
    // control signals passing from ID stage
    input  wire             MemEn_ID_EXE,
    input  wire          MemToReg_ID_EXE,
//    input  wire [ 1:0]     RegDst_ID_EXE,
    input  wire [ 1:0]    ALUSrcA_ID_EXE,
    input  wire [ 1:0]    ALUSrcB_ID_EXE,
    input  wire [ 3:0]      ALUop_ID_EXE,
    input  wire [ 3:0]   MemWrite_ID_EXE,
    input  wire [ 3:0]   RegWrite_ID_EXE,
    input  wire [ 1:0]       MULT_ID_EXE,
//    input  wire [ 1:0]        DIV_ID_EXE,
    input  wire [ 1:0]       MFHL_ID_EXE,
    input  wire [ 1:0]       MTHL_ID_EXE,

    input  wire                LB_ID_EXE, //new
    input  wire               LBU_ID_EXE, //new
    input  wire                LH_ID_EXE, //new
    input  wire               LHU_ID_EXE, //new
    input  wire [ 1:0]         LW_ID_EXE, //new
    input  wire [ 1:0]         SW_ID_EXE, //new
    input  wire                SB_ID_EXE, //new
    input  wire                SH_ID_EXE, //new

    // control signals passing to MEM stage
    output reg             MemEn_EXE_MEM,
    output reg          MemToReg_EXE_MEM,
    output reg  [ 3:0]  MemWrite_EXE_MEM,
    output reg  [ 3:0]  RegWrite_EXE_MEM,
    output reg  [ 1:0]      MULT_EXE_MEM,
    output reg  [ 1:0]      MFHL_EXE_MEM,
    output reg  [ 1:0]      MTHL_EXE_MEM,
    output reg                LB_EXE_MEM, //new
    output reg               LBU_EXE_MEM, //new
    output reg                LH_EXE_MEM, //new
    output reg               LHU_EXE_MEM, //new
    output reg  [ 1:0]        LW_EXE_MEM, //new

    // data passing to MEM stage
    output reg  [ 4:0]  RegWaddr_EXE_MEM,
    output reg  [31:0] ALUResult_EXE_MEM,
    output reg  [31:0]  MemWdata_EXE_MEM,
    output reg  [31:0]        PC_EXE_MEM,
    output reg  [31:0] RegRdata1_EXE_MEM,
    output reg  [31:0] RegRdata2_EXE_MEM,

    output wire [31:0] ALUResult_EXE
 //   output wire [ 3:0] RegWrite_EXE
);

    wire        ACarryOut,AOverflow,AZero;
    wire [31:0] ALUA,ALUB;
    wire [ 4:0] RegWaddr_EXE;

    wire [ 3:0] MemWrite_Final;
//    wire [ 3:0] RegWrite_Final;

    wire [31:0] MemWdata;

    assign RegWaddr_EXE = RegWaddr_ID_EXE;
//    assign RegWrite_EXE = RegWrite_Final;


    always @(posedge clk)
    if (~rst) begin
        // control signals passing to MEM stage
           MemEn_EXE_MEM  <=    MemEn_ID_EXE;
        MemToReg_EXE_MEM  <= MemToReg_ID_EXE;
        MemWrite_EXE_MEM  <= MemWrite_Final;
        RegWrite_EXE_MEM  <= RegWrite_ID_EXE;
            MULT_EXE_MEM  <=     MULT_ID_EXE;
            MFHL_EXE_MEM  <=     MFHL_ID_EXE;
            MTHL_EXE_MEM  <=     MTHL_ID_EXE;
              LB_EXE_MEM  <=       LB_ID_EXE;
             LBU_EXE_MEM  <=      LBU_ID_EXE;
              LH_EXE_MEM  <=       LH_ID_EXE;
             LHU_EXE_MEM  <=      LHU_ID_EXE;
              LW_EXE_MEM  <=       LW_ID_EXE;

        // data passing to MEM stage
        RegWaddr_EXE_MEM <=     RegWaddr_EXE;
       ALUResult_EXE_MEM <=    ALUResult_EXE;
        MemWdata_EXE_MEM <=         MemWdata;
              PC_EXE_MEM <=        PC_ID_EXE;
       RegRdata1_EXE_MEM <= RegRdata1_ID_EXE;
       RegRdata2_EXE_MEM <= RegRdata2_ID_EXE;
    end
    else begin
    { MemEn_EXE_MEM, MemToReg_EXE_MEM, MemWrite_EXE_MEM,
      RegWrite_EXE_MEM, RegWaddr_EXE_MEM, MULT_EXE_MEM,
      MFHL_EXE_MEM, MTHL_EXE_MEM, LB_EXE_MEM, LBU_EXE_MEM,
      LH_EXE_MEM, LHU_EXE_MEM, LW_EXE_MEM,ALUResult_EXE_MEM,
      MemWdata_EXE_MEM, PC_EXE_MEM, RegRdata1_EXE_MEM,
      RegRdata2_EXE_MEM } <= 'd0;
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

    MemWrite_Sel MemW (
         .MemWrite_ID_EXE (    MemWrite_ID_EXE),
         .SB_ID_EXE       (          SB_ID_EXE),
         .SH_ID_EXE       (          SH_ID_EXE),
         .SW_ID_EXE       (          SW_ID_EXE),
         .vaddr           ( ALUResult_EXE[1:0]),
         .MemWrite        (     MemWrite_Final)
    );

    Store_sel Store (
         .vaddr        (ALUResult_EXE[1:0]),
         .SW           (         SW_ID_EXE),
         .SB           (         SB_ID_EXE),
         .SH           (         SH_ID_EXE),
         .Rt_read_data (  RegRdata2_ID_EXE),
         .MemWdata     (          MemWdata)
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
                       SB_ID_EXE           ? MemW_SB :
                       SH_ID_EXE           ? MemW_SH : MemWrite_ID_EXE;
endmodule

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
//  wire ns  = ~(|SW);

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
endmodule
