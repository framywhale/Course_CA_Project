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
 
    input                        do_load,
    input                       data_req,
    output                 data_rdata_ok,

    output                      PC_fresh,

    output             fetch_axi_rready ,
    input              fetch_axi_rvalid ,
    input       [31:0] fetch_axi_rdata  ,
    output      [ 2:0] fetch_axi_rid    ,

    input              fetch_axi_arready,
    output             fetch_axi_arvalid,
    output             fetch_axi_arsize ,
    input              fetch_axi_arid   ,

    input                 decode_allowin 

  );
    parameter reset_addr = 32'hbfc00000;

    reg [32:0] IR_buffer,IR;
    reg arvalid_r, first_fetch;

    assign IR_IF_ID = IR;
    assign PC_fresh = fetch_axi_rvalid && fetch_axi_rready && !do_load;

    assign fetch_axi_arsize = 3'b010;

    assign fetch_axi_rready = decode_allowin & IRWrite | do_load;
    wire   fetch_ready_go = fetch_axi_rvalid && (fetch_axi_rid == 3'd0) 
                            || (IR_buffer[32] == 1'b1);

    assign data_rdata_ok  = !decode_allowin  && (fetch_axi_rid == 3'd1) 
                          && fetch_axi_rvalid;
    
    always @(posedge clk) begin   // arvalid -> read address channel  
      if (rst) begin 
        arvalid_r   <=  1'b0;
        first_fetch <=  1'b1;
      end
      else if ( first_fetch || do_load || PC_fresh ) begin 
        arvalid_r   <= 1'b1;
        first_fetch <= 1'b0;
      end
      else if (fetch_axi_arready && arvalid_r) begin
        arvalid_r   <= 1'b0;
        first_fetch <= 1'b0;
      end
    end

    always @(posedge clk) begin // rdata 
      if (rst) begin
        IR             <= 32'd0;
        IR_buffer      <= 33'd0;
        PC_IF_ID       <= 32'd0;
        PC_add_4_IF_ID <= 32'd0;
        PC_AdEL_IF_ID  <=  1'd0;
        DSI_IF_ID      <=  1'd0;
      end
      else if (!decode_allowin && (fetch_axi_rid == 3'd0 && fetch_axi_rvalid)) begin // inst data return first
        IR_buffer <= {1'b1,fetch_axi_rdata};
        // fetch_axi_rready <= 1'b1; // ??? I think it is not right
      end
      // else if (!decode_allowin && (fetch_axi_rid == 3'd1 && fetch_axi_rvalid)) begin // mem  data return first
      //   fetch_axi_rready <= 1'b1; // ??? I think it is not right, also.
      // end
      else if (decode_allowin && fetch_ready_go) begin // I'm afraid of multi-driving problem                                    
        if (IR_buffer[32]) begin                       // Think twice when practising
          IR        <= IR_buffer[31:0];                // There are some problems when interacting with AXI
          IR_buffer <= 33'd0;                          // We need discuss.
        end
        else begin
          IR        <= fetch_axi_rdata;
        end 
        PC_IF_ID       <= PC_buffer;
        PC_add_4_IF_ID <= PC_buffer + 32'd4;
        PC_AdEL_IF_ID  <= PC_AdEL;
        DSI_IF_ID      <= DSI_ID;
      end
   end

endmodule //fetch_stage
