/*----------------------------------------------------------------*
// Filename      :  fetch_stage.v
// Description   :  5 pipelined CPU fetch stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns

module fetch_stage(
    input                            clk,
    input                            rst,
    // delay slot tag  
    input                         DSI_ID, // delay slot instruction tag
    // data passing from the PC calculate module
    input                        IRWrite,
    // For Stall  
    input                 decode_allowin,
    input       [31:0]         PC_buffer,
    input                        PC_AdEL,
    input                    PC_abnormal,
    input       [31:0]   inst_sram_rdata,
    // data transfering   to ID stage
    output reg  [31:0]          PC_IF_ID,           //fetch_stage pc
    output reg  [31:0]    PC_add_4_IF_ID,
    output      [31:0]          IR_IF_ID,           //instr code sent from fetch_stage
    // signal passing to   ID stage
    output reg             PC_AdEL_IF_ID,
    output reg                 DSI_IF_ID,
 
    input                       data_req,
    output                 data_rdata_ok,

    output                  inst_addr_ok,

    output             fetch_axi_rready ,
    input              fetch_axi_rvalid ,
    input       [31:0] fetch_axi_rdata  ,
    output      [ 2:0] fetch_axi_rid    ,

    input              fetch_axi_arready,
    input              fetch_axi_araddr ,
    input              fetch_axi_arvalid,
    output             fetch_axi_arsize ,
    input              fetch_axi_arid   ,

    input               decode_allowin,
    input                     loadtype

  );
    parameter reset_addr = 32'hbfc00000;

    reg [32:0] IR_buffer;
    reg arvalid_r, first_fetch;

    assign IR_IF_ID = IR;
    assign fetch_axi_rready = decode_allowin & IRWrite | loadtype;

    assign data_rdata_ok  = !decode_allowin  && (fetch_axi_rid == 3'd1) 
                          && fetch_axi_rvalid;

    assign fetch_ready_go = fetch_axi_rvalid && (fetch_axi_rid == 3'd0) 
                            || (IR_buffer[32] == 1'b1);

    always @(posedge clk) begin   // arvalid | read address channel  
      if (rst) begin 
        arvalid_r   <=  1'b0;
        first_fetch <=  1'b1;
      end
      else if ( first_fetch || loadtype || 
               (fetch_axi_rready && fetch_axi_rvalid && (fetch_axi_rid == 3'd0))) begin 
        arvalid_r   <= 1'b1;
        first_fetch <= 1'b0;
      end
      else if (fetch_axi_arready && arvalid_r && (fetch_axi_arid == 3'd0)) begin
        arvalid_r   <= 1'b0;
      end
    end

    always @(posedge clk) begin // rdata 
      if (rst) begin
        IR          <= 32'd0;
        IR_buffer   <= 33'd0;
      end
      else if (!decode_allowin && (fetch_axi_rid == 3'd0)) begin // inst data return first
        IR_buffer        <= {1'b1,fetch_axi_rdata};
        fetch_axi_rready <= 1'b1; // ??? I think it is not right
      end
      else if (!decode_allowin && (fetch_axi_rid == 3'd1)) begin // mem  data return first
        fetch_axi_rready <= 1'b1; // ??? I think it is not right, also.
      end
      else if (decode_allowin && fetch_ready_go) begin // I'm afraid of multi-driving problem                                    
        if (IR_buffer[32]) begin                       // Think twice when practising
          IR        <= IR_buffer[31:0];                // There are some problems when interacting with AXI
          IR_buffer <= 33'd0;                          // We need discuss.
        end
        else begin
          IR        <= fetch_axi_rdata;
        end 
      end
    end


endmodule //fetch_stage

/*

    always @(posedge clk) begin
      if (rst) begin
        IR <= 32'd0;
        IR_buffer <= 33'd0;
      end
      else begin
        if (decode_allowin && (axi_rid=='d0&&axi_rready&&axi_rvalid)) begin
          IR <= axi_rdata;
        end
        else if (decode_allowin && (IR_buffer[32])) begin
          IR <= IR_buffer[31:0];
        end
      end
    end

    always @(posedge clk) begin
      if (rst) begin
        IR_buffer <= 33'd0;
        IR        <= 32'd0;
      end
      else if ( decode_allowin ) begin
        IR_buffer <= loadtype ? {1'b1,axi_rdata} : 33'd0;
        IR        <= (IR_buffer[32] == 1) ? IR_buffer : axi_rdata; 
      end
    end

 */