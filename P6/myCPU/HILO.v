/*----------------------------------------------------------------*
// Filename      :  HILO.v
// Description   :  5 pipelined CPU HILO registers
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module HILO(
    input clk,
    input rst,
    input  [31:0] HI_in,
    input  [31:0] LO_in,
    input  [ 1:0] HILO_Write,
    output [31:0] HI_out,
    output [31:0] LO_out
);

    reg [31:0] HI;
    reg [31:0] LO;
    always @ (posedge clk) begin
       /* if (rst) begin
            HI <= 32'd0;
            LO <= 32'd0;
        end
        else */begin
        if (HILO_Write[1]) HI <= HI_in;
        else               HI <= HI;
        if (HILO_Write[0]) LO <= LO_in;
        else               LO <= LO;
        end
    end

    assign HI_out = HI;
    assign LO_out = LO;
endmodule
