`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif

module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);
	// Internal declarations 
  reg [`DATA_WIDTH - 1:0] Register_file [(1<<`ADDR_WIDTH) - 1:0];
  integer i = 0;
    
  // data always being read
  assign rdata1 = Register_file[raddr1];
  assign rdata2 = Register_file[raddr2];
   
  always @(posedge clk) begin
      if(rst)  begin    //asynchronous reset signal
         for(i = 0; i < (1<<`ADDR_WIDTH) ; i = i+1 )
              Register_file[i] <= 0;
       end
       else begin
           if(wen && waddr)
                Register_file[waddr] <= wdata;
        end
     end   // always end here    
endmodule