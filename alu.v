`include "constants.v"
module alu(
    input wire [31:0] A,
    input wire [31:0] B,
    output reg [31:0] Y,
    input wire [3:0] ctrl_alu_func,
    output wire overflow
);
reg [32:0] tmp;
wire [32:0] extA = {A[31], A};
wire [32:0] extB = {B[31], B};
assign overflow = tmp[32] != tmp[31];

always @(*) begin
    Y = 0;
    case (ctrl_alu_func) 
        `aluAdd: begin
            tmp = extA + extB;
            Y = tmp[31:0];
        end
        `aluSub: begin
            tmp = extA - extB;
            Y = tmp[31:0];
        end
        `aluAnd:
            Y = A & B;
        `aluOr:
            Y = A | B;
        `aluXor:
            Y = A ^ B;
        `aluNor:
            Y = ~(A | B);
        `aluSL:
            Y = A << B[4:0];
        `aluSR:
            Y = A >> B[4:0];
        `aluSRA:
            Y = $signed(A) >>> B[4:0];
        `aluSLT:
            Y = {31'd0, $signed(A) < $signed(B)};
        `aluSLTU:
            Y = {31'd0, A < B};
        default: 
            Y = 32'hx;
    endcase
end

endmodule // 