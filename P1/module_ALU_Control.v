module ALUcontrol(          // IR是当前指令寄存器中的指令
    input  [5:0] Func,      // Func是IR[5：0],为fucn字段
    input  [2:0] ALUOp,     // ALUOp是状态机中译码之后的ALUOp
    input  [5:0] Opcode,    // Opcode是IR[31：26]
    output [2:0] ALUcontrol // 输出ALU的控制信号
                            // 其中，Opcode字段目前没有什么用处，在后续修改中需要使用
);
    // Opcode: IR[31:26]
    parameter [5:0] ADDIU   = 6'b001001,
                    LW      = 6'b100011,
                    SW      = 6'b101011,
                    BNE     = 6'b000101,
                    BEQ     = 6'b000100,
                    J       = 6'b000010,
                    JAL     = 6'b000011,
                    R_TYPE  = 6'b000000, 
                    LUI     = 6'b001111, 
                    SLTI    = 6'b001010,
                    SLTIU   = 6'b001011;
    // Fuction: IR[5:0]
    parameter [5:0] JR   = 6'b001000,
                    SLL  = 6'b000000,
                    SUBU = 6'b100011,
                    ADDU = 6'b100001,
                    OR   = 6'b100101,
                    SLT  = 6'b101010;
    
    reg [2:0] aluop，ALU_op;
    reg [5:0] func,opcode;
    
    assign ALUcontrol = ALU_op; // 将ALU_op接到输出接口上
    
    always @(Func or ALUOp or Opcode) begin
       aluop  = ALUOp;
       func   = Func;
       opcode = Opcode;
    end
    
    always @(aluop or func or opcode) begin
        if(aluop == 3'b100)      ALU_op =  3'b111;
        else if(aluop == 3'b101) ALU_op =  3'b100;
        else if(aluop == 3'b011) ALU_op =  3'b011;
        else if(aluop == 3'b000) ALU_op =  3'b000;
        else if(aluop == 3'b001) ALU_op =  3'b110;
        else if(aluop == 3'b010) begin
            case(Func)
                OR:      ALU_op = 3'b001;
                SLT:     ALU_op = 3'b111;
                default: ALU_op = 3'b010;
            endcase
        end
        else ALU_op = 3'b010;
    end
endmodule
