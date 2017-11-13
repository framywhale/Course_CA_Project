module HILO(
    input clk,
    input rst,
    input  [31:0] HI_in,
    input  [31:0] LO_in,
    input  [ 1:0] HILO_Write,
    output [31:0] HI_out,
    output [31:0] LO_out
);

    reg [31:0] HI;
    reg [31:0] LO;
    always @ (posedge clk) begin
        if (rst) begin
            HI <= 32'd0;
            LO <= 32'd0;
        end
        else begin
        if (HILO_Write[1]) HI <= HI_in;
        else               HI <= HI;
        if (HILO_Write[0]) LO <= LO_in;
        else               LO <= LO;
        end
    end

    assign HI_out = HI;
    assign LO_out = LO;
endmodule
