`include "constants.v"
module stage_if(
    input wire clk,
    input wire rst_n,
    // collision control
    input wire stall_F,
    // control signal input
    input wire ctrl_pc_src_D,
    // from other stages
    input wire [31:0] NPC_D,
    // to next stage
    output wire [31:0] IR_F,
    output wire [31:0] PCInc4_F,
    // debug
    output reg [31:0] PC
);
    // Pipeline
    assign PCInc4_F = PC + 4;
    always @(posedge clk) begin
        if (!rst_n) begin
            PC <= 32'h3000;
        end
        else if (stall_F) begin
            PC <= PC;
        end
        else begin
            case (ctrl_pc_src_D)
                `fromPCInc4_F: PC <= PCInc4_F; 
                `fromNPC_D: PC <= NPC_D;
            endcase
        end
    end
    // Ohter blocks
    wire [31:0] IR;
    im InstructionMemory (
        .clk(clk),
        .PC(PC),
        .instr(IR)
    );
    assign IR_F = stall_F ? 0 : IR;
endmodule // if
