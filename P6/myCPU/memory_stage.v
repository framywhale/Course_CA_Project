/*----------------------------------------------------------------*
// Filename      :  memory_stage.v
// Description   :  5 pipelined CPU memory stage
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`timescale 10ns / 1ns
module memory_stage(
    input  wire                       clk,
    input  wire                       rst,
    // control signals transfering from EXE stage
    input  wire             MemEn_EXE_MEM,
    input  wire          MemToReg_EXE_MEM,
    input  wire  [ 3:0]  MemWrite_EXE_MEM,
    input  wire  [ 3:0]  RegWrite_EXE_MEM,
    input  wire  [ 1:0]      MFHL_EXE_MEM,
    input  wire                LB_EXE_MEM, 
    input  wire               LBU_EXE_MEM, 
    input  wire                LH_EXE_MEM, 
    input  wire               LHU_EXE_MEM, 
    input  wire  [ 1:0]        LW_EXE_MEM, 
    // data passing from EXE stage
    input  wire  [ 4:0]  RegWaddr_EXE_MEM,
    input  wire  [31:0] ALUResult_EXE_MEM,
    input  wire  [31:0]  MemWdata_EXE_MEM,
    input  wire  [31:0] RegRdata2_EXE_MEM, 
    input  wire  [31:0]        PC_EXE_MEM,
    input  wire  [ 1:0]   s_vaddr_EXE_MEM,
    input  wire  [ 2:0]    s_size_EXE_MEM,

    // interaction with the data_sram
    output wire  [31:0]      MemWdata_MEM,
    output wire                 MemEn_MEM,
    output wire  [ 3:0]      MemWrite_MEM,
    output wire  [31:0]    data_sram_addr,
    // output control signals to WB stage
    output reg            MemToReg_MEM_WB,
    output reg   [ 3:0]   RegWrite_MEM_WB,
    output reg   [ 1:0]       MFHL_MEM_WB,
    output reg                  LB_MEM_WB,
    output reg                 LBU_MEM_WB,
    output reg                  LH_MEM_WB,
    output reg                 LHU_MEM_WB,
    output reg   [ 1:0]         LW_MEM_WB,

    // output data to WB stage
    output reg   [ 4:0]   RegWaddr_MEM_WB,
    output reg   [31:0]  ALUResult_MEM_WB,
    output reg   [31:0]  RegRdata2_MEM_WB,
    output reg   [31:0]         PC_MEM_WB,
    output reg   [31:0]   MemRdata_MEM_WB,

    output wire  [31:0]        Bypass_MEM,  //Bypass
    
    input  wire  [31:0]  cp0Rdata_EXE_MEM,
    input  wire              mfc0_EXE_MEM,
    output reg   [31:0]   cp0Rdata_MEM_WB,
    output reg                mfc0_MEM_WB,

    input                      wb_allowin,
    output                    mem_allowin,
    output                       data_req,
    input                   data_rdata_ok,

    input        [31:0]     mem_axi_rdata,
    input                   mem_axi_rvalid,
    input        [ 3:0]     mem_axi_rid,
    output                  mem_axi_rready,

    output       [ 3:0]     mem_axi_arid,
    output       [31:0]     mem_axi_araddr,
    output       [ 2:0]     mem_axi_arsize,
    input                   mem_axi_arready,
    output                  mem_axi_arvalid,

    output       [ 3:0]     mem_axi_awid,
    output       [31:0]     mem_axi_awaddr,
    output       [ 2:0]     mem_axi_awsize,
    output                  mem_axi_awvalid,
    input                   mem_axi_awready,

    output       [ 3:0]     mem_axi_wid,
    output       [31:0]     mem_axi_wdata,
    output       [ 3:0]     mem_axi_wstrb,
    output                  mem_axi_wvalid,
    input                   mem_axi_wready,

    output                  mem_axi_bready,
    input        [ 3:0]     mem_axi_bid,
    input                   mem_axi_bvalid,

    output reg              do_load          
);
    
    wire mem_allowgo;
    
    wire read_req;
    wire write_req;
    
    wire arvalid;
    wire arready;

    wire [3:0] rid;    
    reg  rready;
    wire rvalid;   
     
    reg  awvalid;
    wire awready;
    

    reg  wvalid;
    wire wready;

    
    wire bvalid;
    reg  bready;
    wire [3:0] bid;
    
    reg do_req_raddr;
    reg do_req_waddr, do_req_wdata;
    
    reg data_r_req, data_w_req;
    
    reg r_addr_rcv;
    reg w_addr_rcv, w_data_rcv;
    

    reg [1:0] data_in_ready;
    
    wire r_data_back;
    wire w_data_back;

    reg [32:0] do_waddr_r [0:3];
    reg [ 3:0] do_dsize_r [0:3];

    wire [4:0] write_id_n;
    wire pot_hazard;
    
    wire data_w_req_pos;               
    wire data_r_req_pos;
    wire r_addr_rcv_pos;    
    wire data_in_ready_pos;               
    wire do_req_waddr_pos;  
    wire do_req_wdata_pos;  
     
    assign mem_allowgo = wb_allowin  &&
                        ((data_r_req==2'd0&&!read_req&&data_w_req==2'd0&&!write_req) || //No memw or memr
                         (data_r_req==2'd2&&r_data_back) ||                             //memrdata returns
                         (data_w_req==2'd2&&data_in_ready_pos));                        //memwrite, addr and data all in

    assign mem_allowin = mem_allowgo && wb_allowin;
    
    wire load_type = (|LW_EXE_MEM) | LH_EXE_MEM | LHU_EXE_MEM | LB_EXE_MEM | LBU_EXE_MEM;

//    reg do_load;
    always @(posedge clk) begin
      if (rst) begin
        do_load <= 1'b0;
      end
      else if (load_type) begin
        do_load <= 1'b1;     
      end
      else if (data_raddr_ok) begin
        do_load <= 1'b0; 
      end
      else begin
        do_load <= 1'b0;
      end
     end 
    
//Select awid, wid
    assign write_id_n = do_waddr_r[0][32]==1'b0 ? 4'd0 :
                        do_waddr_r[1][32]==1'b0 ? 4'd1 :
                        do_waddr_r[2][32]==1'b0 ? 4'd2 :
                        do_waddr_r[3][32]==1'b0 ? 4'd3 : 4'd4;

//Potential hazard between previous store and current write;
    assign pot_hazard = mem_axi_araddr==(do_waddr_r[0][31:0]&32'hfffffffc) && do_waddr_r[0][32] ||
                        mem_axi_araddr==(do_waddr_r[1][31:0]&32'hfffffffc) && do_waddr_r[1][32] ||
                        mem_axi_araddr==(do_waddr_r[2][31:0]&32'hfffffffc) && do_waddr_r[2][32] ||
                        mem_axi_araddr==(do_waddr_r[3][31:0]&32'hfffffffc) && do_waddr_r[3][32] ;


    // interaction of signals and data with data_sram
    assign MemEn_MEM       =     MemEn_EXE_MEM ;
    assign MemWrite_MEM    =  MemWrite_EXE_MEM ;
    assign data_sram_addr  = ALUResult_EXE_MEM ;
    assign MemWdata_MEM    =  MemWdata_EXE_MEM ;
    assign Bypass_MEM      =      mfc0_EXE_MEM ? 
                              cp0Rdata_EXE_MEM : ALUResult_EXE_MEM;

    assign mem_axi_wid     = write_id_n;
    assign mem_axi_wstrb   = MemWrite_EXE_MEM;
    assign mem_axi_wdata   = RegRdata2_EXE_MEM;
    assign mem_axi_wvalid  = wvalid;
    assign wready = mem_axi_wready;

    assign mem_axi_awid    = write_id_n;
    assign mem_axi_awvalid = awvalid;
    assign mem_axi_awaddr  = {ALUResult_EXE_MEM[31:2],s_vaddr_EXE_MEM};
    assign mem_axi_awsize  =  s_size_EXE_MEM;/*根据SW,SB,SH,SWL,SWR来改*/
    assign awready = mem_axi_awready;
    

    assign mem_axi_arid    = 4'd1;
    assign mem_axi_araddr  = {ALUResult_EXE_MEM[31:2],2'b00};
    assign mem_axi_arsize  = (|LW_EXE_MEM)|
                               LH_EXE_MEM | LHU_EXE_MEM |
                               LB_EXE_MEM | LBU_EXE_MEM ? 3'b010 : 3'b00; /*根据LW,LB,LH来改*/
    assign mem_axi_arvalid = arvalid;
    assign arready = mem_axi_arready;
    
    assign rvalid = mem_axi_rvalid;

    assign bid = mem_axi_bid;
    assign bvalid = mem_axi_bvalid;
    
    assign arvalid = do_req_raddr;
    assign mem_axi_rready = rready;
    
    assign mem_axi_bready = bready;

    // output data to WB stage
    always @(posedge clk)
    if (~rst) begin
        if (mem_allowgo) begin
            PC_MEM_WB        <=        PC_EXE_MEM;
            RegWaddr_MEM_WB  <=  RegWaddr_EXE_MEM;
            MemToReg_MEM_WB  <=  MemToReg_EXE_MEM;
            RegWrite_MEM_WB  <=  RegWrite_EXE_MEM;
            ALUResult_MEM_WB <= ALUResult_EXE_MEM;
            RegRdata2_MEM_WB <= RegRdata2_EXE_MEM;
            cp0Rdata_MEM_WB  <=  cp0Rdata_EXE_MEM;
            MFHL_MEM_WB      <=      MFHL_EXE_MEM;
            LB_MEM_WB        <=        LB_EXE_MEM;
            LBU_MEM_WB       <=       LBU_EXE_MEM;
            LH_MEM_WB        <=        LH_EXE_MEM;
            LHU_MEM_WB       <=       LHU_EXE_MEM;
            LW_MEM_WB        <=        LW_EXE_MEM;
            mfc0_MEM_WB      <=      mfc0_EXE_MEM;
            if (data_rdata_ok)
                MemRdata_MEM_WB <=  mem_axi_rdata;
        end
        else begin
            PC_MEM_WB        <=         PC_MEM_WB;
            RegWaddr_MEM_WB  <=   RegWaddr_MEM_WB;
            MemToReg_MEM_WB  <=   MemToReg_MEM_WB;
            RegWrite_MEM_WB  <=   RegWrite_MEM_WB;
            ALUResult_MEM_WB <=  ALUResult_MEM_WB;
            RegRdata2_MEM_WB <=  RegRdata2_MEM_WB;
            cp0Rdata_MEM_WB  <=   cp0Rdata_MEM_WB;
            MFHL_MEM_WB      <=       MFHL_MEM_WB;
            LB_MEM_WB        <=         LB_MEM_WB;
            LBU_MEM_WB       <=        LBU_MEM_WB;
            LH_MEM_WB        <=         LH_MEM_WB;
            LHU_MEM_WB       <=        LHU_MEM_WB;
            LW_MEM_WB        <=         LW_MEM_WB;
            mfc0_MEM_WB      <=       mfc0_MEM_WB;
            MemRdata_MEM_WB  <=   MemRdata_MEM_WB;            
        end
    end
    else begin
        { 
                 PC_MEM_WB,  RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, 
          ALUResult_MEM_WB, RegRdata2_MEM_WB, cp0Rdata_MEM_WB,     MFHL_MEM_WB, 
                 LB_MEM_WB,       LBU_MEM_WB,       LH_MEM_WB,      LHU_MEM_WB,
                 LW_MEM_WB,      mfc0_MEM_WB, MemRdata_MEM_WB
        } <= 'd0;
        end

    assign write_req = |MemWrite_EXE_MEM;
    assign read_req  =  MemEn_EXE_MEM && ~(|MemWrite_EXE_MEM);
    always @(posedge clk) 
    begin
        //若表满，则不能发写请求
        data_w_req  <=  data_w_req==2'd0   ? 
                            (write_req ? 
                                (write_id_n!=4'd4 ? 2'd2 : 2'd1) 
                            : data_w_req)
                        :   (data_w_req==2'd1  ? 
                            (write_id_n!=4'd4  ? 2'd2 : data_w_req)
                        :   (data_in_ready_pos ? 1'b0 : data_w_req));
      
        //有潜在的相关可能，则不能发读请求
        data_r_req  <=  data_r_req==2'd0 ? 
                            read_req ? 
                                !pot_hazard ? 2'd2 : 2'd1
                            : data_r_req
                        :data_r_req==2'd1 ?
                            !pot_hazard ? 2'd2 : data_r_req
                        :r_data_back ? 2'd0 : data_r_req;
    end

    always @ (posedge clk) begin
        //写响应返回，则拉低对应表项的有效位
        if (bvalid&&bready) begin
            if (bid==4'd0) do_waddr_r[0][32] <= 1'b0;
            if (bid==4'd1) do_waddr_r[1][32] <= 1'b0;
            if (bid==4'd2) do_waddr_r[2][32] <= 1'b0;
            if (bid==4'd3) do_waddr_r[3][32] <= 1'b0;
        end
    end

    always @ (posedge clk) begin
        if (data_w_req_pos) begin
            if (write_id_n==4'd0) begin
                do_waddr_r[0] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[0] <= mem_axi_awsize;
            end
            if (write_id_n==4'd1) begin
                do_waddr_r[1] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[1] <= mem_axi_awsize;
            end
            if (write_id_n==4'd2) begin
                do_waddr_r[2] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[2] <= mem_axi_awsize;
            end
            if (write_id_n==4'd3) begin
                do_waddr_r[3] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[3] <= mem_axi_awsize;
            end
        end
    end

    always @ (posedge clk) begin
        do_req_raddr    <= rst               ? 1'b0 :
                           data_r_req_pos    ? 1'b1 :
                           r_addr_rcv_pos    ? 1'b0 : do_req_raddr;
    end

    always @(posedge clk) begin
        r_addr_rcv <= rst              ? 1'b0 :
                      arvalid&&arready ? 1'b1 :
                      r_data_back      ? 1'b0 : r_addr_rcv;
        rready     <= rst              ? 1'b0 :
                      r_addr_rcv_pos   ? 1'b1 :
                      r_data_back      ? 1'b0 : rready;
    end
    assign r_data_back = r_addr_rcv && (rvalid && rready && rid==4'd1);
    assign w_data_back = (w_addr_rcv&&w_data_rcv) && (bvalid && bready);
    
    always @ (posedge clk) begin
        do_req_waddr     <= rst                 ? 1'b0 : 
                            data_w_req_pos      ? 1'b1 :
                            data_in_ready_pos   ? 1'b0 : do_req_waddr;
        do_req_wdata     <= rst                 ? 1'b0 :
                            data_w_req_pos      ? 1'b1 :
                            data_in_ready_pos   ? 1'b0 : do_req_wdata;
        data_in_ready    <= rst                 ? 2'b00 :
                            awvalid&&awready && wvalid&&wready ? 2'b11 :
                            awvalid&&awready                   ? data_in_ready + 2'b01 :
                            wvalid&&wready                     ? data_in_ready + 2'b10 :
                            w_data_back                        ? 2'b00 : data_in_ready;
        
        awvalid          <= rst                 ? 1'b0 :
                            do_req_waddr_pos    ? 1'b1 :
                            awready             ? 1'b0 : awvalid;
        wvalid           <= rst                 ? 1'b0 :
                            do_req_wdata_pos    ? 1'b1 :
                            wready              ? 1'b0 : wvalid;

    end

    always @ (posedge clk) begin
        w_addr_rcv <= rst                ? 1'b0 :             //slave receives waddr and haven't received wdata.
                      awvalid&&awready   ? 1'b1 :
                      w_data_back        ? 1'b0 : w_addr_rcv; 
        w_data_rcv <= rst                ? 1'b0 :             //slave receives wdata and haven't send response
                      wvalid&&wready     ? 1'b1 :
                      w_data_back        ? 1'b0 : w_data_rcv;
        bready     <= rst                ? 1'b0 :
                      data_in_ready_pos  ? 1'b1 :
                      w_data_back        ? 1'b0 : bready;
    end    


    assign data_w_req_pos = data_w_req==2'd0 && write_req && write_id_n!=4'd4 ||
                            data_w_req==2'd1 && write_id_n!=4'd4;
    assign data_r_req_pos = data_r_req==2'd0 && read_req && !pot_hazard ||
                            data_r_req==2'd1 && !pot_hazard;

    assign r_addr_rcv_pos    = !r_addr_rcv         && arvalid&&arready;
    assign data_in_ready_pos = data_in_ready==2'd1 && wvalid&&wready   || 
                               data_in_ready==2'd2 && awvalid&&awready ||
                               data_in_ready==2'd0 && awvalid&&awready && wvalid&&wready;
    assign do_req_waddr_pos  = !do_req_waddr       && data_w_req_pos;
    assign do_req_wdata_pos  = !do_req_wdata       && data_w_req_pos;


endmodule //memory_stage