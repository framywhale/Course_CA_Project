module Control_Unit(
    input  wire       rst,
    input  wire       zero,
    input  wire [5:0] op,
    input  wire [5:0] func,
    output wire       MemEn,
    output wire       JSrc,
    output wire       MemToReg,
    output wire       is_rs_read,
    output wire       is_rt_read,
    output wire [1:0] PCSrc,
    output wire [1:0] RegDst,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [3:0] ALUop,
    output wire [3:0] RegWrite,
    output wire [3:0] MemWrite
  );
///////////////////////////////////////////////////////
//              Instruction compare                  //
///////////////////////////////////////////////////////
wire inst_lw    = (op == 6'b100011);
wire inst_sw    = (op == 6'b101011);
wire inst_addiu = (op == 6'b001001);
wire inst_beq   = (op == 6'b000100);
wire inst_bne   = (op == 6'b000101);
wire inst_j     = (op == 6'b000010);
wire inst_jal   = (op == 6'b000011);
wire inst_slti  = (op == 6'b001010);
wire inst_sltiu = (op == 6'b001011);
wire inst_lui   = (op == 6'b001111);
wire inst_jr    = (op == 6'd0) && (func == 6'b001000);
wire inst_sll   = (op == 6'd0) && (func == 6'b000000);
wire inst_or    = (op == 6'd0) && (func == 6'b100101);
wire inst_slt   = (op == 6'd0) && (func == 6'b101010);
wire inst_addu  = (op == 6'd0) && (func == 6'b100001);

wire inst_addi  = (op == 6'b001000);
wire inst_andi  = (op == 6'b001100);
wire inst_ori   = (op == 6'b001101);
wire inst_xori  = (op == 6'b001110);
wire inst_add   = (op == 6'd0) && (func == 6'b100000);
wire inst_sub   = (op == 6'd0) && (func == 6'b100010);
wire inst_subu  = (op == 6'd0) && (func == 6'b100011);
wire inst_sltu  = (op == 6'd0) && (func == 6'b101011);
wire inst_and   = (op == 6'd0) && (func == 6'b100100);
wire inst_nor   = (op == 6'd0) && (func == 6'b100111);
wire inst_xor   = (op == 6'd0) && (func == 6'b100110);
wire inst_sllv  = (op == 6'd0) && (func == 6'b000100);
wire inst_sra   = (op == 6'd0) && (func == 6'b000011);
wire inst_srav  = (op == 6'd0) && (func == 6'b000111);
wire inst_srl   = (op == 6'd0) && (func == 6'b000010);
wire inst_srlv  = (op == 6'd0) && (func == 6'b000110);

//////////////////////////////////////////////////////////////////
//                 Control signal assignment                    //
//////////////////////////////////////////////////////////////////
assign MemToReg   = ~rst & inst_lw;
assign JSrc       = ~rst & inst_jr;
assign MemEn      = ~rst & (inst_sw | inst_lw);

assign PCSrc[1]   = ~rst & ((inst_bne&(~zero)) | (inst_beq&zero));
assign PCSrc[0]   = ~rst & (inst_jal    | inst_j     | inst_jr  );

assign ALUSrcA[1] = ~rst & (inst_sll    | inst_sra   | inst_srl );
assign ALUSrcA[0] = ~rst & (inst_jal);

assign ALUSrcB[1] = ~rst & (inst_jal    | inst_ori   | inst_xori  |
                            inst_andi   );
assign ALUSrcB[0] = ~rst & (inst_lw     | inst_sw    | inst_addiu |
                            inst_slti   | inst_sltiu | inst_lui   |
                            inst_addi   | inst_andi  | inst_ori   |
                            inst_xori   );

assign RegDst[1]  = ~rst & (inst_jal);
assign RegDst[0]  = ~rst & (inst_addu   | inst_or    | inst_slt   |
                            inst_sll    | inst_add   | inst_sub   |
                            inst_subu   | inst_sltu  | inst_and   |
                            inst_nor    | inst_xor   | inst_sllv  |
                            inst_sra    | inst_srav  | inst_srl   |
                            inst_srlv   );

assign RegWrite = {4{~rst & (inst_lw    | inst_addiu | inst_slti  |
                             inst_sltiu | inst_lui   | inst_addu  |
                             inst_or    | inst_slt   | inst_sll   |
                             inst_jal   | inst_addi  | inst_andi  |
                             inst_ori   | inst_xori  | inst_add   |
                             inst_sub   | inst_subu  | inst_sltu  |
                             inst_and   | inst_nor   | inst_xor   |
                             inst_sllv  | inst_sra   | inst_srav  |
                             inst_srl   | inst_srlv  )}};
assign MemWrite = {4{~rst & inst_sw}};

// ALUop control signal
assign ALUop[3] = ~rst & (inst_xori |  inst_nor |
                          inst_xor  | inst_sra  | inst_srav  |
                          inst_srl  | inst_srlv );

assign ALUop[2] = ~rst & (inst_slti | inst_slt  | inst_sltiu |
                          inst_sll  | inst_sub  | inst_sltu  |
                          inst_sllv | inst_srl  | inst_srlv  |
                          inst_subu);

assign ALUop[1] = ~rst & (inst_lw   | inst_sw   | inst_addiu |
                          inst_slti | inst_slt  | inst_lui   |
                          inst_jal  | inst_addu | inst_addi  |
                          inst_xori | inst_add  | inst_sub   |
                          inst_xor  | inst_sra  | inst_srav  |
                          inst_subu );

assign ALUop[0] = ~rst & (inst_slti | inst_slt  | inst_or    |
                          inst_lui  | inst_sll  | inst_ori   |
                          inst_nor  | inst_sllv | inst_sra   |
                          inst_srav );

assign is_rs_read = ~rst & ~(inst_j    | inst_jal);
assign is_rt_read = ~rst & ~(inst_addi | inst_addiu | inst_slti | inst_sltiu |
                             inst_andi | inst_lui   | inst_ori  | inst_xori  |
                             inst_j    | inst_jal   | inst_lw );

endmodule
