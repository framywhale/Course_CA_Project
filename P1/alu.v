`define DATA_WIDTH 32

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [2:0] ALUop,
	output reg Overflow,
	output reg CarryOut,
	output reg Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);

	// port declarations
	reg Carryout_sub;
	reg [`DATA_WIDTH - 2:0] Result_sub;
//	reg [`DATA_WIDTH : 0]   Result_sup;

// ===================================	ALU function  ===================================================     
	always @( ALUop or A or B ) begin
	   case( ALUop )
	       3'b000:  begin // and 
	               Result = A & B;
	               CarryOut = 0;
	               Overflow = 0;
	               Zero =  (Result == 0)? 1:0;
	        end
	        
	       3'b001:  begin // or
	               Result = A | B;
	               CarryOut = 0;
                   Overflow = 0;
                   Zero =  (Result == 0)? 1:0;
	        end
	        
	       3'b010:  begin  // add
	               {CarryOut,Result} = A + B;
	               {Carryout_sub,Result_sub} = A[`DATA_WIDTH - 2:0] + B[`DATA_WIDTH - 2:0];
	               Overflow = CarryOut ^ Carryout_sub;
                   Zero =  (Result == 0)? 1:0;
	        end

	       3'b011:  begin  
	       		  // unsigned-number slt
	       		  // {CarryOut,Result_sup} =  {1'b0,A[`DATA_WIDTH-1:0]} + ~{1'b0,B[`DATA_WIDTH-1:0]} + 1;
                  // {Carryout_sub,Result} = A + ~B + 1;
                  // Overflow = CarryOut ^ Carryout_sub;
                   Result[0] = (A < B)? 1 : 0;
	               Result [`DATA_WIDTH - 1:1] = 0; 
	               Zero = 0;
	       	end

	       3'b100:  begin  // LUI shift
	       			Result = {B[15:0],A[15:0]};
	       			Zero = 0;
	       			Overflow = 0;
	       			CarryOut = 0;
	        end

	       3'b101:  begin  // SLL
	       			Result = B << (A[5:0]);
	       			Zero = 0;
	       			Overflow = 0;
	       			CarryOut = 0;
	        end
	        
	       3'b110:  begin  // sub
	               {CarryOut,Result} =  A + ~B + 1;
	               {Carryout_sub, Result_sub} = A[`DATA_WIDTH - 2:0] + ~B[`DATA_WIDTH - 2:0]+1;
	               Overflow = CarryOut ^ Carryout_sub;
	               Zero =  (Result == 0)? 1:0;
	        end
	        
	       3'b111:  begin  // signed-number slt
	               {CarryOut,Result} =  A + ~B + 1;
                   {Carryout_sub, Result_sub} = A[`DATA_WIDTH - 2:0] + ~B[`DATA_WIDTH - 2:0]+1;
                   Overflow = CarryOut ^ Carryout_sub;
                   Result[0] = Result[`DATA_WIDTH - 1]^Overflow;
	               Result [`DATA_WIDTH - 1:1] = 0;   
	               Zero = 0; 
	        end 
	        
	       default: begin
	               Result = 0;
                   Zero = 0;
                   Overflow = 0;
                   CarryOut = 0;
                   Result_sub = 31'd0;
                   Carryout_sub = 0;
                //   Result_sup = 33'd0;
	       end 
	         
	   endcase //case end here
	end  // always end here

endmodule
