module multiplyer(
    input  [31:0] x,
    input  [31:0] y,
    input  mul_clk,
    input  resetn,
    input  clken,
    input  mul_signed,
    output [63:0] result
);
wire        rst = ~resetn;
wire        clk = mul_clk;
wire [65:0] temp_signed_r, temp_unsigned_r;
reg         temp_sign_r;

wire [32:0] x_r = mul_signed ? {x[31],x} : {{1'b0}, x};
wire [32:0] y_r = mul_signed ? {y[31],y} : {{1'b0}, y};




mult_signed Signed_Muliplier(
    .CLK  (clk),
    .A    (x_r),
    .B    (y_r),
//    .SCLR (rst),
//    .CE   (clken),
    .P    (temp_signed_r)
);

/*
always @ (posedge clk) begin
    if (rst)
        temp_sign_r <= 0;
    else
        temp_sign_r <= mul_signed;
end
*/
assign result = temp_signed_r[63:0];

endmodule
