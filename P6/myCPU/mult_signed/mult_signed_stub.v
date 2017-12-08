// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
// Date        : Mon Nov 13 17:01:37 2017
// Host        : DESKTOP-9RQ6B5S running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               g:/Learning/CA/project/P4/ucas_CDE_v0.3/mycpu_verify/rtl/myCPU/mult_signed/mult_signed_stub.v
// Design      : mult_signed
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "mult_gen_v12_0_12,Vivado 2017.1" *)
module mult_signed(CLK, A, B, P)
/* synthesis syn_black_box black_box_pad_pin="CLK,A[32:0],B[32:0],P[65:0]" */;
  input CLK;
  input [32:0]A;
  input [32:0]B;
  output [65:0]P;
endmodule
