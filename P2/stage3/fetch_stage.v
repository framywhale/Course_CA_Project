/*
  ------------------------------------------------------------------------------
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

module fetch_stage(
    input  wire        clk,
    input  wire        rst,
    // data passing from the PC calculate module
    input  wire    IRWrite,
    // For Stall
    input  wire [31:0] PC_next,
    // interaction with inst_sram
    output wire        inst_sram_en,
    input  wire [31:0] inst_sram_rdata,
    // data transfering to ID stage
    output reg  [31:0]       PC_IF_ID,           //fetch_stage pc
    output reg  [31:0] PC_add_4_IF_ID,
    output reg  [31:0]     Inst_IF_ID            //instr code sent from fetch_stage
  );
    parameter reset_addr = 32'hbfc00000;

    assign inst_sram_en = ~rst;

    always @ (posedge clk) begin
      if(rst) begin
          PC_IF_ID       <= reset_addr;
          PC_add_4_IF_ID <= reset_addr+4;
          Inst_IF_ID     <= 32'd0;
      end
      else if (IRWrite) begin
          PC_IF_ID       <= PC_next;
          PC_add_4_IF_ID <= PC_next+4;
          Inst_IF_ID     <= inst_sram_rdata;
      end
      else begin
          PC_IF_ID       <= PC_IF_ID;
          PC_add_4_IF_ID <= PC_add_4_IF_ID;
          Inst_IF_ID     <= Inst_IF_ID;
      end
    end
endmodule //fetch_stage

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
