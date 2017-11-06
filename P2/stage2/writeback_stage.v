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

module writeback_stage(
    input wire                       clk,
    input wire                       rst,
    // control signals passing from MEM stage
    input wire           MemToReg_MEM_WB,
    input wire  [ 3:0]   RegWrite_MEM_WB,
    // data passing from MEM stage
    input wire  [ 4:0]   RegWaddr_MEM_WB,
    input wire  [31:0]  ALUResult_MEM_WB,
    input wire  [31:0]         PC_MEM_WB,
    input wire  [31:0]   MemRdata_MEM_WB,
    // data that will be used to write back to Register files
    // or be used as debug signals
    output wire [ 3:0]       RegWrite_WB,
    output wire [ 4:0]       RegWaddr_WB,
    output wire [31:0]       RegWdata_WB,
    output wire [31:0]             PC_WB
);
    wire MemToReg_WB;
    
    assign       PC_WB =       PC_MEM_WB;
    assign RegWaddr_WB = RegWaddr_MEM_WB;
    assign MemToReg_WB = MemToReg_MEM_WB;
    assign RegWrite_WB = RegWrite_MEM_WB;
    assign RegWdata_WB = MemToReg_WB ? MemRdata_MEM_WB : ALUResult_MEM_WB;

endmodule //writeback_stage
