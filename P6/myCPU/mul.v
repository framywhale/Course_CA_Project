/*----------------------------------------------------------------*
// Filename      :  mul.v
// Description   :  5 pipelined CPU multiplier unit
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module multiplyer(
    input  [31:0] x,
    input  [31:0] y,
    input  mul_clk,
    input  resetn,
    input  clken,
    input  mul_signed,
    output [63:0] result
  );

  wire        rst = ~resetn;
  wire        clk = mul_clk;
  wire [65:0] temp_signed_r, temp_unsigned_r;
  reg         temp_sign_r;

  wire [32:0] x_r = mul_signed ? {x[31],x} : {{1'b0}, x};
  wire [32:0] y_r = mul_signed ? {y[31],y} : {{1'b0}, y};




  mult_signed Signed_Muliplier(
      .CLK  (clk),
      .A    (x_r),
      .B    (y_r),
      .P    (temp_signed_r)
  );

  assign result = temp_signed_r[63:0];

endmodule // multiplier
