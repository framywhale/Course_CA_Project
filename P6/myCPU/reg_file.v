/*----------------------------------------------------------------*
// Filename      :  reg_file.v
// Description   :  5 pipelined CPU general register files
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/
`timescale 10ns / 1ns
     
`define DATA_WIDTH 32
`define ADDR_WIDTH 5
     
module reg_file(
    input                      clk,
    input                      rst,
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr1,
    input  [`ADDR_WIDTH - 1:0] raddr2,
    input  [              3:0] wen,
    input  [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);

    reg [`DATA_WIDTH - 1:0] mem [0:(1 << `ADDR_WIDTH )- 1];
    integer i;
    always @ (posedge clk)
    begin
    if (rst == 1)
        begin
        for (i = 0; i < 1 << `ADDR_WIDTH  ; i = i + 1)
            mem[i] <= `DATA_WIDTH'd0;
        end
    else if (wen != 4'd0 && waddr != 5'd0) begin
        mem[waddr][31:24] <= {8{wen[3]}} & wdata[31:24];
        mem[waddr][23:16] <= {8{wen[2]}} & wdata[23:16];
        mem[waddr][15: 8] <= {8{wen[1]}} & wdata[15: 8];
        mem[waddr][ 7: 0] <= {8{wen[0]}} & wdata[ 7: 0];
        end
    end

    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

endmodule // general register files
