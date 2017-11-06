/*------------------------------------------------------------------------------
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
------------------------------------------------------------------------------*/


module nextpc_gen(
    input  wire        clk,
    input  wire        rst,
    input  wire    PCWrite,  //For Stall
    input  wire        JSrc,
    input  wire [ 1:0] PCSrc,
    input  wire [31:0] JR_target,
    input  wire [31:0] J_target,
    input  wire [31:0] Br_addr,
    output reg  [31:0] PC_next,
    output wire [31:0] inst_sram_addr
  );
    parameter reset_addr = 32'hbfc00000;
    
    wire [31:0] Jump_addr, inst_addr;
    assign Jump_addr = JSrc ? JR_target : J_target; 
    assign inst_sram_addr = PCWrite ? inst_addr : PC_next;
  
    reg [31:0] PC;
    always @(posedge clk) begin
        if(rst) begin
            PC      <= reset_addr;
            PC_next <= reset_addr;
        end
        else if(PCWrite) begin
            PC      <= inst_addr+4;
            PC_next <= inst_addr;
        end
        else begin
            PC      <= PC;
            PC_next <= PC_next;
        end
    end
     
    MUX_4_32 PCS_MUX(
        .Src1   (         PC),
        .Src2   (  Jump_addr),
        .Src3   (    Br_addr),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (  inst_addr)
    );
    

endmodule //nextpc_gen
