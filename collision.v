`include "constants.v"
module collision(
    // Input   
    input wire [31:0] IR_D,
    input wire [31:0] IR_E,
    input wire [4:0] A3_E,
    input wire [4:0] A3_M,
    input wire [4:0] A3_W,
    input wire ctrl_grf_we_E,
    input wire ctrl_grf_we_M,
    input wire ctrl_grf_we_W,
    input wire mem_to_reg_E,
    input wire mem_to_reg_M,
    input wire mulBusy_E,
    input wire mulEnable_E,
    input wire mulEnable_D,
    input wire ctrl_branch_D,
    input wire ctrl_jump_reg_D,
    // debug
    input wire clk,
    input wire [31:0] PCInc4_D,
    input wire [31:0] PCInc4_E,
    // Output
    output reg stall_F,
    output reg stall_D,
    output reg flush_E,
    output reg forwardCmpA_D,
    output reg forwardCmpB_D,
    output reg [1:0] forwardAluA_E,
    output reg [1:0] forwardAluB_E
);
wire [4:0] rsD = IR_D[`rs];
wire [4:0] rsE = IR_E[`rs];
wire [4:0] rdD = IR_D[`rd];
wire [4:0] rdE = IR_E[`rd];
wire [4:0] rtD = IR_D[`rt];
wire [4:0] rtE = IR_E[`rt];
// Stall 
reg stall, lwStall, branchStall, jumpStall, mulStall;
always @(*) begin
    lwStall = (IR_D[`rs] == IR_E[`rt] || IR_D[`rt] == IR_E[`rt]) && mem_to_reg_E;
    branchStall = (ctrl_branch_D && mem_to_reg_M  && (A3_M == IR_D[`rs] || A3_M == IR_D[`rt])) || // load from mem 
                  (ctrl_branch_D && ctrl_grf_we_E && (A3_E == IR_D[`rs] || A3_E == IR_D[`rt])); // Still in Ex
    jumpStall = (ctrl_jump_reg_D && mem_to_reg_M && A3_M == IR_D[`rs]) ||
                (ctrl_jump_reg_D && ctrl_grf_we_E && A3_E == IR_D[`rs]);
    mulStall = (mulEnable_E || mulBusy_E) && mulEnable_D;
    stall = (lwStall || branchStall || jumpStall || mulStall);
    stall_D = stall;
    stall_F = stall;
    flush_E = stall;
end
// Stage ID Forward
always @(*) begin
    if (IR_D[`rs] != 0 && IR_D[`rs] == A3_M && ctrl_grf_we_M)
        forwardCmpA_D = `fwdFrom_AO_M;
    else
        forwardCmpA_D = `doNotForward;
end

always @(*) begin
    if (IR_D[`rt] != 0 && IR_D[`rt] == A3_M && ctrl_grf_we_M)
        forwardCmpB_D = `fwdFrom_AO_M;
    else
        forwardCmpB_D = `doNotForward;
end

// Stage EX Forward
always @(*) begin
    if (IR_E[`rs] != 0 && IR_E[`rs] == A3_M && ctrl_grf_we_M)
        forwardAluA_E = `fwdFrom_AO_M;
    else if (IR_E[`rs] != 0 && IR_E[`rs] == A3_W && ctrl_grf_we_W)
        forwardAluA_E = `fwdFrom_WD3_W;
    else
        forwardAluA_E = `doNotForward; 
end

always @(*) begin
    if (IR_E[`rt] != 0 && IR_E[`rt] == A3_M && ctrl_grf_we_M)
        forwardAluB_E = `fwdFrom_AO_M;
    else if (IR_E[`rt] != 0 && IR_E[`rt] == A3_W && ctrl_grf_we_W)
        forwardAluB_E = `fwdFrom_WD3_W;
    else
        forwardAluB_E = `doNotForward; 
end
// debug 
`ifdef DEBUG
always @(posedge clk) begin
    if (forwardAluB_E == `fwdFrom_AO_M)
        $display("%d@%h: Forward AO_M -> ALU_B", $time, PCInc4_E-4);
    if (forwardAluB_E == `fwdFrom_WD3_W)
        $display("%d@%h: Forward WD3_W -> ALU_B", $time, PCInc4_E-4);
    if (forwardAluA_E == `fwdFrom_AO_M)
        $display("%d@%h: Forward AO_M -> ALU_A", $time, PCInc4_E-4); 
    if (forwardAluA_E == `fwdFrom_WD3_W)
        $display("%d@%h: Forward WD3_W -> ALU_A", $time, PCInc4_E-4);
    if (forwardCmpB_D == `fwdFrom_AO_M)
        $display("%d@%h: Forward AO_M -> CMP_B", $time, PCInc4_D-4);
    if (forwardCmpA_D == `fwdFrom_AO_M)
        $display("%d@%h: Forward AO_M -> CMP_A", $time, PCInc4_D-4);
    if (stall)
        $display("%d@%h: Stall lw:%d busy:%d, branch:%d", $time, PCInc4_D-4, lwStall, busyStall, branchStall);
end
`endif
endmodule // collision