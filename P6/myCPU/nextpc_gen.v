/*----------------------------------------------------------------*
// Filename      :  nextpc_gen.v
// Description   :  5 pipelined CPU generate next PC
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module nextpc_gen(
    input              clk            ,
    input              rst            ,
    input              PCWrite        ,  // For Stall
    input              JSrc           ,
    input              eret           ,   
    input              ex_int_handle  ,            
    input       [ 1:0] PCSrc          ,    
    input       [31:0] JR_target      ,        
    input       [31:0] J_target       ,       
    input       [31:0] Br_addr        ,      
    input       [31:0] epc            , 

    output             PC_AdEL        ,  
    output      [31:0] inst_sram_addr ,
    output reg         PC_abnormal    ,
    output reg  [31:0] PC_buffer      ,
    input              PC_fresh          

  );

    parameter reset_addr  = 32'hbfc00000;
    parameter except_addr = 32'hbfc00380;
    
    reg PC_AdEL_r;
    
    wire [31:0] Jump_addr, inst_addr, PC_mux;

    assign Jump_addr = JSrc ? JR_target : J_target; 

    assign inst_addr = ex_int_handle  ? except_addr : 
                                eret  ? epc         : PC_mux;

    assign inst_sram_addr = PC_next;

    assign PC_AdEL = PC_AdEL_r;

    reg first_fetch;

    reg [31:0] PC,PC_next;

    always @(posedge clk) begin
        if (rst) begin
            PC          <= reset_addr;
            PC_next     <= reset_addr;
            PC_AdEL_r   <= 'd0;
            PC_abnormal <= 'd0;
        end
        else if (PC_fresh) begin
            PC_next      <= inst_addr;
            PC           <= PC_next + 32'd4;
            PC_buffer    <= PC_next;
            PC_AdEL_r    <= |PC_next[1:0] ? 1'b1 : 1'b0;
            PC_abnormal  <= ex_int_handle | eret;
        end
    end
     
    MUX_4_32 PCS_MUX(
        .Src1   (         PC),
        .Src2   (  Jump_addr),
        .Src3   (    Br_addr),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (     PC_mux)
    ); 

endmodule //nextpc_gen
