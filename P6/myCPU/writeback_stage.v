/*----------------------------------------------------------------*
// Filename      :  writeback_stage.v
// Description   :  5 pipelined CPU write back stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-12-04 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module writeback_stage(
    input                         clk,
    input                         rst,
    // control signals passing from MEM stage
    input             MemToReg_MEM_WB,
    input   [ 3:0]    RegWrite_MEM_WB,
    input   [ 1:0]        MFHL_MEM_WB,
    input                   LB_MEM_WB, 
    input                  LBU_MEM_WB, 
    input                   LH_MEM_WB, 
    input                  LHU_MEM_WB, 
    input   [ 1:0]          LW_MEM_WB, 
    // data passing from MEM stage
    input   [ 4:0]    RegWaddr_MEM_WB,
    input   [31:0]   ALUResult_MEM_WB,
    input   [31:0]   RegRdata2_MEM_WB,
    input   [31:0]          PC_MEM_WB,
    input   [31:0]    MemRdata_MEM_WB,
    input   [31:0]          HI_MEM_WB,
    input   [31:0]          LO_MEM_WB,
    // data that will be used to write back to Register files
    // or be used as debug signals
    output  [ 4:0]        RegWaddr_WB,
    output  [31:0]        RegWdata_WB,
    output  [31:0] RegWdata_Bypass_WB,
    output  [ 3:0]        RegWrite_WB,
    output  [31:0]              PC_WB,  
    input   [31:0]    cp0Rdata_MEM_WB,
    input                 mfc0_MEM_WB,

    output                 wb_allowin            
);
    wire        MemToReg_WB;
    wire  [31:0]  HI_LO_out;

    assign wb_allowin = 1'b1;
        
    wire  [31:0] MemRdata_Final;

     
    assign HI_LO_out = {32{MFHL_MEM_WB[1]}} & HI_MEM_WB |
                       {32{MFHL_MEM_WB[0]}} & LO_MEM_WB ;  //2-1 MUX
     
    assign  wb_allowin =            1'b1;
    assign       PC_WB =       PC_MEM_WB;
    assign RegWaddr_WB = RegWaddr_MEM_WB;
    assign MemToReg_WB = MemToReg_MEM_WB;
    assign RegWrite_WB = RegWrite_MEM_WB;
    assign RegWdata_WB = |MFHL_MEM_WB ?      HI_LO_out  : 
                         (MemToReg_WB ? MemRdata_Final  : 
                         (mfc0_MEM_WB ? cp0Rdata_MEM_WB : ALUResult_MEM_WB));

    assign RegWdata_Bypass_WB = |MFHL_MEM_WB ?       HI_LO_out : 
                                (mfc0_MEM_WB ? cp0Rdata_MEM_WB :ALUResult_MEM_WB);

    RegWdata_Sel RegWdata (
          .MemRdata (       MemRdata_MEM_WB),
          .Rt_data  (      RegRdata2_MEM_WB),
          .LW       (             LW_MEM_WB),
          .vaddr    ( ALUResult_MEM_WB[1:0]),
          .LB       (             LB_MEM_WB),
          .LBU      (            LBU_MEM_WB),
          .LH       (             LH_MEM_WB),
          .LHU      (            LHU_MEM_WB),
          .RegWdata (        MemRdata_Final)
    );

endmodule //writeback_stage

module RegWdata_Sel(
    input  [31:0] MemRdata,
    input  [31:0]  Rt_data,
    input  [ 1:0]       LW,
    input  [ 1:0]    vaddr,
    input               LB,
    input              LBU,
    input               LH,
    input              LHU,
    output [31:0] RegWdata
);
    wire [31:0] LWL_data, LWR_data;
    wire [3:0] v;
    wire LWL, LWR;
    wire [7:0]  LB_data;
    wire [15:0] LH_data;

    assign LWL =  LW[1] & ~LW[0];
    assign LWR = ~LW[1] &  LW[0];

    assign v[3] =  vaddr[1] &  vaddr[0];
    assign v[2] =  vaddr[1] & ~vaddr[0];
    assign v[1] = ~vaddr[1] &  vaddr[0];
    assign v[0] = ~vaddr[1] & ~vaddr[0];

    assign LWL_data = ({32{v[0]}} & {MemRdata[ 7:0],Rt_data[23:0]} | {32{v[1]}} & {MemRdata[15:0],Rt_data[15:0]}) |
                      ({32{v[2]}} & {MemRdata[23:0],Rt_data[ 7:0]} | {32{v[3]}} & MemRdata);

    assign LWR_data = ({32{v[3]}} & {Rt_data[31: 8],MemRdata[31:24]} | {32{v[2]}} & {Rt_data[31:16],MemRdata[31:16]}) |
                      ({32{v[1]}} & {Rt_data[31:24],MemRdata[31: 8]} | {32{v[0]}} & MemRdata);
                      
    assign LB_data = ({8{v[0]}} & MemRdata[ 7: 0] | {8{v[1]}} & MemRdata[15: 8]) |
                     ({8{v[2]}} & MemRdata[23:16] | {8{v[3]}} & MemRdata[31:24]) ;
                    
    assign LH_data = {16{v[0]}} & MemRdata[15: 0] |
                     {16{v[2]}} & MemRdata[31:16] ; //no exceptions

    assign RegWdata = (({32{&LW}} & MemRdata | {32{ LB}} & {{24{LB_data[7]}},  LB_data}) | ({32{LBU}} & {24'd0,LB_data} | {32{ LH}} & {{16{LH_data[15]}}, LH_data})) |
                      (({32{LHU}} & {16'd0,LH_data} | {32{LWL}} & LWL_data) |  {32{LWR}} & LWR_data) ;
endmodule // RegWdata_Sel
