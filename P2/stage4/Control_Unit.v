module Control_Unit(
    input  wire       rst,
    input  wire       BranchCond,
    input  wire [4:0] rt,
    input  wire [5:0] op,
    input  wire [5:0] func,
    output wire       MemEn,
    output wire       JSrc,
    output wire       MemToReg,
    output wire       is_rs_read,
    output wire       is_rt_read,
    output wire       LB,
    output wire       LBU,
    output wire       LH,
    output wire       LHU,
    output wire [1:0] PCSrc,
    output wire [1:0] RegDst,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [3:0] ALUop,
    output wire [3:0] RegWrite,
    output wire [3:0] MemWrite,
    output wire [5:0] B_Type,
    output wire [1:0] MULT,
    output wire [1:0] DIV,
    output wire [1:0] MFHL,
    output wire [1:0] MTHL,
    output wire [1:0] LW,
    output wire [1:0] SW
  );
///////////////////////////////////////////////////////
//              Instruction compare                  //
///////////////////////////////////////////////////////
wire is_branch;

// Stage 1 Instructions
wire inst_lw     = (op == 6'b100011);
wire inst_sw     = (op == 6'b101011);
wire inst_addiu  = (op == 6'b001001);
wire inst_beq    = (op == 6'b000100);
wire inst_bne    = (op == 6'b000101);
wire inst_j      = (op == 6'b000010);
wire inst_jal    = (op == 6'b000011);
wire inst_slti   = (op == 6'b001010);
wire inst_sltiu  = (op == 6'b001011);
wire inst_lui    = (op == 6'b001111);
wire inst_jr     = (op == 6'b000000) && (func == 6'b001000);
wire inst_sll    = (op == 6'b000000) && (func == 6'b000000);
wire inst_or     = (op == 6'b000000) && (func == 6'b100101);
wire inst_slt    = (op == 6'b000000) && (func == 6'b101010);
wire inst_addu   = (op == 6'b000000) && (func == 6'b100001);

// Stage 2 Instructions
wire inst_addi   = (op == 6'b001000);
wire inst_andi   = (op == 6'b001100);
wire inst_ori    = (op == 6'b001101);
wire inst_xori   = (op == 6'b001110);
wire inst_add    = (op == 6'b000000) && (func == 6'b100000);
wire inst_sub    = (op == 6'b000000) && (func == 6'b100010);
wire inst_subu   = (op == 6'b000000) && (func == 6'b100011);
wire inst_sltu   = (op == 6'b000000) && (func == 6'b101011);
wire inst_and    = (op == 6'b000000) && (func == 6'b100100);
wire inst_nor    = (op == 6'b000000) && (func == 6'b100111);
wire inst_xor    = (op == 6'b000000) && (func == 6'b100110);
wire inst_sllv   = (op == 6'b000000) && (func == 6'b000100);
wire inst_sra    = (op == 6'b000000) && (func == 6'b000011);
wire inst_srav   = (op == 6'b000000) && (func == 6'b000111);
wire inst_srl    = (op == 6'b000000) && (func == 6'b000010);
wire inst_srlv   = (op == 6'b000000) && (func == 6'b000110);

// Stage 3 Instructions
wire inst_div    = (op == 6'b000000) && (func == 6'b011010);
wire inst_divu   = (op == 6'b000000) && (func == 6'b011011);
wire inst_mult   = (op == 6'b000000) && (func == 6'b011000);
wire inst_multu  = (op == 6'b000000) && (func == 6'b011001);
wire inst_mfhi   = (op == 6'b000000) && (func == 6'b010000);
wire inst_mflo   = (op == 6'b000000) && (func == 6'b010010);
wire inst_mthi   = (op == 6'b000000) && (func == 6'b010001);
wire inst_mtlo   = (op == 6'b000000) && (func == 6'b010011);
wire inst_jalr   = (op == 6'b000000) && (func == 6'b001001);
wire inst_bgtz   = (op == 6'b000111) && (rt == 5'd0);
wire inst_blez   = (op == 6'b000110) && (rt == 5'd0);
wire inst_bltz   = (op == 6'b000001) && (rt == 5'd0);
wire inst_bgez   = (op == 6'b000001) && (rt == 5'b00001);
wire inst_bltzal = (op == 6'b000001) && (rt == 5'b10000);
wire inst_bgezal = (op == 6'b000001) && (rt == 5'b10001);

// Stage 4 Instructions
wire inst_lb     = (op == 6'b100000);
wire inst_lbu    = (op == 6'b100100);
wire inst_lh     = (op == 6'b100001);
wire inst_lhu    = (op == 6'b100101);
wire inst_lwl    = (op == 6'b100010);
wire inst_lwr    = (op == 6'b100110);
wire inst_sb     = (op == 6'b101000);
wire inst_sh     = (op == 6'b101001);
wire inst_swr    = (op == 6'b101010);
wire inst_swl    = (op == 6'b101110);

///////////////////////////////////////////////////////////////////////////////
//                        Control signal assignment                          //
///////////////////////////////////////////////////////////////////////////////
assign MemToReg   = ~rst &   inst_lw;
assign JSrc       = ~rst &  (inst_jr   | inst_jalr  );
assign MemEn      = ~rst &  (inst_sw   | inst_lw    );
assign is_rs_read = ~rst & ~(inst_j    | inst_jal   );
assign is_rt_read = ~rst & ~(inst_addi | inst_addiu | inst_slti | inst_sltiu  |
                             inst_andi | inst_lui   | inst_ori  | inst_xori   |
                             inst_j    | inst_jal   | inst_lw   | inst_jalr   );

assign is_branch  = ~rst &  (inst_bne  | inst_blez  | inst_bgez | inst_bgezal |
                             inst_beq  | inst_bltz  | inst_bgtz | inst_bltzal );

assign PCSrc[1]   = ~rst & (is_branch   & BranchCond );
assign PCSrc[0]   = ~rst & (inst_jal    | inst_j     | inst_jr  | inst_jalr );

assign ALUSrcA[1] = ~rst & (inst_sll    | inst_sra   | inst_srl   );
assign ALUSrcA[0] = ~rst & (inst_jal    | inst_jalr  | inst_bltzal|
                            inst_bgezal );

assign ALUSrcB[1] = ~rst & (inst_jal    | inst_ori   | inst_xori   |
                            inst_andi   | inst_jalr  | inst_bgezal |
                            inst_bltzal );
assign ALUSrcB[0] = ~rst & (inst_lw     | inst_sw    | inst_addiu  |
                            inst_slti   | inst_sltiu | inst_lui    |
                            inst_addi   | inst_andi  | inst_ori    |
                            inst_xori   );

assign RegDst[1]  = ~rst & (inst_jal    | inst_bgezal | inst_bltzal );
assign RegDst[0]  = ~rst & (inst_addu   | inst_or     | inst_slt    |
                            inst_sll    | inst_add    | inst_sub    |
                            inst_subu   | inst_sltu   | inst_and    |
                            inst_nor    | inst_xor    | inst_sllv   |
                            inst_sra    | inst_srav   | inst_srl    |
                            inst_srlv   | inst_jalr   | inst_mult   |
                            inst_multu  | inst_div    | inst_divu   |
                            inst_mfhi   | inst_mflo   );

assign RegWrite = {4{~rst & (inst_lw    | inst_addiu  | inst_slti  |
                            inst_sltiu  | inst_lui    | inst_addu  |
                            inst_or     | inst_slt    | inst_sll   |
                            inst_jal    | inst_addi   | inst_andi  |
                            inst_ori    | inst_xori   | inst_add   |
                            inst_sub    | inst_subu   | inst_sltu  |
                            inst_and    | inst_nor    | inst_xor   |
                            inst_sllv   | inst_sra    | inst_srav  |
                            inst_srl    | inst_srlv   | inst_jalr  |
                            inst_bltzal | inst_bgezal | inst_mfhi  |
                            inst_mflo   )}};


assign MemWrite[3] = ~rst & (inst_sw);
assign MemWrite[2] = ~rst & (inst_sw);
assign MemWrite[1] = ~rst & (inst_sw | inst_sh );
assign MemWrite[0] = ~rst & (inst_sw | inst_sb | inst_sh);

// ALUop control signal
assign ALUop[3] = ~rst & (inst_xori   | inst_nor  | inst_xor    |
                          inst_sra    | inst_srav | inst_srl    |
                          inst_srlv   );
assign ALUop[2] = ~rst & (inst_slti   | inst_slt  | inst_sltiu  |
                          inst_sll    | inst_sub  | inst_sltu   |
                          inst_sllv   | inst_srl  | inst_srlv   |
                          inst_subu   );
assign ALUop[1] = ~rst & (inst_lw     | inst_sw   | inst_addiu  |
                          inst_slti   | inst_slt  | inst_lui    |
                          inst_jal    | inst_addu | inst_addi   |
                          inst_xori   | inst_add  | inst_sub    |
                          inst_xor    | inst_sra  | inst_srav   |
                          inst_subu   | inst_jalr | inst_bgezal |
                          inst_bltzal );
assign ALUop[0] = ~rst & (inst_slti   | inst_slt  | inst_or     |
                          inst_lui    | inst_sll  | inst_ori    |
                          inst_nor    | inst_sllv | inst_sra    |
                          inst_srav   );

assign B_Type[5] = inst_bltz | inst_bltzal;
assign B_Type[4] = inst_blez;
assign B_Type[3] = inst_bgtz;
assign B_Type[2] = inst_bgez | inst_bgezal;
assign B_Type[1] = inst_beq;
assign B_Type[0] = inst_bne;

assign MULT[1] = inst_multu;
assign MULT[0] = inst_mult;

assign DIV[1]  = inst_divu;
assign DIV[0]  = inst_div;

assign MFHL[1] = inst_mfhi;
assign MFHL[0] = inst_mflo;

assign MTHL[1] = inst_mthi;
assign MTHL[0] = inst_mtlo;

assign LB  = inst_lb;
assign LBU = inst_lbu;
assign LH  = inst_lh;
assign LHU = inst_lhu;

assign LW[1] = inst_lwl | inst_lw;
assign LW[0] = inst_lwr | inst_lw;

assign SW[1] = inst_swl | inst_sw;
assign SW[0] = inst_swr | inst_sw;

endmodule

module Store_sel(
    input  wire [ 1:0] vaddr,
    input  wire [ 1:0] SW,
    input  wire [31:0] Rt_read_data,
    output wire [31:0] MemWdata
  );
  wire swr = SW[0];
  wire swl = SW[1];
  wire sw  = &SW;

  wire [31:0] swr_1,swr_2,swr_3,swr_4,swr_data;
  wire [31:0] swl_1,swl_2,swl_3,swl_4,swl_data;

  assign swl_1 = {24'd0,Rt_read_data[31:24]};
  assign swl_2 = {16'd0,Rt_read_data[31:16]};
  assign swl_3 = { 8'd0,Rt_read_data[31: 8]};
  assign swl_4 = Rt_read_data;

  assign swl_data = ({32{(~vaddr[1]) & (~vaddr[0])}} & swl_1) |
                    ({32{(~vaddr[1]) & ( vaddr[0])}} & swl_2) |
                    ({32{( vaddr[1]) & (~vaddr[0])}} & swl_3) |
                    ({32{( vaddr[1]) & ( vaddr[0])}} & swl_4) ;

  assign swr_1 =  Rt_read_data;
  assign swr_2 = {Rt_read_data[23:0], 8'd0};
  assign swr_3 = {Rt_read_data[15:0],16'd0};
  assign swr_4 = {Rt_read_data[ 7:0],24'd0};

  assign swr_data = ({32{(~vaddr[1]) & (~vaddr[0])}} & swr_1) |
                    ({32{(~vaddr[1]) & ( vaddr[0])}} & swr_2) |
                    ({32{( vaddr[1]) & (~vaddr[0])}} & swr_3) |
                    ({32{( vaddr[1]) & ( vaddr[0])}} & swr_4) ;

  assign MemWdata = ({32{sw }} & Rt_read_data) |
                    ({32{swl}} & swl_data    ) |
                    ({32{swr}} & swr_data    ) ;

endmodule
