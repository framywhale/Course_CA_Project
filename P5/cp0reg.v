/*----------------------------------------------------------------*
// Filename      :  cp0reg.v
// Description   :  5 pipelined CPU CP0 Registers part
// Author        :  Gou Lingrui & Wu Jiahao
// Email         :  wujiahao15@mails.ucas.ac.cn
// Created Time  :  2017-10-11 21:04:12
// Modified Time :  2017-11-17 17:35:21
//----------------------------------------------------------------*/

`define DATA_WIDTH 32
`define ADDR_WIDTH 5

`timescale 10ns / 1ns

module cp0reg(
    input                      clk,
    input                      rst,
    input                      wen,
    input                      eret,
    input                      trap,
    input  [              5:0] int,
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr,
    input  [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata,
    output [`DATA_WIDTH - 1:0] epc_value
);
    // BadVAddr     reg: 8, sel: 0
    reg  [31:0] badvaddr;
    wire [31:0] badvaddr_value;
    assign badvaddr_value = badvaddr;
    // Count        reg: 9, sel: 0
    reg         cycle;
    reg  [31:0] count;
    wire [31:0] count_value;
    assign count_value = count;
    // Compare      reg: 11, sel: 0
    reg  [31:0] compare;
    wire [31:0] compare_value;
    assign compare_value = compare;
    wire count_cmp_eq = (count_value == compare_value) ? 1'b1 : 1'b0;

    // Status       reg: 12, sel: 0
    wire        status_CU3   = 1'b0;
    wire        status_CU2   = 1'b0;
    wire        status_CU1   = 1'b0;
    wire        status_CU0   = 1'b1;
    wire        status_RP    = 1'b0;
    wire        status_FR    = 1'b0;
    wire        status_RE    = 1'b0;
    wire        status_MX    = 1'b0;
    wire        status_BEV   = 1'b1;
    wire        status_TS    = 1'b0;
    wire        status_SR    = 1'b0;
    wire        status_NMI   = 1'b0;
    wire        status_ASE   = 1'b0;
    reg         status_IM7;
    reg         status_IM6;
    reg         status_IM5;
    reg         status_IM4;
    reg         status_IM3;
    reg         status_IM2;
    reg         status_IM1;
    reg         status_IM0;
    wire [ 1:0] status_KSU   = 2'b00;
    wire        status_ERL   = 1'b0;
    reg         status_EXL;
    reg         status_IE;

    wire [31:0] status_value;
    assign status_value = {status_CU3, status_CU2, status_CU1, status_CU0,
                           status_RP,  status_FR,  status_RE,  status_MX,  
                    1'b0,  status_BEV, status_TS,  status_SR,  status_NMI, status_ASE, 
                    2'd0,  status_IM7, status_IM6, status_IM5, status_IM4, status_IM3,
                           status_IM2, status_IM1, status_IM0, 3'd0,       status_KSU,
                           status_ERL, status_EXL, status_IE };

    // Cause        reg: 13, sel: 0
    reg         cause_BD;
    reg         cause_TI;
    // wire [1:0]  cause_CE     = 2'd0;
    // wire        cause_DC     = 1'b0;
    // wire        cause_PCI    = 1'b0;
    // wire        cause_IV     = 1'b0;
    // wire        cause_WP     = 1'b0;
    // wire        cause_FDCI   = 1'b0;
    reg         cause_IP7;
    reg         cause_IP6;
    reg         cause_IP5;
    reg         cause_IP4;
    reg         cause_IP3;
    reg         cause_IP2;
    reg         cause_IP1;
    reg         cause_IP0;
    reg  [4:0]  cause_ExcCode;

    wire [31:0] cause_value;
    assign cause_value = {cause_BD,  cause_TI, 15'd0, cause_IP7, cause_IP6, 
                          cause_IP5, cause_IP4,       cause_IP3, cause_IP2,
                          cause_IP1, cause_IP0, 1'b0, cause_ExcCode, 2'd0};

    // EPC          reg: 14, sel: 0
    reg  [31:0] epc;

    assign epc_value = epc;

    always @(posedge clk) begin
      // BadVAddr     reg: 8, sel: 0
      if(rst) begin
        badvaddr <= 32'd0;
      end
      else if (wen && waddr==5'd8) begin
        badvaddr <= wdata;
      end
      // Count        reg: 9, sel: 0
      if(rst) begin
        cycle <= 1'b0;
        count <= 32'd0;
      end
      else if(wen && waddr==5'd9) begin
        count <= wdata;
        cycle <= 1'b0;
      end
      else begin
        cycle <= ~cycle;
        if(cycle) begin
          count <= count + 1;
      end
      // Status       reg: 12, sel: 0
      if (rst) begin
        status_IM7   <= 1'b0;
        status_IM6   <= 1'b0;
        status_IM5   <= 1'b0;
        status_IM4   <= 1'b0;
        status_IM3   <= 1'b0;
        status_IM2   <= 1'b0;
        status_IM1   <= 1'b0;
        status_IM0   <= 1'b0;
        status_EXL   <= 1'b0;
        status_IE    <= 1'b0;
      end
      else begin
        if (eret) 
          status_EXL <= 1'b0;
        else if (trap)
          status_EXL <= 1'b1;
        else
          status_EXL <= status_EXL;
        if (wen && waddr == 5'd12) begin
          status_IM7 <= wdata[ 15];
          status_IM6 <= wdata[ 14];
          status_IM5 <= wdata[ 13];
          status_IM4 <= wdata[ 12];
          status_IM3 <= wdata[ 11];
          status_IM2 <= wdata[ 10];
          status_IM1 <= wdata[  9];
          status_IM0 <= wdata[  8];
          status_IE  <= wdata[  0];
        end
      end
      // Cause        reg: 13, sel: 0
      if (rst) begin
        cause_TI <= 1'b0;
      end
      else if (wen && waddr==5'd11) begin //compare_wen
        cause_TI <= 1'b0;
      end
      else if (count_cmp_eq) begin
        cause_TI <= 1'b1;
      end
      if (rst) begin
        cause_BD      <= 1'b0;
        cause_IP7     <= 1'b0;
        cause_IP6     <= 1'b0;
        cause_IP5     <= 1'b0;
        cause_IP4     <= 1'b0;
        cause_IP3     <= 1'b0;
        cause_IP2     <= 1'b0;
        cause_IP1     <= 1'b0;
        cause_IP0     <= 1'b0;
        cause_ExcCode <= 5'h1f;
      end
      else begin
        if (trap) begin
          cause_ExcCode <= 5'd8; //rs_ex ? rs_excode[4:0] : exe_excode[4:0];     
        end
        if (wen && waddr == 5'd13) begin
          cause_IP1  <= wdata[ 9];
          cause_IP0  <= wdata[ 8];
        end
        cause_IP7    <= int[5];
        cause_IP6    <= int[4];
        cause_IP5    <= int[3];
        cause_IP4    <= int[2];
        cause_IP3    <= int[1];
        cause_IP2    <= int[0];
      end
      // EPC          reg: 14, sel: 0
      if (rst) 
        epc <= 32'd0;
      else if (!status_EXL)
        epc <= epc;
      else if (wen && waddr == 5'd14)
        epc <= wdata[31:0];
    end

    assign rdata = {32{&(~(raddr ^ 5'b01000))}}  & badvaddr_value |
                   {32{&(~(raddr ^ 5'b01001))}}  &    count_value |
                   {32{&(~(raddr ^ 5'b01011))}}  &  compare_value |
                   {32{&(~(raddr ^ 5'b01100))}}  &   status_value |
                   {32{&(~(raddr ^ 5'b01101))}}  &    cause_value |
                   {32{&(~(raddr ^ 5'b01110))}}  &      epc_value ;
                   
endmodule // CP0 register files

/*
    reg [`DATA_WIDTH - 1:0] mem [0:(1 << `ADDR_WIDTH )- 1];
    integer i;
    always @ (posedge clk)
    begin
    if (rst == 1)
        begin
        for (i = 0; i < 1 << `ADDR_WIDTH  ; i = i + 1)
            mem[i] <= `DATA_WIDTH'd0;
        mem[11] = 32'h10400000;                      //Status
        end
    else begin 
        if (wen != 4'd0 && waddr != 5'd0) begin
        mem[waddr][31:24] <= {8{wen[3]}} & wdata[31:24];
        mem[waddr][23:16] <= {8{wen[2]}} & wdata[23:16];
        mem[waddr][15: 8] <= {8{wen[1]}} & wdata[15: 8];
        mem[waddr][ 7: 0] <= {8{wen[0]}} & wdata[ 7: 0];
        end
        else if (eret) mem[11] <= mem[11] & 32'hfffffffd; //EXL <-- 0       
        else if (trap) mem[11] <= mem[11] ^ 32'h00000002; //EXL <-- 1
        else mem[0] <= mem[0];                            //default, in order that latch will not appear
        end
    end


    assign rdata = eret ? mem[14] : mem[raddr];
*/

    // BadVAddr     reg: 8, sel: 0
    /*  if (rs_valid && 
          (rs_ex && rs_excode==`LS132R_EX_ADEL ||
           exe_ex && (exe_excode==`LS132R_EX_ADEL || exe_excode==`LS132R_EX_ADES)))
        badvaddr <= rs_ex ? rs_pc_r : mem_vaddr;    

    // Count        reg: 9, sel: 0
      if (rst)
        count <= 32'h0;
      else if (cp0_wen && cp0_waddr=={5'd9, 3'd0})
        count <= wdata[31:0];
      else if (count_add_en)
        count <= count + 1'b1;    

    // Compare      reg: 11, sel: 0
      if (rst)
        compare <= 32'h0;
      else if (cp0_wen && cp0_waddr=={5'd11, 3'd0})
        compare <= wdata[31:0];    

    */