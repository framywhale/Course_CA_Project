`timescale 1ns / 1ps

`define DATA_WIDTH 32

module divider(
        input  wire                   clk,
        input  wire                   rst,         // high active
        input  wire [`DATA_WIDTH-1:0] dividend,
        input  wire [`DATA_WIDTH-1:0] divisor,
        input  wire                   div,         // divider enable
        input  wire                   div_signed,
        output wire [`DATA_WIDTH-1:0] quotient,
        output wire [`DATA_WIDTH-1:0] remainder,   
        output reg                    busy,        // whether divider is running
        output reg                    complete     // whether division is over
    );
    // FSM state signals
    parameter  init         = 2'b00,
               iteration    = 2'b01,
               done         = 2'b11;

    // signals used in FSM 
    // suffic 'C' means current state
    // suffic 'N' means next    state         
    reg                           BusyN, CompleteN;
    reg  [                   2:0] StateC, StateN;
    reg  [                   5:0] CountC, CountN;
    reg  [       `DATA_WIDTH-1:0] QuotientC,QuotientN;
    reg  [         `DATA_WIDTH:0] RemainderC,RemainderN;
    reg  [((`DATA_WIDTH<<1)-1):0] Dividend_64C,Dividend_64N;

    // signals used to mark the sign bit of quotient and remainder
    reg              quotient_signed,remainder_signed;
    // keep the original dividend and divisor data
    reg  [ `DATA_WIDTH-1:0] dividend_cal, divisor_cal;
    // get the sign bit of dividend and divisor
    wire dividend_signed = dividend[31] & div_signed;
    wire divisor_signed  = divisor[31]  & div_signed;
    // get the abs of dividend and divisor
    wire [ `DATA_WIDTH-1:0] dividend_abs, divisor_abs;
    assign dividend_abs = ({32{dividend_signed}}^dividend)
                        + dividend_signed;
    assign divisor_abs  = ({32{divisor_signed}}^divisor)
                        + divisor_signed;

    // keep the sign bit of
    // quotient and remainder
    // to the done state
    always @(posedge clk) begin
        if(rst) begin
            quotient_signed  <= 1'b0;
            remainder_signed <= 1'b0;
            dividend_cal     <= 'd0;
            divisor_cal      <= 'd0;
        end
        else if((div == 1) && (CountC == 6'd0)) begin
            quotient_signed  <= dividend_signed^divisor_signed;
            remainder_signed <= dividend_signed;
            dividend_cal     <= dividend_abs;
            divisor_cal      <= divisor_abs;
        end
        else begin
            quotient_signed  <= quotient_signed;
            remainder_signed <= remainder_signed;
            dividend_cal     <= dividend_cal;
            divisor_cal      <= divisor_cal;
        end
    end
    // --------------------- FSM ---------------------------
    always @(posedge clk) begin
        if(rst == 1) begin
            StateC       <=  init;
            CountC       <=  6'd0;
            RemainderC   <=  `DATA_WIDTH'd0;
            QuotientC    <=  `DATA_WIDTH'd0;
            complete     <=  1'b0;
            busy         <=  1'b0;
            Dividend_64C <= 'd0;
        end
        else begin
            StateC       <= StateN;
            CountC       <= CountN;
            QuotientC    <= QuotientN;
            RemainderC   <= RemainderN;
            complete     <= CompleteN;
            busy         <= BusyN;
            Dividend_64C <= Dividend_64N;
        end
    end
    always @(*)  begin
        case(StateC)
            init: begin
                    QuotientN     = `DATA_WIDTH'd0;
                    RemainderN    = 'd0;
                              
                    if(div == 1) begin
                        StateN       = iteration;
                        BusyN        = 1'b1;
                        CompleteN    = 1'b0;
                        Dividend_64N = {`DATA_WIDTH'd0,dividend_abs};
                        CountN       = CountC+1;
                    end
                    else begin
                        StateN       = init;
                        BusyN        = 1'b0;
                        CompleteN    = 1'b0;
                        Dividend_64N = 'd0;
                        CountN       = 6'd0;
                    end
                end

            iteration: begin
                  //  Dividend_64N = Dividend_64C<<1;
                  RemainderC   = Dividend_64C[63:31]
                               - {1'b0,divisor_cal};
                
                  RemainderN   = RemainderC;

                  if(RemainderC[32] == 1'b1) begin
                      QuotientN    = {QuotientC[30:0],1'b0};
                      Dividend_64N = Dividend_64C<<1;
                  end 
                  else begin
                      QuotientN    = {QuotientC[30:0],1'b1};
                      Dividend_64N = {RemainderC,Dividend_64C[30:0]}<<1;
                  end

                  if(CountC == 6'd32) begin
                      StateN    = done;
                      BusyN     = 1'b1;
                      CompleteN = 1'b1;
                      CountN    = CountC;
                  end
                  else begin
                      StateN    = iteration;
                      BusyN     = 1'b1;
                      CompleteN = 1'b0;
                      CountN    = CountC+1;
                  end
                end

            done:      begin
                  QuotientN        = ({`DATA_WIDTH{quotient_signed}}^QuotientC)
                                   + quotient_signed;
                  RemainderN[31:0] = ({`DATA_WIDTH{remainder_signed}}^Dividend_64N[63:32])
                                   + remainder_signed;
                  RemainderN[32]   = 1'b0;

                  StateN     = init;
                  CompleteN  = 1'b0;
                  BusyN      = 1'b0;
                  CountN     = 6'd0;
            end
        endcase
    end

    assign quotient  = (complete == 1'b1) ? QuotientN : `DATA_WIDTH'd0;
    assign remainder = (complete == 1'b1) ? RemainderN[31:0] : `DATA_WIDTH'd0;

endmodule
