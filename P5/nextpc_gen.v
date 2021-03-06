/*----------------------------------------------------------------*
// Filename      :  nextpc_gen.v
// Description   :  5 pipelined CPU generate next PC
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module nextpc_gen(
    input  wire        clk,
    input  wire        rst,
    input  wire        PCWrite,  // For Stall
    input  wire        JSrc,
 //   input  wire        trap,
    input  wire        eret,
    input  wire        ex_int_handle,
    input  wire [ 1:0] PCSrc,
    input  wire [31:0] JR_target,
    input  wire [31:0] J_target,
    input  wire [31:0] Br_addr,
    input  wire [31:0] epc,
    output wire        PC_AdEL,
    output reg  [31:0] PC_next,
    output wire [31:0] inst_sram_addr
  );
    parameter reset_addr  = 32'hbfc00000;
    parameter except_addr = 32'hbfc00380;
    
    wire [31:0] Jump_addr, inst_addr, PC_mux;

    assign Jump_addr = JSrc ? JR_target : J_target; 

    assign inst_addr = ex_int_handle  ? except_addr : 
                                eret  ? epc         : PC_mux;

    assign inst_sram_addr = PCWrite ? inst_addr  : PC_next;

    assign PC_AdEL = (|inst_sram_addr[1:0]) ? 1'b1 : 1'b0;
  
    reg [31:0] PC;
    always @(posedge clk) begin
        if(rst) begin
            PC      <= reset_addr;
            PC_next <= reset_addr;
        end
        else if(PCWrite) begin
            PC      <= inst_addr+4;
            PC_next <= inst_addr;
        end
        else begin
            PC      <= PC;
            PC_next <= PC_next;
        end
    end
     
    MUX_4_32 PCS_MUX(
        .Src1   (         PC),
        .Src2   (  Jump_addr),
        .Src3   (    Br_addr),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (     PC_mux)
    ); 

endmodule //nextpc_gen
