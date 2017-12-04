/*----------------------------------------------------------------*
// Filename      :  mycpu_top.v
// Description   :  5 pipelined CPU top
// Author        :  Gou Lingrui & Wu Jiahao
// Created Time  :  2017-12-04 15:24:31
//----------------------------------------------------------------*/

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
  );


// need axi interface instantialization
// need cpu instantialization

endmodule