`timescale 10ns / 1ns

`define VPN      31:13
`define VPN2     89:71
`define ASID     70:63
`define PageMask 62:51
`define G        50
`define EntryLo0 49:25
`define PFN0     49:30
`define FLAG0    29:25
`define C0       29:27
`define D0       26
`define V0       25
`define EntryLo1 24:0
`define PFN1     24:5
`define FLAG1    4:0
`define C1       4:2
`define D1       1
`define V1       0

module tlb(
    input             clk,

    input             tlbp,
    input             tlbr,
    input             tlbwi,

    input   [32:0]    l_vaddr,
    input   [32:0]    s_vaddr,

    input   [31:0]    index_r2t,
    input   [31:0]    entryhi_r2t,
    input   [31:0]    entrylo0_r2t,
    input   [31:0]    entrylo1_r2t,
    input   [31:0]    pagemask_r2t,

    output            tlb_invalid_l,
    output            tlb_refill_l,
    output            tlb_invalid_s,
    output            tlb_refill_s,
    output            tlb_modified,

    output  [31:0]    l_paddr,
    output  [31:0]    s_paddr,
    
    output  [31:0]    index_t2r,
    output  [31:0]    entryhi_t2r,
    output  [31:0]    entrylo0_t2r,
    output  [31:0]    entrylo1_t2r,
    output  [31:0]    pagemask_t2r   
  );

    reg [89:0] tlb [31:0];
    // [89:71]: VPN2     ; [70:63]: ASID  ;
    // [62:51]: PageMask ; [50:50]: G     ;
    // [49:30]: PFN0     ; [29:25]: C,D,V ;
    // [24: 5]: PFN1     ; [ 4: 0]: C,D,V ;

    wire [ 4:0] tlb_index;
    assign tlb_index = index_r2t[4:0];

    // TLBWI
    always @(posedge clk) begin
        if (tlbwi) begin
            tlb[tlb_index][`VPN2]     <=  entryhi_r2t[31:13];
            tlb[tlb_index][`ASID]     <=  entryhi_r2t[ 7: 0];
            tlb[tlb_index][`PageMask] <= pagemask_r2t[24:13];
            tlb[tlb_index][`G]        <= entrylo0_r2t[0] & entrylo1_r2t[0];
            tlb[tlb_index][`PFN0]     <= entrylo0_r2t[25: 6];
            tlb[tlb_index][`FLAG0]    <= entrylo0_r2t[ 5: 1];
            tlb[tlb_index][`PFN1]     <= entrylo1_r2t[25: 6];
            tlb[tlb_index][`FLAG1]    <= entrylo1_r2t[ 5: 1];
        end
    end
    // TLBR
    assign  entryhi_t2r = {32{tlbr}} & {tlb[tlb_index][`VPN2],5'd0,tlb[tlb_index][`ASID]};
    assign entrylo0_t2r = {32{tlbr}} & {6'd0,tlb[tlb_index][`PFN0],tlb[tlb_index][`FLAG0],tlb[tlb_index][`G]}; 
    assign entrylo1_t2r = {32{tlbr}} & {6'd0,tlb[tlb_index][`PFN1],tlb[tlb_index][`FLAG1],tlb[tlb_index][`G]}; 
    assign pagemask_t2r = {32{tlbr}} & {7'd0,tlb[tlb_index][`PageMask],13'd0}; 
    
    // TLBP
    wire [31:0] asid_compare;
    assign asid_compare[31] = tlb[31][`G] | &(tlb[31][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[30] = tlb[30][`G] | &(tlb[30][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[29] = tlb[29][`G] | &(tlb[29][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[28] = tlb[28][`G] | &(tlb[28][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[27] = tlb[27][`G] | &(tlb[27][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[26] = tlb[26][`G] | &(tlb[26][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[25] = tlb[25][`G] | &(tlb[25][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[24] = tlb[24][`G] | &(tlb[24][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[23] = tlb[23][`G] | &(tlb[23][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[22] = tlb[22][`G] | &(tlb[22][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[21] = tlb[21][`G] | &(tlb[21][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[20] = tlb[20][`G] | &(tlb[20][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[19] = tlb[19][`G] | &(tlb[19][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[18] = tlb[18][`G] | &(tlb[18][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[17] = tlb[17][`G] | &(tlb[17][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[16] = tlb[16][`G] | &(tlb[16][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[15] = tlb[15][`G] | &(tlb[15][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[14] = tlb[14][`G] | &(tlb[14][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[13] = tlb[13][`G] | &(tlb[13][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[12] = tlb[12][`G] | &(tlb[12][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[11] = tlb[11][`G] | &(tlb[11][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[10] = tlb[10][`G] | &(tlb[10][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 9] = tlb[ 9][`G] | &(tlb[ 9][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 8] = tlb[ 8][`G] | &(tlb[ 8][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 7] = tlb[ 7][`G] | &(tlb[ 7][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 6] = tlb[ 6][`G] | &(tlb[ 6][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 5] = tlb[ 5][`G] | &(tlb[ 5][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 4] = tlb[ 4][`G] | &(tlb[ 4][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 3] = tlb[ 3][`G] | &(tlb[ 3][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 2] = tlb[ 2][`G] | &(tlb[ 2][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 1] = tlb[ 1][`G] | &(tlb[ 1][`ASID] ^~ entryhi_r2t[7:0]);
    assign asid_compare[ 0] = tlb[ 0][`G] | &(tlb[ 0][`ASID] ^~ entryhi_r2t[7:0]);

    wire [31:0] vpn_compare_p;
    assign vpn_compare_p[31] = &(tlb[31][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[30] = &(tlb[30][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[29] = &(tlb[29][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[28] = &(tlb[28][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[27] = &(tlb[27][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[26] = &(tlb[26][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[25] = &(tlb[25][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[24] = &(tlb[24][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[23] = &(tlb[23][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[22] = &(tlb[22][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[21] = &(tlb[21][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[20] = &(tlb[20][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[19] = &(tlb[19][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[18] = &(tlb[18][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[17] = &(tlb[17][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[16] = &(tlb[16][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[15] = &(tlb[15][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[14] = &(tlb[14][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[13] = &(tlb[13][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[12] = &(tlb[12][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[11] = &(tlb[11][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[10] = &(tlb[10][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 9] = &(tlb[ 9][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 8] = &(tlb[ 8][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 7] = &(tlb[ 7][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 6] = &(tlb[ 6][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 5] = &(tlb[ 5][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 4] = &(tlb[ 4][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 3] = &(tlb[ 3][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 2] = &(tlb[ 2][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 1] = &(tlb[ 1][`VPN2] ^~ entryhi_r2t[`VPN]);
    assign vpn_compare_p[ 0] = &(tlb[ 0][`VPN2] ^~ entryhi_r2t[`VPN]);

    wire [31:0] mask_compare;
    assign mask_compare[31] = &(~{7'd0,tlb[31][`PageMask]});
    assign mask_compare[30] = &(~{7'd0,tlb[30][`PageMask]});
    assign mask_compare[29] = &(~{7'd0,tlb[29][`PageMask]});
    assign mask_compare[28] = &(~{7'd0,tlb[28][`PageMask]});
    assign mask_compare[27] = &(~{7'd0,tlb[27][`PageMask]});
    assign mask_compare[26] = &(~{7'd0,tlb[26][`PageMask]});
    assign mask_compare[25] = &(~{7'd0,tlb[25][`PageMask]});
    assign mask_compare[24] = &(~{7'd0,tlb[24][`PageMask]});
    assign mask_compare[23] = &(~{7'd0,tlb[23][`PageMask]});
    assign mask_compare[22] = &(~{7'd0,tlb[22][`PageMask]});
    assign mask_compare[21] = &(~{7'd0,tlb[21][`PageMask]});
    assign mask_compare[20] = &(~{7'd0,tlb[20][`PageMask]});
    assign mask_compare[19] = &(~{7'd0,tlb[19][`PageMask]});
    assign mask_compare[18] = &(~{7'd0,tlb[18][`PageMask]});
    assign mask_compare[17] = &(~{7'd0,tlb[17][`PageMask]});
    assign mask_compare[16] = &(~{7'd0,tlb[16][`PageMask]});
    assign mask_compare[15] = &(~{7'd0,tlb[15][`PageMask]});
    assign mask_compare[14] = &(~{7'd0,tlb[14][`PageMask]});
    assign mask_compare[13] = &(~{7'd0,tlb[13][`PageMask]});
    assign mask_compare[12] = &(~{7'd0,tlb[12][`PageMask]});
    assign mask_compare[11] = &(~{7'd0,tlb[11][`PageMask]});
    assign mask_compare[10] = &(~{7'd0,tlb[10][`PageMask]});
    assign mask_compare[ 9] = &(~{7'd0,tlb[ 9][`PageMask]});
    assign mask_compare[ 8] = &(~{7'd0,tlb[ 8][`PageMask]});
    assign mask_compare[ 7] = &(~{7'd0,tlb[ 7][`PageMask]});
    assign mask_compare[ 6] = &(~{7'd0,tlb[ 6][`PageMask]});
    assign mask_compare[ 5] = &(~{7'd0,tlb[ 5][`PageMask]});
    assign mask_compare[ 4] = &(~{7'd0,tlb[ 4][`PageMask]});
    assign mask_compare[ 3] = &(~{7'd0,tlb[ 3][`PageMask]});
    assign mask_compare[ 2] = &(~{7'd0,tlb[ 2][`PageMask]});
    assign mask_compare[ 1] = &(~{7'd0,tlb[ 1][`PageMask]});
    assign mask_compare[ 0] = &(~{7'd0,tlb[ 0][`PageMask]});

    wire [31:0] compare_result_p;
    assign compare_result_p[31] = vpn_compare_p[31] & asid_compare[31] & mask_compare[31];
    assign compare_result_p[30] = vpn_compare_p[30] & asid_compare[30] & mask_compare[30];
    assign compare_result_p[29] = vpn_compare_p[29] & asid_compare[29] & mask_compare[29];
    assign compare_result_p[28] = vpn_compare_p[28] & asid_compare[28] & mask_compare[28];
    assign compare_result_p[27] = vpn_compare_p[27] & asid_compare[27] & mask_compare[27];
    assign compare_result_p[26] = vpn_compare_p[26] & asid_compare[26] & mask_compare[26];
    assign compare_result_p[25] = vpn_compare_p[25] & asid_compare[25] & mask_compare[25];
    assign compare_result_p[24] = vpn_compare_p[24] & asid_compare[24] & mask_compare[24];
    assign compare_result_p[23] = vpn_compare_p[23] & asid_compare[23] & mask_compare[23];
    assign compare_result_p[22] = vpn_compare_p[22] & asid_compare[22] & mask_compare[22];
    assign compare_result_p[21] = vpn_compare_p[21] & asid_compare[21] & mask_compare[21];
    assign compare_result_p[20] = vpn_compare_p[20] & asid_compare[20] & mask_compare[20];
    assign compare_result_p[19] = vpn_compare_p[19] & asid_compare[19] & mask_compare[19];
    assign compare_result_p[18] = vpn_compare_p[18] & asid_compare[18] & mask_compare[18];
    assign compare_result_p[17] = vpn_compare_p[17] & asid_compare[17] & mask_compare[17];
    assign compare_result_p[16] = vpn_compare_p[16] & asid_compare[16] & mask_compare[16];
    assign compare_result_p[15] = vpn_compare_p[15] & asid_compare[15] & mask_compare[15];
    assign compare_result_p[14] = vpn_compare_p[14] & asid_compare[14] & mask_compare[14];
    assign compare_result_p[13] = vpn_compare_p[13] & asid_compare[13] & mask_compare[13];
    assign compare_result_p[12] = vpn_compare_p[12] & asid_compare[12] & mask_compare[12];
    assign compare_result_p[11] = vpn_compare_p[11] & asid_compare[11] & mask_compare[11];
    assign compare_result_p[10] = vpn_compare_p[10] & asid_compare[10] & mask_compare[10];
    assign compare_result_p[ 9] = vpn_compare_p[ 9] & asid_compare[ 9] & mask_compare[ 9];
    assign compare_result_p[ 8] = vpn_compare_p[ 8] & asid_compare[ 8] & mask_compare[ 8];
    assign compare_result_p[ 7] = vpn_compare_p[ 7] & asid_compare[ 7] & mask_compare[ 7];
    assign compare_result_p[ 6] = vpn_compare_p[ 6] & asid_compare[ 6] & mask_compare[ 6];
    assign compare_result_p[ 5] = vpn_compare_p[ 5] & asid_compare[ 5] & mask_compare[ 5];
    assign compare_result_p[ 4] = vpn_compare_p[ 4] & asid_compare[ 4] & mask_compare[ 4];
    assign compare_result_p[ 3] = vpn_compare_p[ 3] & asid_compare[ 3] & mask_compare[ 3];
    assign compare_result_p[ 2] = vpn_compare_p[ 2] & asid_compare[ 2] & mask_compare[ 2];
    assign compare_result_p[ 1] = vpn_compare_p[ 1] & asid_compare[ 1] & mask_compare[ 1];
    assign compare_result_p[ 0] = vpn_compare_p[ 0] & asid_compare[ 0] & mask_compare[ 0];

    wire [4:0] hit_index;
    assign hit_index =  {32{compare_result_p[31]}} & 5'b11111 |
                        {32{compare_result_p[30]}} & 5'b11110 |
                        {32{compare_result_p[29]}} & 5'b11101 |
                        {32{compare_result_p[28]}} & 5'b11100 |
                        {32{compare_result_p[27]}} & 5'b11011 |
                        {32{compare_result_p[26]}} & 5'b11010 |
                        {32{compare_result_p[25]}} & 5'b11001 |
                        {32{compare_result_p[24]}} & 5'b11000 |
                        {32{compare_result_p[23]}} & 5'b10111 |
                        {32{compare_result_p[22]}} & 5'b10110 |
                        {32{compare_result_p[21]}} & 5'b10101 |
                        {32{compare_result_p[20]}} & 5'b10100 |
                        {32{compare_result_p[19]}} & 5'b10011 |
                        {32{compare_result_p[18]}} & 5'b10010 |
                        {32{compare_result_p[17]}} & 5'b10001 |
                        {32{compare_result_p[16]}} & 5'b10000 |
                        {32{compare_result_p[15]}} & 5'b01111 |
                        {32{compare_result_p[14]}} & 5'b01110 |
                        {32{compare_result_p[13]}} & 5'b01101 |
                        {32{compare_result_p[12]}} & 5'b01100 |
                        {32{compare_result_p[11]}} & 5'b01011 |
                        {32{compare_result_p[10]}} & 5'b01010 |
                        {32{compare_result_p[ 9]}} & 5'b01001 |
                        {32{compare_result_p[ 8]}} & 5'b01000 |
                        {32{compare_result_p[ 7]}} & 5'b00111 |
                        {32{compare_result_p[ 6]}} & 5'b00110 |
                        {32{compare_result_p[ 5]}} & 5'b00101 |
                        {32{compare_result_p[ 4]}} & 5'b00100 |
                        {32{compare_result_p[ 3]}} & 5'b00011 |
                        {32{compare_result_p[ 2]}} & 5'b00010 |
                        {32{compare_result_p[ 1]}} & 5'b00001 |
                        {32{compare_result_p[ 0]}} & 5'b00000 ;

    assign index_t2r = (|compare_result_p) ? {27'd0,hit_index} : {1'b1,31'd0};
    

/* --------------------------------- load(v2p) ---------------------------------------- */
    wire [31:0] vpn_compare_l;
    assign vpn_compare_l[31] = &(tlb[31][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[30] = &(tlb[30][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[29] = &(tlb[29][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[28] = &(tlb[28][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[27] = &(tlb[27][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[26] = &(tlb[26][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[25] = &(tlb[25][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[24] = &(tlb[24][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[23] = &(tlb[23][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[22] = &(tlb[22][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[21] = &(tlb[21][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[20] = &(tlb[20][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[19] = &(tlb[19][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[18] = &(tlb[18][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[17] = &(tlb[17][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[16] = &(tlb[16][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[15] = &(tlb[15][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[14] = &(tlb[14][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[13] = &(tlb[13][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[12] = &(tlb[12][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[11] = &(tlb[11][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[10] = &(tlb[10][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 9] = &(tlb[ 9][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 8] = &(tlb[ 8][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 7] = &(tlb[ 7][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 6] = &(tlb[ 6][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 5] = &(tlb[ 5][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 4] = &(tlb[ 4][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 3] = &(tlb[ 3][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 2] = &(tlb[ 2][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 1] = &(tlb[ 1][`VPN2] ^~ l_vaddr[`VPN]);
    assign vpn_compare_l[ 0] = &(tlb[ 0][`VPN2] ^~ l_vaddr[`VPN]);    

    wire [31:0] compare_result_l;
    assign compare_result_l[31] = vpn_compare_l[31] & asid_compare[31] & mask_compare[31];
    assign compare_result_l[30] = vpn_compare_l[30] & asid_compare[30] & mask_compare[30];
    assign compare_result_l[29] = vpn_compare_l[29] & asid_compare[29] & mask_compare[29];
    assign compare_result_l[28] = vpn_compare_l[28] & asid_compare[28] & mask_compare[28];
    assign compare_result_l[27] = vpn_compare_l[27] & asid_compare[27] & mask_compare[27];
    assign compare_result_l[26] = vpn_compare_l[26] & asid_compare[26] & mask_compare[26];
    assign compare_result_l[25] = vpn_compare_l[25] & asid_compare[25] & mask_compare[25];
    assign compare_result_l[24] = vpn_compare_l[24] & asid_compare[24] & mask_compare[24];
    assign compare_result_l[23] = vpn_compare_l[23] & asid_compare[23] & mask_compare[23];
    assign compare_result_l[22] = vpn_compare_l[22] & asid_compare[22] & mask_compare[22];
    assign compare_result_l[21] = vpn_compare_l[21] & asid_compare[21] & mask_compare[21];
    assign compare_result_l[20] = vpn_compare_l[20] & asid_compare[20] & mask_compare[20];
    assign compare_result_l[19] = vpn_compare_l[19] & asid_compare[19] & mask_compare[19];
    assign compare_result_l[18] = vpn_compare_l[18] & asid_compare[18] & mask_compare[18];
    assign compare_result_l[17] = vpn_compare_l[17] & asid_compare[17] & mask_compare[17];
    assign compare_result_l[16] = vpn_compare_l[16] & asid_compare[16] & mask_compare[16];
    assign compare_result_l[15] = vpn_compare_l[15] & asid_compare[15] & mask_compare[15];
    assign compare_result_l[14] = vpn_compare_l[14] & asid_compare[14] & mask_compare[14];
    assign compare_result_l[13] = vpn_compare_l[13] & asid_compare[13] & mask_compare[13];
    assign compare_result_l[12] = vpn_compare_l[12] & asid_compare[12] & mask_compare[12];
    assign compare_result_l[11] = vpn_compare_l[11] & asid_compare[11] & mask_compare[11];
    assign compare_result_l[10] = vpn_compare_l[10] & asid_compare[10] & mask_compare[10];
    assign compare_result_l[ 9] = vpn_compare_l[ 9] & asid_compare[ 9] & mask_compare[ 9];
    assign compare_result_l[ 8] = vpn_compare_l[ 8] & asid_compare[ 8] & mask_compare[ 8];
    assign compare_result_l[ 7] = vpn_compare_l[ 7] & asid_compare[ 7] & mask_compare[ 7];
    assign compare_result_l[ 6] = vpn_compare_l[ 6] & asid_compare[ 6] & mask_compare[ 6];
    assign compare_result_l[ 5] = vpn_compare_l[ 5] & asid_compare[ 5] & mask_compare[ 5];
    assign compare_result_l[ 4] = vpn_compare_l[ 4] & asid_compare[ 4] & mask_compare[ 4];
    assign compare_result_l[ 3] = vpn_compare_l[ 3] & asid_compare[ 3] & mask_compare[ 3];
    assign compare_result_l[ 2] = vpn_compare_l[ 2] & asid_compare[ 2] & mask_compare[ 2];
    assign compare_result_l[ 1] = vpn_compare_l[ 1] & asid_compare[ 1] & mask_compare[ 1];
    assign compare_result_l[ 0] = vpn_compare_l[ 0] & asid_compare[ 0] & mask_compare[ 0];

    wire [24:0] entrylo_sel_l;
    assign entrylo_sel_l = 
        (({25{~l_vaddr[12]}} & tlb[31][`EntryLo0] | {25{l_vaddr[12]}} & tlb[31][`EntryLo1]) & {25{compare_result_l[31]}}) |
        (({25{~l_vaddr[12]}} & tlb[30][`EntryLo0] | {25{l_vaddr[12]}} & tlb[30][`EntryLo1]) & {25{compare_result_l[30]}}) |
        (({25{~l_vaddr[12]}} & tlb[29][`EntryLo0] | {25{l_vaddr[12]}} & tlb[29][`EntryLo1]) & {25{compare_result_l[29]}}) |
        (({25{~l_vaddr[12]}} & tlb[28][`EntryLo0] | {25{l_vaddr[12]}} & tlb[28][`EntryLo1]) & {25{compare_result_l[28]}}) |
        (({25{~l_vaddr[12]}} & tlb[27][`EntryLo0] | {25{l_vaddr[12]}} & tlb[27][`EntryLo1]) & {25{compare_result_l[27]}}) |
        (({25{~l_vaddr[12]}} & tlb[26][`EntryLo0] | {25{l_vaddr[12]}} & tlb[26][`EntryLo1]) & {25{compare_result_l[26]}}) |
        (({25{~l_vaddr[12]}} & tlb[25][`EntryLo0] | {25{l_vaddr[12]}} & tlb[25][`EntryLo1]) & {25{compare_result_l[25]}}) |
        (({25{~l_vaddr[12]}} & tlb[24][`EntryLo0] | {25{l_vaddr[12]}} & tlb[24][`EntryLo1]) & {25{compare_result_l[24]}}) |
        (({25{~l_vaddr[12]}} & tlb[23][`EntryLo0] | {25{l_vaddr[12]}} & tlb[23][`EntryLo1]) & {25{compare_result_l[23]}}) |
        (({25{~l_vaddr[12]}} & tlb[22][`EntryLo0] | {25{l_vaddr[12]}} & tlb[22][`EntryLo1]) & {25{compare_result_l[22]}}) |
        (({25{~l_vaddr[12]}} & tlb[21][`EntryLo0] | {25{l_vaddr[12]}} & tlb[21][`EntryLo1]) & {25{compare_result_l[21]}}) |
        (({25{~l_vaddr[12]}} & tlb[20][`EntryLo0] | {25{l_vaddr[12]}} & tlb[20][`EntryLo1]) & {25{compare_result_l[20]}}) |
        (({25{~l_vaddr[12]}} & tlb[19][`EntryLo0] | {25{l_vaddr[12]}} & tlb[19][`EntryLo1]) & {25{compare_result_l[19]}}) |
        (({25{~l_vaddr[12]}} & tlb[18][`EntryLo0] | {25{l_vaddr[12]}} & tlb[18][`EntryLo1]) & {25{compare_result_l[18]}}) |
        (({25{~l_vaddr[12]}} & tlb[17][`EntryLo0] | {25{l_vaddr[12]}} & tlb[17][`EntryLo1]) & {25{compare_result_l[17]}}) |
        (({25{~l_vaddr[12]}} & tlb[16][`EntryLo0] | {25{l_vaddr[12]}} & tlb[16][`EntryLo1]) & {25{compare_result_l[16]}}) |
        (({25{~l_vaddr[12]}} & tlb[15][`EntryLo0] | {25{l_vaddr[12]}} & tlb[15][`EntryLo1]) & {25{compare_result_l[15]}}) |
        (({25{~l_vaddr[12]}} & tlb[14][`EntryLo0] | {25{l_vaddr[12]}} & tlb[14][`EntryLo1]) & {25{compare_result_l[14]}}) |
        (({25{~l_vaddr[12]}} & tlb[13][`EntryLo0] | {25{l_vaddr[12]}} & tlb[13][`EntryLo1]) & {25{compare_result_l[13]}}) |
        (({25{~l_vaddr[12]}} & tlb[12][`EntryLo0] | {25{l_vaddr[12]}} & tlb[12][`EntryLo1]) & {25{compare_result_l[12]}}) |
        (({25{~l_vaddr[12]}} & tlb[11][`EntryLo0] | {25{l_vaddr[12]}} & tlb[11][`EntryLo1]) & {25{compare_result_l[11]}}) |
        (({25{~l_vaddr[12]}} & tlb[10][`EntryLo0] | {25{l_vaddr[12]}} & tlb[10][`EntryLo1]) & {25{compare_result_l[10]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 9][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 9][`EntryLo1]) & {25{compare_result_l[ 9]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 8][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 8][`EntryLo1]) & {25{compare_result_l[ 8]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 7][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 7][`EntryLo1]) & {25{compare_result_l[ 7]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 6][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 6][`EntryLo1]) & {25{compare_result_l[ 6]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 5][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 5][`EntryLo1]) & {25{compare_result_l[ 5]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 4][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 4][`EntryLo1]) & {25{compare_result_l[ 4]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 3][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 3][`EntryLo1]) & {25{compare_result_l[ 3]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 2][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 2][`EntryLo1]) & {25{compare_result_l[ 2]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 1][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 1][`EntryLo1]) & {25{compare_result_l[ 1]}}) |
        (({25{~l_vaddr[12]}} & tlb[ 0][`EntryLo0] | {25{l_vaddr[12]}} & tlb[ 0][`EntryLo1]) & {25{compare_result_l[ 0]}}) ;
   
    // Load paddr 
    assign l_paddr = {entrylo_sel_l[24:5],l_vaddr[11:0]};

/* ----------------------------------- store(v2p) ------------------------------------- */
    wire [31:0] vpn_compare_s;
    assign vpn_compare_s[31] = &(tlb[31][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[30] = &(tlb[30][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[29] = &(tlb[29][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[28] = &(tlb[28][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[27] = &(tlb[27][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[26] = &(tlb[26][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[25] = &(tlb[25][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[24] = &(tlb[24][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[23] = &(tlb[23][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[22] = &(tlb[22][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[21] = &(tlb[21][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[20] = &(tlb[20][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[19] = &(tlb[19][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[18] = &(tlb[18][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[17] = &(tlb[17][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[16] = &(tlb[16][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[15] = &(tlb[15][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[14] = &(tlb[14][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[13] = &(tlb[13][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[12] = &(tlb[12][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[11] = &(tlb[11][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[10] = &(tlb[10][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 9] = &(tlb[ 9][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 8] = &(tlb[ 8][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 7] = &(tlb[ 7][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 6] = &(tlb[ 6][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 5] = &(tlb[ 5][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 4] = &(tlb[ 4][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 3] = &(tlb[ 3][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 2] = &(tlb[ 2][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 1] = &(tlb[ 1][`VPN2] ^~ s_vaddr[`VPN]);
    assign vpn_compare_s[ 0] = &(tlb[ 0][`VPN2] ^~ s_vaddr[`VPN]);  

    wire [31:0] compare_result_s;
    assign compare_result_s[31] = vpn_compare_s[31] & asid_compare[31] & mask_compare[31];
    assign compare_result_s[30] = vpn_compare_s[30] & asid_compare[30] & mask_compare[30];
    assign compare_result_s[29] = vpn_compare_s[29] & asid_compare[29] & mask_compare[29];
    assign compare_result_s[28] = vpn_compare_s[28] & asid_compare[28] & mask_compare[28];
    assign compare_result_s[27] = vpn_compare_s[27] & asid_compare[27] & mask_compare[27];
    assign compare_result_s[26] = vpn_compare_s[26] & asid_compare[26] & mask_compare[26];
    assign compare_result_s[25] = vpn_compare_s[25] & asid_compare[25] & mask_compare[25];
    assign compare_result_s[24] = vpn_compare_s[24] & asid_compare[24] & mask_compare[24];
    assign compare_result_s[23] = vpn_compare_s[23] & asid_compare[23] & mask_compare[23];
    assign compare_result_s[22] = vpn_compare_s[22] & asid_compare[22] & mask_compare[22];
    assign compare_result_s[21] = vpn_compare_s[21] & asid_compare[21] & mask_compare[21];
    assign compare_result_s[20] = vpn_compare_s[20] & asid_compare[20] & mask_compare[20];
    assign compare_result_s[19] = vpn_compare_s[19] & asid_compare[19] & mask_compare[19];
    assign compare_result_s[18] = vpn_compare_s[18] & asid_compare[18] & mask_compare[18];
    assign compare_result_s[17] = vpn_compare_s[17] & asid_compare[17] & mask_compare[17];
    assign compare_result_s[16] = vpn_compare_s[16] & asid_compare[16] & mask_compare[16];
    assign compare_result_s[15] = vpn_compare_s[15] & asid_compare[15] & mask_compare[15];
    assign compare_result_s[14] = vpn_compare_s[14] & asid_compare[14] & mask_compare[14];
    assign compare_result_s[13] = vpn_compare_s[13] & asid_compare[13] & mask_compare[13];
    assign compare_result_s[12] = vpn_compare_s[12] & asid_compare[12] & mask_compare[12];
    assign compare_result_s[11] = vpn_compare_s[11] & asid_compare[11] & mask_compare[11];
    assign compare_result_s[10] = vpn_compare_s[10] & asid_compare[10] & mask_compare[10];
    assign compare_result_s[ 9] = vpn_compare_s[ 9] & asid_compare[ 9] & mask_compare[ 9];
    assign compare_result_s[ 8] = vpn_compare_s[ 8] & asid_compare[ 8] & mask_compare[ 8];
    assign compare_result_s[ 7] = vpn_compare_s[ 7] & asid_compare[ 7] & mask_compare[ 7];
    assign compare_result_s[ 6] = vpn_compare_s[ 6] & asid_compare[ 6] & mask_compare[ 6];
    assign compare_result_s[ 5] = vpn_compare_s[ 5] & asid_compare[ 5] & mask_compare[ 5];
    assign compare_result_s[ 4] = vpn_compare_s[ 4] & asid_compare[ 4] & mask_compare[ 4];
    assign compare_result_s[ 3] = vpn_compare_s[ 3] & asid_compare[ 3] & mask_compare[ 3];
    assign compare_result_s[ 2] = vpn_compare_s[ 2] & asid_compare[ 2] & mask_compare[ 2];
    assign compare_result_s[ 1] = vpn_compare_s[ 1] & asid_compare[ 1] & mask_compare[ 1];
    assign compare_result_s[ 0] = vpn_compare_s[ 0] & asid_compare[ 0] & mask_compare[ 0];

    wire [24:0] entrylo_sel_s;
    assign entrylo_sel_s = 
        (({25{~s_vaddr[12]}} & tlb[31][`EntryLo0] | {25{s_vaddr[12]}} & tlb[31][`EntryLo1]) & {25{compare_result_s[31]}}) |
        (({25{~s_vaddr[12]}} & tlb[30][`EntryLo0] | {25{s_vaddr[12]}} & tlb[30][`EntryLo1]) & {25{compare_result_s[30]}}) |
        (({25{~s_vaddr[12]}} & tlb[29][`EntryLo0] | {25{s_vaddr[12]}} & tlb[29][`EntryLo1]) & {25{compare_result_s[29]}}) |
        (({25{~s_vaddr[12]}} & tlb[28][`EntryLo0] | {25{s_vaddr[12]}} & tlb[28][`EntryLo1]) & {25{compare_result_s[28]}}) |
        (({25{~s_vaddr[12]}} & tlb[27][`EntryLo0] | {25{s_vaddr[12]}} & tlb[27][`EntryLo1]) & {25{compare_result_s[27]}}) |
        (({25{~s_vaddr[12]}} & tlb[26][`EntryLo0] | {25{s_vaddr[12]}} & tlb[26][`EntryLo1]) & {25{compare_result_s[26]}}) |
        (({25{~s_vaddr[12]}} & tlb[25][`EntryLo0] | {25{s_vaddr[12]}} & tlb[25][`EntryLo1]) & {25{compare_result_s[25]}}) |
        (({25{~s_vaddr[12]}} & tlb[24][`EntryLo0] | {25{s_vaddr[12]}} & tlb[24][`EntryLo1]) & {25{compare_result_s[24]}}) |
        (({25{~s_vaddr[12]}} & tlb[23][`EntryLo0] | {25{s_vaddr[12]}} & tlb[23][`EntryLo1]) & {25{compare_result_s[23]}}) |
        (({25{~s_vaddr[12]}} & tlb[22][`EntryLo0] | {25{s_vaddr[12]}} & tlb[22][`EntryLo1]) & {25{compare_result_s[22]}}) |
        (({25{~s_vaddr[12]}} & tlb[21][`EntryLo0] | {25{s_vaddr[12]}} & tlb[21][`EntryLo1]) & {25{compare_result_s[21]}}) |
        (({25{~s_vaddr[12]}} & tlb[20][`EntryLo0] | {25{s_vaddr[12]}} & tlb[20][`EntryLo1]) & {25{compare_result_s[20]}}) |
        (({25{~s_vaddr[12]}} & tlb[19][`EntryLo0] | {25{s_vaddr[12]}} & tlb[19][`EntryLo1]) & {25{compare_result_s[19]}}) |
        (({25{~s_vaddr[12]}} & tlb[18][`EntryLo0] | {25{s_vaddr[12]}} & tlb[18][`EntryLo1]) & {25{compare_result_s[18]}}) |
        (({25{~s_vaddr[12]}} & tlb[17][`EntryLo0] | {25{s_vaddr[12]}} & tlb[17][`EntryLo1]) & {25{compare_result_s[17]}}) |
        (({25{~s_vaddr[12]}} & tlb[16][`EntryLo0] | {25{s_vaddr[12]}} & tlb[16][`EntryLo1]) & {25{compare_result_s[16]}}) |
        (({25{~s_vaddr[12]}} & tlb[15][`EntryLo0] | {25{s_vaddr[12]}} & tlb[15][`EntryLo1]) & {25{compare_result_s[15]}}) |
        (({25{~s_vaddr[12]}} & tlb[14][`EntryLo0] | {25{s_vaddr[12]}} & tlb[14][`EntryLo1]) & {25{compare_result_s[14]}}) |
        (({25{~s_vaddr[12]}} & tlb[13][`EntryLo0] | {25{s_vaddr[12]}} & tlb[13][`EntryLo1]) & {25{compare_result_s[13]}}) |
        (({25{~s_vaddr[12]}} & tlb[12][`EntryLo0] | {25{s_vaddr[12]}} & tlb[12][`EntryLo1]) & {25{compare_result_s[12]}}) |
        (({25{~s_vaddr[12]}} & tlb[11][`EntryLo0] | {25{s_vaddr[12]}} & tlb[11][`EntryLo1]) & {25{compare_result_s[11]}}) |
        (({25{~s_vaddr[12]}} & tlb[10][`EntryLo0] | {25{s_vaddr[12]}} & tlb[10][`EntryLo1]) & {25{compare_result_s[10]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 9][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 9][`EntryLo1]) & {25{compare_result_s[ 9]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 8][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 8][`EntryLo1]) & {25{compare_result_s[ 8]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 7][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 7][`EntryLo1]) & {25{compare_result_s[ 7]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 6][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 6][`EntryLo1]) & {25{compare_result_s[ 6]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 5][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 5][`EntryLo1]) & {25{compare_result_s[ 5]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 4][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 4][`EntryLo1]) & {25{compare_result_s[ 4]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 3][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 3][`EntryLo1]) & {25{compare_result_s[ 3]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 2][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 2][`EntryLo1]) & {25{compare_result_s[ 2]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 1][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 1][`EntryLo1]) & {25{compare_result_s[ 1]}}) |
        (({25{~s_vaddr[12]}} & tlb[ 0][`EntryLo0] | {25{s_vaddr[12]}} & tlb[ 0][`EntryLo1]) & {25{compare_result_s[ 0]}}) ;

    // Store paddr
    assign s_paddr = {entrylo_sel_s[24:5],s_vaddr[11:0]}; 

/* -------------------------------- TLB exceptions ------------------------------------ */
    assign tlb_refill_l  = ~(|vpn_compare_l) & l_vaddr[32];
    assign tlb_refill_s  = ~(|vpn_compare_s) & s_vaddr[32];
    assign tlb_invalid_l =  (|vpn_compare_l) & ~entrylo_sel_l[0];
    assign tlb_invalid_s =  (|vpn_compare_s) & ~entrylo_sel_s[0];
    assign tlb_modified  =  (|vpn_compare_s) & ~entrylo_sel_s[1] & entrylo_sel_s[0] & s_vaddr[32];

endmodule
