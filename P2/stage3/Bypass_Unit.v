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

module Bypass_Unit(
    input  wire        clk,
    input  wire        rst,
    // input IR recognize signals from Control Unit
    // to judge whether rs or rt is need to read
    input  wire        is_rs_read,
    input  wire        is_rt_read,
    // Judge whether the instruction is LW
    input  wire        MemToReg_ID_EXE,
    input  wire        MemToReg_EXE_MEM,
    input  wire        MemToReg_MEM_WB,
    // Reg Write address in afterward stages
    input  wire [ 4:0] RegWaddr_EXE_MEM,
    input  wire [ 4:0] RegWaddr_MEM_WB,
    input  wire [ 4:0] RegWaddr_ID_EXE,
    // RegWrite signals in afterward stages
    input  wire [ 3:0] RegWrite_ID_EXE,
    input  wire [ 3:0] RegWrite_EXE_MEM,
    input  wire [ 3:0] RegWrite_MEM_WB,
    // Reg read address in ID stage
    input  wire [ 4:0] rs_ID,
    input  wire [ 4:0] rt_ID,
    // output stall signals
    output wire        PCWrite,
    output wire        IRWrite,
    output wire        ID_EXE_Stall,
    // output mux signals to choose data sources
    output wire [ 1:0] RegRdata1_src,
    output wire [ 1:0] RegRdata2_src
  );
    // choose the address to compare with
    // reg write address in afterward stages
    wire [ 4:0] rs_read, rt_read;
    assign rs_read = (is_rs_read) ? rs_ID : 5'd0;
    assign rt_read = (is_rt_read) ? rt_ID : 5'd0;

    // define the hazard addresses and the relationship
    // of each situation
    wire Haz_ID_EXE_rs, Haz_ID_EXE_rt,
         Haz_ID_MEM_rs, Haz_ID_MEM_rt,
         Haz_ID_WB_rs,  Haz_ID_WB_rt;

    assign Haz_ID_EXE_rs = (|RegWaddr_ID_EXE) & (|rs_read)
                         & (&(rs_read^~RegWaddr_ID_EXE)) & (|RegWrite_ID_EXE);
    assign Haz_ID_EXE_rt = (|RegWaddr_ID_EXE) & (|rt_read)
                         & (&(rt_read^~RegWaddr_ID_EXE)) & (|RegWrite_ID_EXE);

    assign Haz_ID_MEM_rs = (|RegWaddr_EXE_MEM) & (|rs_read)
                         & (&(rs_read^~RegWaddr_EXE_MEM)) & (|RegWrite_EXE_MEM);
    assign Haz_ID_MEM_rt = (|RegWaddr_EXE_MEM) & (|rt_read)
                         & (&(rt_read^~RegWaddr_EXE_MEM)) & (|RegWrite_EXE_MEM);

    assign Haz_ID_WB_rs  = (|RegWaddr_MEM_WB) & (|rs_read)
                         & (&(rs_read^~RegWaddr_MEM_WB)) & (|RegWrite_MEM_WB);
    assign Haz_ID_WB_rt  = (|RegWaddr_MEM_WB) & (|rt_read)
                         & (&(rt_read^~RegWaddr_MEM_WB)) & (|RegWrite_MEM_WB);

    assign RegRdata1_src = Haz_ID_EXE_rs ? 2'b01 :
                          (Haz_ID_MEM_rs ? 2'b10 :
                          (Haz_ID_WB_rs  ? 2'b11 : 2'b00));
    assign RegRdata2_src = Haz_ID_EXE_rt ? 2'b01 :
                          (Haz_ID_MEM_rt ? 2'b10 :
                          (Haz_ID_WB_rt  ? 2'b11 : 2'b00));

    assign ID_EXE_Stall = ((Haz_ID_EXE_rt |  Haz_ID_EXE_rs) & MemToReg_ID_EXE)
                        | (((Haz_ID_MEM_rt & ~Haz_ID_EXE_rt)
                        |   (Haz_ID_MEM_rs & ~Haz_ID_EXE_rs))
                        &    MemToReg_EXE_MEM);

    assign PCWrite = ~ID_EXE_Stall;
    assign IRWrite = ~ID_EXE_Stall;

endmodule
