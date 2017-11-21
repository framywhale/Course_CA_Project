/*----------------------------------------------------------------*
// Filename      :  fetch_stage.v
// Description   :  5 pipelined CPU fetch stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns

module fetch_stage(
    input  wire        clk,
    input  wire        rst,
    // delay slot tag
    input  wire      DSI_ID, // delay slot instruction tag
    // data passing from the PC calculate module
    input  wire     IRWrite,
    // For Stall
    input  wire [31:0] PC_next,
    input  wire        PC_AdEL,
    // interaction with inst_sram
    output wire        inst_sram_en,
    input  wire [31:0] inst_sram_rdata,
    // data transfering to ID stage
    output reg  [31:0]       PC_IF_ID,           //fetch_stage pc
    output reg  [31:0] PC_add_4_IF_ID,
    output reg  [31:0]     Inst_IF_ID,           //instr code sent from fetch_stage
    // signal passing to ID stage
    output reg          PC_AdEL_IF_ID,
    output reg              DSI_IF_ID
  );
    parameter reset_addr = 32'hbfc00000;

    assign inst_sram_en = ~rst;

    always @ (posedge clk) begin
      if(rst) begin
          DSI_IF_ID      <= 1'b0;
          PC_AdEL_IF_ID  <= 1'b0;
          PC_IF_ID       <= reset_addr;
          PC_add_4_IF_ID <= reset_addr+4;
          Inst_IF_ID     <= 32'd0;      
      end
      else if (IRWrite) begin
          DSI_IF_ID      <= DSI_ID;
          PC_AdEL_IF_ID  <= PC_AdEL;
          PC_IF_ID       <= PC_next;
          PC_add_4_IF_ID <= PC_next+32'd4;
          Inst_IF_ID     <= inst_sram_rdata;
      end
      else begin
          DSI_IF_ID      <=      DSI_IF_ID;
          PC_AdEL_IF_ID  <=  PC_AdEL_IF_ID;
          PC_IF_ID       <=       PC_IF_ID;
          PC_add_4_IF_ID <= PC_add_4_IF_ID;
          Inst_IF_ID     <=     Inst_IF_ID;
      end
    end

endmodule //fetch_stage

/*
module Adder(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] Result
  );
    ALU adder(
        .A      (      A),
        .B      (      B),
        .ALUop  (4'b0010),   //ADD
        .Result ( Result)
    );
endmodule
*/
