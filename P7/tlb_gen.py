import os

FILENAME = './tlb.txt'

TLB_MODULE_NAME = 'tlb'
TLB_NAME = 'tlb'

CP0_INDEX_IN     = 'index_in'
CP0_ENTRYHI_IN   = 'entryhi_in'
CP0_ENTRYLO0_IN  = 'entrylo0_in'
CP0_ENTRYLO1_IN  = 'entrylo1_in'
CP0_PAGEMASK_IN  = 'pagemask_in'

CP0_INDEX_OUT    = 'index_out'
CP0_ENTRYHI_OUT  = 'entryhi_out'
CP0_ENTRYLO0_OUT = 'entrylo0_out'
CP0_ENTRYLO1_OUT = 'entrylo1_out'
CP0_PAGEMASK_OUT = 'pagemask_out'

COMPARE_VEC_NAME = 'vpn_compare'
MASK_COMPARE_NAME = 'mask_compare'
COMPARE_RESULT_NAME = 'compare_result'
vec_flag = "asid_compare"

if os.path.exists(FILENAME):
    os.remove(FILENAME)

with open(FILENAME,'w') as f:
    file = ''
    module = '''`timescale 10ns / 1ns

`define VPN      31:13
`define VPN2     89:71
`define ASID     70:63
`define PageMask 62:51
`define G        50
`define PFN0     49:30
`define FLAG0    29:25
`define C0       29:27
`define D0       26
`define V0       25
`define PFN1     24:5
`define FLAG1    4:0
`define C0       4:2
`define D0       1
`define V0       0

module %s(
    input             clk,
    input             rst,
    input             tlbp,
    input             tlbr,
    input             tlbwi,
    input             load,
    input             store,
    input   [31:0]    l_vaddr,
    input   [31:0]    s_vaddr,
    input   [31:0]    %s,
    input   [31:0]    %s,
    input   [31:0]    %s,
    input   [31:0]    %s,
    input   [31:0]    %s,   
    output            hit,
    output            tlb_invalid,
    output            tlb_refill,
    output            tlb_modified,
    output  [31:0]    l_paddr,
    output  [31:0]    s_paddr,
    output  [31:0]    %s,
    output  [31:0]    %s,
    output  [31:0]    %s,
    output  [31:0]    %s,
    output  [31:0]    %s,      
  );\n\n''' \
  %(TLB_MODULE_NAME,\
    CP0_INDEX_IN,CP0_ENTRYHI_IN,CP0_ENTRYLO0_IN,CP0_ENTRYLO1_IN,CP0_PAGEMASK_IN,\
    CP0_INDEX_OUT,CP0_ENTRYHI_OUT,CP0_ENTRYLO0_OUT,CP0_ENTRYLO1_OUT,CP0_PAGEMASK_OUT)
    file += module
    tlb_declare = "    reg [89:0] %s [31:0];\n"%TLB_NAME
    tlb_quote = '''    // [89:71]: VPN2     ; [70:63]: ASID  ;
    // [62:51]: PageMask ; [50:50]: G     ;
    // [49:30]: PFN0     ; [29:25]: C,D,V ;
    // [24: 5]: PFN1     ; [ 4: 0]: C,D,V ;\n\n'''
    file += tlb_declare+tlb_quote
    tlb_index = "    wire [ 4:0] tlb_index;\n    assign tlb_index = %s[4:0];\n\n"%(CP0_INDEX_IN)   
    
    tlbwi = '''    // TLBWI
    always @(posedge clk) begin
        if (tlbwi) begin
            %s[tlb_index][`VPN2]     <=  %s[31:13];
            %s[tlb_index][`ASID]     <=  %s[ 7: 0];
            %s[tlb_index][`PageMask] <= %s[24:13];
            %s[tlb_index][`G]        <= %s[0] & %s[0];
            %s[tlb_index][`PFN0]     <= %s[25: 6];
            %s[tlb_index][`FLAG0]    <= %s[ 5: 1];
            %s[tlb_index][`PFN1]     <= %s[25: 6];
            %s[tlb_index][`FLAG1]    <= %s[ 5: 1];
        end
    end\n'''%( TLB_NAME,CP0_ENTRYHI_IN,\
                 TLB_NAME,CP0_ENTRYHI_IN,\
                 TLB_NAME,CP0_PAGEMASK_IN,\
                 TLB_NAME,CP0_ENTRYLO0_IN,CP0_ENTRYLO1_IN,\
                 TLB_NAME,CP0_ENTRYLO0_IN,\
                 TLB_NAME,CP0_ENTRYLO0_IN,\
                 TLB_NAME,CP0_ENTRYLO1_IN,\
                 TLB_NAME,CP0_ENTRYLO1_IN)

    tlbr = '''    // TLBR
    assign %s  = {%s[tlb_index][`VPN2],5'd0,%s[tlb_index][`ASID]};
    assign %s = {6'd0,%s[tlb_index][`PFN0],%s[tlb_index][`FLAG0]}; 
    assign %s = {6'd0,%s[tlb_index][`PFN1],%s[tlb_index][`FLAG1]}; 
    assign %s = {7'd0,%s[tlb_index][`PageMask],13'd0}; 
    \n'''%( CP0_ENTRYHI_OUT,  TLB_NAME, TLB_NAME, \
          CP0_ENTRYLO0_OUT, TLB_NAME, TLB_NAME, \
          CP0_ENTRYLO1_OUT, TLB_NAME, TLB_NAME, \
          CP0_PAGEMASK_OUT, TLB_NAME)


    flag_vec = "    wire [31:0] %s;\n"%vec_flag
    flag_assign = ''
    for i in range(32):
        flag_assign += "    assign %s[%2d] = %s[%2d][`G] | &(%s[%2d][`ASID] ^~ %s[7:0]);\n"%(vec_flag,31-i,TLB_NAME,31-i,TLB_NAME,31-i,CP0_ENTRYHI_IN)

    vec_assign  = "\n    wire [31:0] %s;\n"%COMPARE_VEC_NAME
    for i in range(32):
        vec_assign += "    assign %s[%2d] = &(%s[%2d][`VPN2] ^~ l_vaddr[`VPN]);\n" \
                        %(COMPARE_VEC_NAME,31-i,TLB_NAME,31-i)
  
    mask_declare = "\n    wire [31:0] %s;\n"%MASK_COMPARE_NAME
    mask_assign = ''
    for i in range(32):
        mask_assign += "    assign %s[%2d] = &(~{7'd0,%s[%2d][`PageMask]});\n"%(MASK_COMPARE_NAME,31-i,TLB_NAME,31-i)

    compare_declare = "\n    wire [31:0] %s;\n"%COMPARE_RESULT_NAME
    compare_assign  = ''
    for i in range(32):
        compare_assign += "    assign %s[%2d] = %s[%2d] & %s[%2d] & %s[%2d];\n"%(\
                           COMPARE_RESULT_NAME,31-i,\
                           COMPARE_VEC_NAME,31-i,\
                           vec_flag,31-i,\
                           MASK_COMPARE_NAME,31-i)


    file += tlb_index + tlbwi + tlbr + flag_vec + flag_assign + vec_assign \
          + mask_declare + mask_assign + compare_declare + compare_assign

    endmodule = "\nendmodule\n"

    file += endmodule

    f.write(file)
