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
    input                      Exc_BD,
    input  [              5:0] int,
    input  [              6:0] Exc_Vec, //Exception type
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr,
    input  [`DATA_WIDTH - 1:0] wdata,
    input  [`DATA_WIDTH - 1:0] epc_in,  
    input  [`DATA_WIDTH - 1:0] Exc_BadVaddr,
    output [`DATA_WIDTH - 1:0] rdata,
    output [`DATA_WIDTH - 1:0] epc_value,
    output                     ex_int_handle,
    output                     eret_handle,

    input                      exe_ready_go,
    input                      exe_refresh,

    output [`DATA_WIDTH - 1:0] index_r2t,  // registers to tlbs
    output [`DATA_WIDTH - 1:0] entryhi_r2t,
    output [`DATA_WIDTH - 1:0] entrylo0_r2t,
    output [`DATA_WIDTH - 1:0] entrylo1_r2t,
    output [`DATA_WIDTH - 1:0] pagemask_r2t,

    input  [`DATA_WIDTH - 1:0] index_t2r,
    input  [`DATA_WIDTH - 1:0] entryhi_t2r,
    input  [`DATA_WIDTH - 1:0] entrylo0_t2r,
    input  [`DATA_WIDTH - 1:0] entrylo1_t2r,
    input  [`DATA_WIDTH - 1:0] pagemask_t2r,

    input                      tlbp,
    input                      tlbr
); 
    parameter tlb_entry_num = 5;

    // Index        reg:  0, sel: 0
    wire [31:0] index_value;
    wire [30: tlb_entry_num] index_zero = 'd0; 
    reg  [tlb_entry_num-1:0] index_index;
    reg  index_p;  // read only

    always @(posedge clk) begin
        if (rst) begin
            index_p     <= 1'b0;
            index_index <=  'd0;
        end
        else if (wen && waddr == 5'd0) begin
            index_index <= wdata[tlb_entry_num-1:0];
        end
        else if (tlbp) begin
            index_index <= index_t2r[tlb_entry_num-1:0];
            index_p     <= index_t2r[31];
        end
    end

    assign index_value = {index_p,index_zero,index_index};
    assign index_r2t   = index_value;

    // EntryLO0     reg:  2, sel: 0
    wire [31: 0] entrylo0_value;
    wire [31:26] entrylo0_zero = 'd0;
    reg  [25: 6] entrylo0_pfn;
    reg  [ 5: 3] entrylo0_c;
    reg          entrylo0_d;
    reg          entrylo0_v;
    reg          entrylo0_g;

    always @(posedge clk) begin
      if (rst) begin
          entrylo0_pfn <= 'd0;
          entrylo0_c   <= 'd0;
          entrylo0_d   <= 'd0;
          entrylo0_v   <= 'd0;
          entrylo0_g   <= 'd0;
      end
      else if (wen && waddr == 5'd2) begin
          {entrylo0_pfn,entrylo0_c,entrylo0_d,
           entrylo0_v,entrylo0_g} <= wdata[25:0];
      end
      else if (tlbr) begin
          entrylo0_pfn <= entrylo0_t2r[25:6];
          entrylo0_c   <= entrylo0_t2r[5:3];
          entrylo0_d   <= entrylo0_t2r[2];
          entrylo0_v   <= entrylo0_t2r[1];
          entrylo0_g   <= entrylo0_t2r[0];          
      end
    end

    assign entrylo0_value = {entrylo0_zero,entrylo0_pfn,entrylo0_c,
                             entrylo0_d,entrylo0_v,entrylo0_g};
    assign entrylo0_r2t   = entrylo0_value;

    // EntryLO1     reg:  3, sel: 0
    wire [31: 0] entrylo1_value;
    wire [31:26] entrylo1_zero = 'd0;
    reg  [25: 6] entrylo1_pfn;
    reg  [ 5: 3] entrylo1_c;
    reg          entrylo1_d;
    reg          entrylo1_v;
    reg          entrylo1_g;

    always @(posedge clk) begin
      if (rst) begin
          entrylo1_pfn <= 'd0;
          entrylo1_c   <= 'd0;
          entrylo1_d   <= 'd0;
          entrylo1_v   <= 'd0;
          entrylo1_g   <= 'd0;
      end
      else if (wen && waddr == 5'd3) begin
          {entrylo1_pfn,entrylo1_c,entrylo1_d,
           entrylo1_v,entrylo1_g} <= wdata[25:0];
      end
      else if (tlbr) begin
          entrylo1_pfn <= entrylo1_t2r[25:6];
          entrylo1_c   <= entrylo1_t2r[ 5:3];
          entrylo1_d   <= entrylo1_t2r[2];
          entrylo1_v   <= entrylo1_t2r[1];
          entrylo1_g   <= entrylo1_t2r[0];          
      end
    end

    assign entrylo1_value = {entrylo1_zero,entrylo1_pfn,entrylo1_c,
                             entrylo1_d,entrylo1_v,entrylo1_g};
    assign entrylo1_r2t   = entrylo1_value;                        

    // PageMask     reg:  5, sel: 0
    wire [31: 0] pagemask_value;
    wire [31:25] pagemask_hzero = 'd0;
    reg  [24:13] pagemask_mask;
    wire [12: 0] pagemask_lzero = 'd0;

    always @(posedge clk) begin
      if (rst) begin
          pagemask_mask <= 'd0;
      end
      else if (wen && waddr == 5'd5) begin
          pagemask_mask <= wdata[24:13];
      end
      else if (tlbr) begin
          pagemask_mask <= pagemask_t2r[24:13];         
      end
    end

    assign pagemask_value = {pagemask_hzero,pagemask_mask,pagemask_lzero};
    assign pagemask_r2t   = pagemask_value;

    // BadVAddr     reg:  8, sel: 0
    reg  [31:0] badvaddr;
    wire [31:0] badvaddr_value;
    assign badvaddr_value = badvaddr;

    // Count        reg: 9, sel: 0
    reg         cycle;
    reg  [31:0] count;
    wire [31:0] count_value;
    assign count_value = count;

    // EntryHi      reg: 10, sel: 0
    wire [31: 0] entryhi_value;
    reg  [31:13] entryhi_vpn2;
    wire [12: 8] entryhi_zero = 'd0;
    reg  [ 7: 0] entryhi_asid;

    always @(posedge clk) begin
      if (rst) begin
          entryhi_asid <= 'd0;
          entryhi_vpn2 <= 'd0;
      end
      else if (wen && waddr == 5'd10) begin
          entryhi_vpn2 <= wdata[31:13];
          entryhi_asid <= wdata[ 7: 0];
      end
      else if (tlbr) begin
          entryhi_vpn2 <= entryhi_t2r[31:13];
          entryhi_asid <= entryhi_t2r[ 7: 0];
      end
    end  

    assign entryhi_value = {entryhi_vpn2,entryhi_zero,entryhi_asid};
    assign entryhi_r2t   = entryhi_value;

    // Compare      reg: 11, sel: 0
    reg  [31:0] compare;
    wire [31:0] compare_value;
    assign compare_value = compare;
    wire   count_cmp_eq  = (count_value == compare_value) ? 1'b1 : 1'b0;

    // Status       reg: 12, sel: 0
    wire        status_CU3   = 1'b0;
    wire        status_CU2   = 1'b0;
    wire        status_CU1   = 1'b0;
    wire        status_CU0   = 1'b0;
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
    wire [ 1:0] status_KSU   = 2'd0;
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
    wire [ 4:0]ExcCode;
    assign cause_value = {cause_BD,  cause_TI, 14'd0, cause_IP7, cause_IP6, 
                          cause_IP5, cause_IP4,       cause_IP3, cause_IP2,
                          cause_IP1, cause_IP0, 1'b0, cause_ExcCode, 2'd0};
    assign ExcCode     =  (Exc_Vec[11]) ? 5'h1 :        // TLB_modified
                          (Exc_Vec[10]) ? 5'h3 :        // TLB_invalid_s
                          (Exc_Vec[ 9]) ? 5'h2 :        // TLB_invalid_l
                          (Exc_Vec[ 8]) ? 5'h3 :        // TLB_refill_s
                          (Exc_Vec[ 7]) ? 5'h2 :        // TLB_refill_l
                          (Exc_Vec[ 6]) ? 5'h4 :        // PC_AdEL
                          (Exc_Vec[ 5]) ? 5'ha :        // Reserved Instruction
                          (Exc_Vec[ 4]) ? 5'hc :        // OverFlow
                          (Exc_Vec[ 3]) ? 5'h8 :        // syscall
                          (Exc_Vec[ 2]) ? 5'h9 :        // breakpoint
                          (Exc_Vec[ 1]) ? 5'h4 :        // AdEL
                          (Exc_Vec[ 0]) ? 5'h5 : 5'hf;  // AdES;
                          
    // EPC          reg: 14, sel: 0
    reg  [31:0] epc;

    assign epc_value = epc;

    wire [7:0] int_vec;
    wire int_pending = |int_vec & status_IE;
    wire exc_pending = |Exc_Vec;
    
    wire int_handle;
    wire ex_handle;

    assign ex_int_handle = ~status_EXL & (int_pending | exc_pending);
    assign int_handle    = ~status_EXL & int_pending;
    assign ex_handle     = ~status_EXL & exc_pending;
 
    reg wait_for_epc;
    reg wait_for_epc_r;
    wire wait_for_epc_neg;

    always @(posedge clk) begin
        if (~status_EXL) begin
            if (|int_vec && status_IE) begin
                cause_ExcCode <= 5'd0;
            end
            else if (|Exc_Vec) begin
                cause_ExcCode <= ExcCode;
                cause_BD      <= Exc_BD;
                if (Exc_Vec[6] | Exc_Vec[1] | Exc_Vec[0])
                    badvaddr  <= Exc_BadVaddr;
            end
        end

        // BadVAddr     reg: 8, sel: 0
        if(rst) begin
            badvaddr <= 32'd0;
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
            if(cycle)
                count <= count + 1'b1;
        end

        if (rst)
            compare <= 32'h0;
        else if (wen && waddr == 5'd11)
            compare <= wdata[31:0];
      
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
          if (eret && exe_ready_go) 
              status_EXL <= 1'b0;
          else if ((exc_pending || int_pending) && exe_ready_go)
              status_EXL <= 1'b1;
          else if (wen && waddr == 5'd12)
              status_EXL <= wdata[1];

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
            if (wen && waddr == 5'd13) begin
                cause_IP1 <= wdata[ 9];
                cause_IP0 <= wdata[ 8];
            end
                cause_IP7 <= int[5] | cause_TI; //cause_TI;
                cause_IP6 <= int[4];
                cause_IP5 <= int[3];
                cause_IP4 <= int[2];
                cause_IP3 <= int[1];
                cause_IP2 <= int[0];
        end
        // EPC          reg: 14, sel: 0
        if (rst) begin
            epc <= 32'd0;
        end
        else begin
        if (wait_for_epc_neg || ex_handle&&exe_ready_go) begin
            epc <= epc_in;
        end
        else if (wen && waddr == 5'd14)
            epc <= wdata[31:0];
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            wait_for_epc <= 1'b0;
        end
        else begin
            if (int_handle)
                wait_for_epc <= 1'b1;
            else if (wait_for_epc&&exe_refresh)
                wait_for_epc <= 1'b0;
        end
    end


    always @ (posedge clk) begin
        if (rst) begin
            wait_for_epc_r <= 1'b0;
        end
        else begin
            wait_for_epc_r <= wait_for_epc;
        end
    end

    assign wait_for_epc_neg = ~wait_for_epc & wait_for_epc_r;

    assign rdata = {32{&(~(raddr ^ 5'b00000))}}  &    index_value |
                   {32{&(~(raddr ^ 5'b00010))}}  & entrylo0_value |
                   {32{&(~(raddr ^ 5'b00011))}}  & entrylo1_value |
                   {32{&(~(raddr ^ 5'b00101))}}  & pagemask_value |
                   {32{&(~(raddr ^ 5'b01000))}}  & badvaddr_value |
                   {32{&(~(raddr ^ 5'b01001))}}  &    count_value |
                   {32{&(~(raddr ^ 5'b01010))}}  &  entryhi_value |
                   {32{&(~(raddr ^ 5'b01011))}}  &  compare_value |
                   {32{&(~(raddr ^ 5'b01100))}}  &   status_value |
                   {32{&(~(raddr ^ 5'b01101))}}  &    cause_value |
                   {32{&(~(raddr ^ 5'b01110))}}  &      epc_value ;
                              
    assign int_vec = {(int[5] | cause_TI) & status_IM7,
                       int[4]             & status_IM6,
                       int[3]             & status_IM5,
                       int[2]             & status_IM4,
                       int[1]             & status_IM3,
                       int[0]             & status_IM2,
                      cause_IP1           & status_IM1,
                      cause_IP0           & status_IM0};
               
    assign eret_handle = eret; 
               
endmodule  // CP0 register files