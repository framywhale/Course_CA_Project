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

module memory_stage(
    input  wire                       clk,
    input  wire                       rst,
    // control signals transfering from EXE stage
    input  wire             MemEn_EXE_MEM,
    input  wire          MemToReg_EXE_MEM,
    input  wire  [ 3:0]  MemWrite_EXE_MEM,
    input  wire  [ 3:0]  RegWrite_EXE_MEM,
    // data passing from EXE stage
    input  wire  [ 4:0]  RegWaddr_EXE_MEM,
    input  wire  [31:0] ALUResult_EXE_MEM,
    input  wire  [31:0]  MemWdata_EXE_MEM,
    input  wire  [31:0]        PC_EXE_MEM,
    // interaction with the data_sram
    output wire  [31:0]      MemWdata_MEM,
    output wire                 MemEn_MEM,
    output wire  [ 3:0]      MemWrite_MEM,
    output wire  [31:0]    data_sram_addr,
//    input  wire  [31:0]   data_sram_rdata,
    // output control signals to WB stage
    output reg            MemToReg_MEM_WB,
    output reg   [ 3:0]   RegWrite_MEM_WB,
    // output data to WB stage
    output reg   [ 4:0]   RegWaddr_MEM_WB,
    output reg   [31:0]  ALUResult_MEM_WB,
    output reg   [31:0]         PC_MEM_WB,
//    output wire  [31:0]   MemRdata_MEM_WB
    output wire  [31:0]     ALUResult_MEM   //Bypass
  );

// interaction of signals and data with data_sram
    assign MemEn_MEM      =     MemEn_EXE_MEM;
    assign MemWrite_MEM   =  MemWrite_EXE_MEM;
    assign data_sram_addr = ALUResult_EXE_MEM;
    assign MemWdata_MEM   =  MemWdata_EXE_MEM;

    assign ALUResult_MEM  = ALUResult_EXE_MEM;

    // output data to WB stage
    always @(posedge clk) begin
        if (~rst) begin
            PC_MEM_WB        <= PC_EXE_MEM;
            RegWaddr_MEM_WB  <= RegWaddr_EXE_MEM;
            MemToReg_MEM_WB  <= MemToReg_EXE_MEM;
            RegWrite_MEM_WB  <= RegWrite_EXE_MEM;
            ALUResult_MEM_WB <= ALUResult_EXE_MEM;
        end
        else
            {PC_MEM_WB, RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, ALUResult_MEM_WB} <= 'd0;
    end

endmodule //memory_stage
