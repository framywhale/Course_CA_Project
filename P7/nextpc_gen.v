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

    output reg         PC_AdEL        ,  
    output reg  [31:0] PC             ,
    output reg  [31:0] PC_buffer      ,
    input              PC_refresh          

  );
    parameter reset_addr  = 32'hbfc00000;
    parameter except_addr = 32'hbfc00380;
    
    reg [31:0] PC_next;
        
    wire [31:0] Jump_addr, inst_addr, PC_mux;

    assign Jump_addr = JSrc ? JR_target : J_target;             //Select target address for JUMP and JUMP_REGISTER

    assign inst_addr = ex_int_handle  ? except_addr : 
                                eret  ? epc         : PC_mux;   //Select PC being refreshed next

    always @(posedge clk) begin
        if (rst) begin
            PC          <= reset_addr;
            PC_next     <= reset_addr + 32'd4;
            PC_buffer   <= 'd0;
            PC_AdEL     <= 'd0;
        end
        else if (PC_refresh) begin
            PC          <= inst_addr;               //To axi_araddr
            PC_next     <= inst_addr + 32'd4;       //To PC_mux For next value of PC
            PC_buffer   <= PC;                      //Wait to write into PC_IF_ID
            PC_AdEL     <= |PC[1:0] ? 1'b1 : 1'b0;  //For PC address excpetion
        end
        else begin
            PC_next     <= PC_next;
            PC          <= PC;
            PC_buffer   <= PC_buffer;
            PC_AdEL     <= PC_AdEL  ;
        end
    end
     
    MUX_4_32 PCS_MUX(
        .Src1   (    PC_next),
        .Src2   (  Jump_addr),
        .Src3   (    Br_addr),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (     PC_mux)
    ); 

endmodule //nextpc_gen
