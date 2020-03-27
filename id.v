`include "constants.v"
module stage_id(
    input wire clk,
    input wire rst_n,
    // Foward Control
    input wire stall_D,
    input wire forwardCmpA_D,
    input wire forwardCmpB_D,
    output wire ctrl_branch_D,
    output wire ctrl_jump_reg_D,
    output wire mulEnable_D,
    // control signal input
    input wire ctrl_grf_we_W,
    // control signal output
    output reg ctrl_pc_src_D, // to if
    // *Datapath*
    // from Stage MM
    input wire [31:0] AO_M,
    // from Stage WB
    input wire [4:0] A3_W,
    input wire [31:0] WD3_W,
    // to Stage IF
    output reg [31:0] NPC_D,
    // *Pipeline*
    // from Stage IF
    input wire [31:0] PCInc4_F,
    input wire [31:0] IR_F,
    // to Stage EX
    output reg [31:0] PCInc4_D,
    output reg [31:0] IR_D,
    output reg [31:0] IMM_D,
    output wire [31:0] RS_D,
    output wire [31:0] RT_D
);
// Pipeline
always @(posedge clk) begin
    if (!rst_n) begin
        PCInc4_D <= 0;
        IR_D <= 0;
    end
    else begin
        if (!stall_D) begin
            PCInc4_D <= PCInc4_F;
            IR_D <= IR_F;
        end
    end
end
regs Registers (
    .clk(clk),
    .rst_n(rst_n),

    .a1(IR_D[`rs]),
    .rd1(RS_D),
    
    .a2(IR_D[`rt]),
    .rd2(RT_D),
    
    .we3(ctrl_grf_we_W),
    .a3(A3_W),
    .wd3(WD3_W)
);
// Controller 
wire [1:0] ctrl_imm_src;
wire [2:0] ctrl_cmp_func;
wire [1:0] ctrl_jump;
controller ctrl_ID (
    .clk(clk),
    .rst_n(rst_n),
    .instr(IR_D),
    // branch
    .ctrl_branch(ctrl_branch_D),
    // jump
    .ctrl_jump(ctrl_jump),
    // imm mux
    .ctrl_imm_src(ctrl_imm_src),
    // cmp
    .ctrl_cmp_func(ctrl_cmp_func)
);
assign ctrl_jump_reg_D = ctrl_jump == `jumpReg;
assign mulEnable_D =  ctrl_ID.ctrl_mul_func != `mulDisable || ctrl_ID.ctrl_alu_out_src == `fromLO || ctrl_ID.ctrl_alu_out_src == `fromHI;
// Branch & Jump Logic
wire cmpOut;
cmp CMP (
    .A(forwardCmpA_D ? AO_M : RS_D),
    .B(forwardCmpB_D ? AO_M : RT_D),
    .Y(cmpOut),
    .func(ctrl_cmp_func)
);
wire [31:0] signExtImm = {{16{IR_D[15]}}, IR_D[`i16]};
always @(*) begin
    NPC_D = 32'bx;
    if (ctrl_jump == `jumpDisable) begin
        if (ctrl_branch_D & cmpOut) begin // Branch
            ctrl_pc_src_D = `fromNPC_D;
            NPC_D = (signExtImm << 2) + PCInc4_D;
        end
        else // Not Brnch
            ctrl_pc_src_D = `fromPCInc4_F;
    end
    else begin
        ctrl_pc_src_D = `fromNPC_D;
        if (ctrl_jump == `jumpImm) begin
            NPC_D = {PCInc4_D[31:28], IR_D[`i26], 2'd0};
        end
        else begin // Jump Reg
            NPC_D = forwardCmpA_D ? AO_M : RS_D;
        end
    end
end 
// IMM_Ediate Ext & MUX
always @(*) begin
    case (ctrl_imm_src)
        `signExt: IMM_D = signExtImm;
        `shiftLeft: IMM_D = {IR_D[`i16], 16'd0};
        `zeroExt: IMM_D = {16'd0, IR_D[`i16]};
        `fromPC: IMM_D = PCInc4_D + 4;
    endcase
end
endmodule // stage_id
