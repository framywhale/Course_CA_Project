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
    input wire  [ 1:0]       MFHL_MEM_WB,
    input wire                 LB_MEM_WB, //new
    input wire                LBU_MEM_WB, //new
    input wire                 LH_MEM_WB, //new
    input wire                LHU_MEM_WB, //new
    input wire  [ 1:0]         LW_MEM_WB, //new

    // control from EXE
    input  wire [ 1:0]       MFHL_ID_EXE,
    // data passing from MEM stage
    input wire  [ 4:0]   RegWaddr_MEM_WB,
    input wire  [31:0]  ALUResult_MEM_WB,
    input wire  [31:0]  RegRdata2_MEM_WB, //new
    input wire  [31:0]         PC_MEM_WB,
    input wire  [31:0]   MemRdata_MEM_WB,
    input wire  [31:0]         HI_MEM_WB,
    input wire  [31:0]         LO_MEM_WB,
    // data that will be used to write back to Register files
    // or be used as debug signals
    output wire [ 4:0]       RegWaddr_WB,
    output wire [31:0]       RegWdata_WB,
    output wire [31:0]       RegWdata_Bypass_WB,
    output wire [ 3:0]       RegWrite_WB,
    output wire [31:0]             PC_WB,
    
    input  wire [31:0]   cp0Rdata_MEM_WB,
    input  wire              mfc0_MEM_WB
);
    wire        MemToReg_WB;
    wire  [31:0]  HI_LO_out;
    
    wire  [31:0] MemRdata_Final;

    assign HI_LO_out = {32{MFHL_MEM_WB[1]}} & HI_MEM_WB |
                       {32{MFHL_MEM_WB[0]}} & LO_MEM_WB;  //2-1 MUX


    assign       PC_WB =       PC_MEM_WB;
    assign RegWaddr_WB = RegWaddr_MEM_WB;
    assign MemToReg_WB = MemToReg_MEM_WB;
    assign RegWrite_WB = RegWrite_MEM_WB;
    assign RegWdata_WB = |MFHL_MEM_WB ? HI_LO_out : (MemToReg_WB ? MemRdata_Final : (mfc0_MEM_WB ? cp0Rdata_MEM_WB : ALUResult_MEM_WB));
    assign RegWdata_Bypass_WB = |MFHL_MEM_WB ? HI_LO_out : (mfc0_MEM_WB ? cp0Rdata_MEM_WB :ALUResult_MEM_WB);

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
endmodule
