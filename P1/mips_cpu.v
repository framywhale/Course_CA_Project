`timescale 10ns / 1ns

module mips_cpu(
    input  rst,
    input  clk,

    output reg [31:0] PC,
    input  [31:0] Instruction,

    output [31:0] Address,
    output reg MemWrite,
    output [31:0] Write_data,

    input  [31:0] Read_data,
    output reg MemRead,

    output reg  [31:0] cycle_cnt,        //counter of total cycles
    output reg [31:0] inst_cnt,         //counter of total instructions
    output reg  [31:0] br_cnt,           //counter of branch/jump instructions
    output reg [31:0] ld_cnt,           //counter of load instructions
    output reg [31:0] st_cnt,           //counter of store instructions
    output reg [31:0] user1_cnt,        //user defined counter (reserved)
    output reg  [31:0] user2_cnt,
    output reg [31:0] user3_cnt				
);

// =================================== Control Unit ===================================
    // OpCode: IR[31:26]
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
    // State definitions
    parameter [3:0] insfetch    = 4'd0, 
                    decode      = 4'd1,
                    memcompu    = 4'd2,
                    oplw        = 4'd3,
                    memrew      = 4'd4,
                    opsw        = 4'd5,
                    r_exe       = 4'd6,
                    rcomplete   = 4'd7,
                    branchexe   = 4'd8,
                    jcomplete   = 4'd9,
                    addiuexe    = 4'd10,
                    addiucomple = 4'd11,
                    jrcomplete  = 4'd12,
                    jal         = 4'd13,
                    writeback   = 4'd14,
                    jal2        = 4'd15;
    // port declarations
    reg [3:0]  state,next_state;
    reg [31:0] IR;
    reg [31:0] ALUout;
    reg RegWrite, MemtoReg, IRWrite, PCWriteCond, PCWrite;
    reg [1:0]  PCSrc, ALUSrcB, ALUSrcA, RegDst, ALUop;
    wire Zero_addr,BrachCond, is_bne, is_beq;
    assign is_bne = (IR[31:26] == BNE) ? 1:0;
    assign is_beq = (IR[31:26] == BEQ) ? 1:0;
    assign BrachCond = (is_bne&(~Zero_addr)) || (is_beq&Zero_addr);

    // -------------------------- FSM -----------------------------------
    always @(state or IR[31:26] or IR[5:0]) begin
        case(state)
            insfetch: begin     // instruction fetch
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_1_00_00_00_01_0_1_0_00_0_1; 
                next_state = decode;
            end

            decode  : begin     // decode
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_11_0_0_0_00_0_0;
                // choose next state of FSM by the OpCode
                if(IR[31:26] == ADDIU)  next_state = addiuexe;
                else if(IR[31:26] == LW  || IR[31:26] == SW || IR[31:26] == LUI || IR[31:26] == SLTI || IR[31:26] == SLTIU)   
                                                                next_state = memcompu;
                else if(IR[31:26] == R_TYPE)                    next_state = r_exe;
                else if(IR[31:26] == JAL)                       next_state = jal; 
                else if(IR[31:26] == J)                         next_state = jcomplete;
                else if(IR[31:26] == BNE || IR[31:26] == BEQ)  begin
                    next_state = branchexe;
                end 
                else begin
                    next_state = insfetch;
                end
            end

            memcompu: begin     // memory address compution
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 15'b0_0_00_01_10_0_0_0_00_0_0;
                // choose next state of FSM by the OpCode
                if(IR[31:26] == LW)          begin next_state = oplw;         ALUop = 2'b00; end   
                else if(IR[31:26] == SW)     begin next_state = opsw;         ALUop = 2'b00; end
                else if(IR[31:26] == LUI)    begin next_state = writeback;    ALUop = 2'b11; end
                else if(IR[31:26] == SLTI)   begin next_state = writeback;    ALUop = 2'b11; end
                else if(IR[31:26] == SLTIU)  begin next_state = writeback;    ALUop = 2'b11; end
            end

            oplw    : begin     // Memory access
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_01_10_0_1_0_00_0_0;
                next_state = memrew;
            end

            memrew  : begin     // Memory read completion step
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_00_1_0_0_00_1_0;
                next_state = insfetch;
            end

            opsw    : begin     // Memory access
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_00_0_0_1_00_0_0; 
                next_state = insfetch;
            end
            
            r_exe    : begin    // R type instructions executions
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 15'b0_0_00_10_00_0_0_0_00_0_0;  
                if(IR[5:0] == JR)        begin next_state = jcomplete; ALUSrcA = 2'b01; end // JR actually is not R type instruction
                else if(IR[5:0] == SLL)  begin next_state = rcomplete; ALUSrcA = 2'b10; end
                else if(IR[5:0] == SUBU) begin next_state = rcomplete; ALUSrcA = 2'b01; end
                else if(IR[5:0] == ADDU) begin next_state = rcomplete; ALUSrcA = 2'b01; end
                else if(IR[5:0] == OR)   begin next_state = rcomplete; ALUSrcA = 2'b01; end 
                else if(IR[5:0] == SLT)  begin next_state = rcomplete; ALUSrcA = 2'b01; end
            end
            
            rcomplete: begin    // R type instructions completion
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_00_0_0_0_01_1_0; 
                next_state = insfetch;
            end

            writeback: begin
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_00_0_0_0_00_1_0;
                next_state = insfetch;
            end
            
            branchexe: begin    // Branch completion
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b1_0_01_01_01_00_0_0_0_00_0_0;
                next_state = insfetch;
            end
            
            jcomplete: begin    // Jump completion
                // Control signal assignments
                {PCWriteCond,PCWrite,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 15'b0_1_00_00_00_0_0_0_00_0_0;  
                if(IR[5:0] == JR) PCSrc = 2'b01;
                else              PCSrc = 2'b10;
                next_state = insfetch;
            end
            
            addiuexe: begin     // addiu execution
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_0_00_00_01_10_0_0_0_00_0_0;
                next_state = addiucomple;
            end
            
            addiucomple: begin  // addiu completion
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_0_00_00_01_00_0_1_0_00_1_0;
                next_state = insfetch;
            end

            jal:    begin       // JAL   PC+
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_01_0_0_0_00_0_0;
                next_state = jal2;
            end 

            jal2:    begin       // JAL execution
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} 
                = 17'b0_0_00_00_00_00_0_0_0_10_1_0;
                next_state = jcomplete;
            end
            
            default: begin  
                // Control signal assignments
                {PCWriteCond,PCWrite,PCSrc,ALUop,ALUSrcA,ALUSrcB,MemtoReg,MemRead,MemWrite,RegDst,RegWrite,IRWrite} = 17'd0;
                next_state = insfetch;
            end

        endcase
    end
   
    // state update 
    always @( posedge clk ) begin
        if(rst) state <= insfetch;
        else    state <= next_state;
        if(IRWrite) IR  <= Instruction;
        else;
   end
    
    // Programme counters
 
          always @(posedge clk) begin //  bne & beq not taken
            if (rst) begin
                user1_cnt <= 'd0;
            end
            else begin
                if((state == branchexe) && (BrachCond == 0))
                    user1_cnt <= user1_cnt+1; 
            end
         end
         
          always @(posedge clk) begin //  bne & beq taken
            if (rst) begin
                user2_cnt <= 'd0;
            end
            else begin
                if((state == branchexe) && (BrachCond == 1))
                user2_cnt <= user2_cnt+1; 
            end
         end
         
          always @(posedge clk) begin //  bne & beq taken
           if (rst) begin
               user3_cnt <= 'd0;
           end
           else begin
                user3_cnt <= 'd0;
           end
        end
        
         always @(posedge clk) begin // cycle counter
            if (rst) begin
                cycle_cnt <= 'd0;
            end
            else begin
                cycle_cnt <= cycle_cnt +1;
            end
         end
         
         always @(posedge clk) begin // instruction counter
            if (rst) begin
                inst_cnt <= 'd0;
            end
            else begin
                if(IRWrite)  inst_cnt <= inst_cnt+1; 
            end
         end
         
         always @(posedge clk) begin // LW instruction counter
            if (rst) begin
                ld_cnt <= 'd0;
            end
            else begin
                if(state == oplw) ld_cnt <= ld_cnt + 1;
            end
         end
         
                  always @(posedge clk) begin // LW instruction counter
            if (rst) begin
                st_cnt <= 'd0;
            end
            else begin
                if(state == opsw) st_cnt <= st_cnt + 1;
            end
         end
         
         always @(posedge clk) begin // Branch instruction counter
            if (rst) begin
                 br_cnt <= 'd0;
            end
            else begin
                 if(state == branchexe || state == jcomplete) 
                     br_cnt <= br_cnt + 1;
            end
         end 
    
// =================================== Register Files ===================================
	// port declarations
    wire [31:0] Regwdata;   //the data that is to be write into reg files
    wire [4:0]  Regwaddr;
    wire [31:0] Regread1,Regread2; 
    reg  [31:0] A,B;
    reg  [31:0] MDR;
    // MUX 1 choose the reg destination
    assign Regwaddr = (RegDst == 2'b00) ? IR[20:16] : ((RegDst == 2'b01) ? IR[15:11] : ((RegDst == 2'b10) ? 5'd31 : 5'd0));
    // choose the source of the Regwdata
    assign Regwdata = (MemtoReg == 1'b0)? ALUout : MDR;
	//module the regfile unit
	reg_file regfile(clk,rst,Regwaddr,IR[25:21],IR[20:16],
					 RegWrite,Regwdata,Regread1,Regread2);
	always @(posedge clk) begin
	   A = Regread1;
	   B = Regread2;
	end

// =================================== ALU Address ===================================
	// port declarations
    wire Carryout_addr;
    wire Overflow_addr;
    reg [31:0] alusrc1;
    wire [31:0] alusrc2;
    wire [31:0] extend_imm;
    wire [31:0] ALUresult;
    reg  [2:0]  ALUcontrol;
    // port asignments
    assign extend_imm = {{16{IR[15]}},IR[15:0]};   // sign_extend
    assign alusrc2    = (ALUSrcB == 2'b00) ? B : (ALUSrcB == 2'b01) ? 32'd4 : (ALUSrcB == 2'b10)? extend_imm : (extend_imm<<2);
    always @ (*)
    begin
        case(ALUSrcA)
            2'b00: alusrc1 = PC;
            2'b01: alusrc1 = A;
            2'b10: alusrc1 = {{27{1'b0}},IR[10:6]};  //sll
            default: alusrc1 = 'd0;
        endcase
    end
    // ALU control Unit
    always @(ALUop or IR[5:0] or IR[31:26]) begin
        if(ALUop == 2'b00)  ALUcontrol = 3'b010;
        else if(ALUop == 2'b01) ALUcontrol =  3'b110;
        else if(ALUop == 2'b10) begin
            case(IR[5:0])
                SUBU: ALUcontrol = 3'b110;
                SLL : ALUcontrol = 3'b101;
                JR  : ALUcontrol = 3'b010;
                ADDU: ALUcontrol = 3'b010;
                OR  : ALUcontrol = 3'b001;
                SLT : ALUcontrol = 3'b111;
                default: ALUcontrol = 3'd0;
            endcase
        end
        else begin
            case(IR[31:26])
                LUI:    ALUcontrol = 3'b100;
                SLTI:   ALUcontrol = 3'b111; 
                SLTIU:  ALUcontrol = 3'b011;
                default: ALUcontrol = 3'd0;
            endcase
        end
    end
	// module the alu unit
	alu alu_address(alusrc1,alusrc2,ALUcontrol,Carryout_addr,Overflow_addr,Zero_addr,ALUresult);
    always @(posedge clk) begin
        if(state == insfetch || state == decode ||
           state == addiuexe || state == r_exe  || 
           state == memcompu || state == jal) ALUout <= ALUresult;
        if(state == oplw)      MDR    <= Read_data;
    end

// =================================== PC ===================================
    always @(posedge clk) begin
    	if (rst) begin
			PC <= 32'd0;	// reset 	
    	end
    	else  begin
    		if( (BrachCond & PCWriteCond) | PCWrite ) begin
                case(PCSrc)
                    2'b00: PC <= ALUresult;
                    2'b01: PC <= ALUout;
                    2'b10: PC <= {PC[31:28],(IR[25:0]<<2)};
                    default: PC <= 'd0;
                endcase
            end
    	end
    end
// ======================= memory API ======================================= 
    assign Address     = ALUout;
    assign Write_data  = B; 

endmodule