/*----------------------------------------------------------------*
// Filename      :  mycpu_top.v
// Description   :  5 pipelined CPU top
// Author        :  Gou Lingrui & Wu Jiahao
// Created Time  :  2017-12-04 15:24:31
//----------------------------------------------------------------*/
`define SIMU_DEBUG
`timescale 10ns / 1ns

module mycpu_top(
    input  wire        clk,
    input  wire        resetn, 
    input  wire [ 5:0] int_i,
    // read address channel
    output wire [ 3:0] cpu_arid,         // M->S 
    output wire [31:0] cpu_araddr,       // M->S 
    output wire [ 7:0] cpu_arlen,        // M->S 
    output wire [ 2:0] cpu_arsize,       // M->S 
    output wire [ 1:0] cpu_arburst,      // M->S 
    output wire [ 1:0] cpu_arlock,       // M->S 
    output wire [ 3:0] cpu_arcache,      // M->S 
    output wire [ 2:0] cpu_arprot,       // M->S 
    output wire        cpu_arvalid,      // M->S 
    input  wire        cpu_arready,      // S->M 
    // read data channel
    input  wire [ 3:0] cpu_rid,          // S->M 
    input  wire [31:0] cpu_rdata,        // S->M 
    input  wire [ 1:0] cpu_rresp,        // S->M 
    input  wire        cpu_rlast,        // S->M 
    input  wire        cpu_rvalid,       // S->M 
    output wire        cpu_rready,       // M->S
    // write address channel 
    output wire [ 3:0] cpu_awid,         // M->S
    output wire [31:0] cpu_awaddr,       // M->S
    output wire [ 7:0] cpu_awlen,        // M->S
    output wire [ 2:0] cpu_awsize,       // M->S
    output wire [ 1:0] cpu_awburst,      // M->S
    output wire [ 1:0] cpu_awlock,       // M->S
    output wire [ 3:0] cpu_awcache,      // M->S
    output wire [ 2:0] cpu_awprot,       // M->S
    output wire        cpu_awvalid,      // M->S
    input  wire        cpu_awready,      // S->M
    // write data channel
    output wire [ 3:0] cpu_wid,          // M->S
    output wire [31:0] cpu_wdata,        // M->S
    output wire [ 3:0] cpu_wstrb,        // M->S
    output wire        cpu_wlast,        // M->S
    output wire        cpu_wvalid,       // M->S
    input  wire        cpu_wready,       // S->M
    // write response channel
    input  wire [ 3:0] cpu_bid,          // S->M 
    input  wire [ 1:0] cpu_bresp,        // S->M 
    input  wire        cpu_bvalid,       // S->M 
    output wire        cpu_bready        // M->S 

    // debug signals
  `ifdef SIMU_DEBUG
   ,output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
  `endif    
  );


mycpu cpu(
    .clk                 ( clk               ),
    .resetn              ( resetn            ),
    .int_i               ( int_i             ),

    .inst_req            ( inst_req          ),
    .inst_wr             ( inst_wr           ),
    .inst_size           ( inst_size         ),
    .inst_addr           ( inst_addr         ),
    .inst_wdata          ( inst_wdata        ),
    .inst_rdata          ( inst_rdata        ),
    .inst_addr_ok        ( inst_addr_ok      ),
    .inst_data_ok        ( inst_data_ok      ),

    .data_req            ( data_req          ),
    .data_wr             ( data_wr           ),
    .data_size           ( data_size         ),
    .data_addr           ( data_addr         ),
    .data_wdata          ( data_wdata        ),
    .data_rdata          ( data_rdata        ),
    .data_addr_ok        ( data_addr_ok      ),
    .data_data_ok        ( data_data_ok      ),

    //debug
    .debug_wb_pc         ( debug_wb_pc       ),
    .debug_wb_rf_wen     ( debug_wb_rf_wen   ),
    .debug_wb_rf_wnum    ( debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata   ( debug_wb_rf_wdata )
);


cpu_axi_interface axi_interface(
    .clk                 ( clk              ),
    .resetn              ( resetn           ),
                         
    .inst_req            ( inst_req         ),   
    .inst_wr             ( inst_wr          ),  
    .inst_size           ( inst_size        ),    
    .inst_addr           ( inst_addr        ),    
    .inst_wdata          ( inst_wdata       ),     
    .inst_rdata          ( inst_rdata       ),     
    .inst_addr_ok        ( inst_addr_ok     ),       
    .inst_data_ok        ( inst_data_ok     ),       
                                                                    
    .data_req            ( data_req         ),   
    .data_wr             ( data_wr          ),  
    .data_size           ( data_size        ),    
    .data_addr           ( data_addr        ),    
    .data_wdata          ( data_wdata       ),     
    .data_rdata          ( data_rdata       ),     
    .data_addr_ok        ( data_addr_ok     ),       
    .data_data_ok        ( data_data_ok     ),       
                                                                    
    .arid                ( cpu_arid         ), 
    .araddr              ( cpu_araddr       ), 
    .arlen               ( cpu_arlen        ), 
    .arsize              ( cpu_arsize       ), 
    .arburst             ( cpu_arburst      ), 
    .arlock              ( cpu_arlock       ), 
    .arcache             ( cpu_arcache      ), 
    .arprot              ( cpu_arprot       ), 
    .arvalid             ( cpu_arvalid      ), 
    .arready             ( cpu_arready      ), 
                                                                                    
    .rid                 ( cpu_rid          ), 
    .rdata               ( cpu_rdata        ), 
    .rresp               ( cpu_rresp        ), 
    .rlast               ( cpu_rlast        ), 
    .rvalid              ( cpu_rvalid       ), 
    .rready              ( cpu_rready       ), 
                                      
    .awid                ( cpu_awid         ), 
    .awaddr              ( cpu_awaddr       ), 
    .awlen               ( cpu_awlen        ), 
    .awsize              ( cpu_awsize       ), 
    .awburst             ( cpu_awburst      ), 
    .awlock              ( cpu_awlock       ), 
    .awcache             ( cpu_awcache      ), 
    .awprot              ( cpu_awprot       ), 
    .awvalid             ( cpu_awvalid      ), 
    .awready             ( cpu_awready      ), 
                               
    .wid                 ( cpu_wid          ), 
    .wdata               ( cpu_wdata        ), 
    .wstrb               ( cpu_wstrb        ), 
    .wlast               ( cpu_wlast        ), 
    .wvalid              ( cpu_wvalid       ), 
    .wready              ( cpu_wready       ), 
                               
    .bid                 ( cpu_bid          ), 
    .bresp               ( cpu_bresp        ), 
    .bvalid              ( cpu_bvalid       ), 
    .bready              ( cpu_bready       )  
);    


endmodule