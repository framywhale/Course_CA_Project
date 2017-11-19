/*----------------------------------------------------------------*
// Filename      :  MUX_4_32.v
// Description   :  5 pipelined CPU MUX 
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module MUX_4_32(
    input  [31:0] Src1,
    input  [31:0] Src2,
    input  [31:0] Src3,
    input  [31:0] Src4,
    input  [ 1:0] op,
    output [31:0] Result
  );
    wire [31:0] and1, and2, and3, and4, op1, op1x, op0, op0x;

    assign op1  = {32{ op[1]}};
    assign op1x = {32{~op[1]}};
    assign op0  = {32{ op[0]}};
    assign op0x = {32{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;
    assign and4 = Src4   & op1  & op0;

    assign Result = (and1 | and2) | (and3 | and4);

endmodule // MUX_4_32
