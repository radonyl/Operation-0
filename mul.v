`include "constants.v"
module Multiplier (
           input wire clk,
           input wire rst_n,
           input wire [31:0] A,
           input wire [31:0] B,
           input wire start,
           input wire [3:0] func,
           output reg busy,
           output reg [31:0] HI,
           output reg [31:0] LO
       );
    localparam mulDelay = 5;
    localparam divDelay = 10;
    reg [31:0] delay;
    reg [31:0] buf_A;
    reg [31:0] buf_B;
    reg [3:0] buf_func;
    wire [63:0] mulRes = $signed(buf_A) * $signed(buf_B);
    wire [63:0] unsignedMulRes = buf_A * buf_B;

    always @(posedge clk) begin
        if (!rst_n) begin
            HI <= 0;
            LO <= 0;
            busy <= 0;
            buf_func <= 0;
            buf_A <= 0;
            buf_B <= 0;
        end
        else begin
            if (!busy) begin
                if (start) begin
                    case (func)
                        `mulMULT, `mulMULTU, `mulMADD, `mulMADDU, `mulMSUB, `mulMSUBU: begin
                            delay <= mulDelay;
                            buf_A <= A;
                            buf_B <= B;
                            busy <= 1;
                            buf_func <= func;
                        end
                        `mulDIV, `mulDIVU: begin
                            delay <= divDelay;
                            buf_A <= A;
                            buf_B <= B;
                            busy <= 1;
                            buf_func <= func;
                        end
                        `mulSetLO:
                            LO <= A;
                        `mulSetHI:
                            HI <= A;
                    endcase
                end
            end
            else begin
                if (delay == 0) begin
                    busy <= 0;
                    case (buf_func)
                        `mulMULT:
                            {HI, LO} <= mulRes;
                        `mulMULTU:
                            {HI, LO} <= unsignedMulRes;
                        `mulMADD:
                            {HI, LO} <= {HI, LO} + mulRes;
                        `mulMADDU:
                            {HI, LO} <= {HI, LO} + unsignedMulRes;
                        `mulMSUB:
                            {HI, LO} <= {HI, LO} - mulRes;
                        `mulMSUBU:
                            {HI, LO} <= {HI, LO} - unsignedMulRes;
                        `mulDIV: begin
                            if (buf_B != 0) begin
                                HI <= $signed(buf_A) % $signed(buf_B);
                                LO <= $signed(buf_A) / $signed(buf_B);
                            end                            
                        end
                        `mulDIVU: begin
                            if (buf_B != 0) begin
                                HI <= buf_A % buf_B;
                                LO <= buf_A / buf_B;
                            end
                        end
                    endcase
                end
                else begin
                    delay <= delay - 1;
                end
            end
        end
    end
endmodule