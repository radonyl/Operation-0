`include "constants.v"
module cmp(
    input wire signed [31:0] A,
    input wire signed [31:0] B,
    output reg Y,
    input wire [2:0] func
);
always @(*) begin
    case (func)
        `cmpGreaterThanZero: Y = (A > 0);
        `cmpNotLessThanZero: Y = (A >= 0);
        `cmpLessThanZero: Y = (A < 0);
        `cmpNotGreaterThanZero: Y = (A <= 0); 
        `cmpEqual: Y = (A == B);
        `cmpNotEqual: Y = (A != B);
        default: Y = 1'bx;
    endcase
end
endmodule // cmp