`include "constants.v"
module stage_ex(
    input wire clk,
    input wire rst_n,
    // Forward Contrl
    input wire [1:0] forwardAluA_E,
    input wire [1:0] forwardAluB_E,
    input wire flush_E,
    output wire mulBusy_E,
    output wire mulEnable_E,
    // from Stage ID
    input wire [31:0] PCInc4_D,
    input wire [31:0] IR_D,
    input wire [31:0] IMM_D,
    input wire [31:0] RS_D,
    input wire [31:0] RT_D,
    // from Stage MM
    input wire [31:0] AO_M,
    // from Stage WB
    input wire [31:0] WD3_W,
    // to Stage MM
    output reg [31:0] PCInc4_E,
    output reg [31:0] IR_E,
    output reg [31:0] AO_E,
    output reg [31:0] RT_E,
    // collision
    output wire [4:0] A3_E,
    output wire ctrl_grf_we_E,
    output wire mem_to_reg_E
);
    // Pipeline
    reg [31:0] IMM_E;
    reg [31:0] RT;
    reg [31:0] RS;
    reg [31:0] RS_E;
    always @(posedge clk) begin
        if (!rst_n || flush_E) begin
            PCInc4_E <= 0;
            IR_E <= 0;
            RS <= 0;
            RT <= 0;
            IMM_E <= 0;
        end
        else begin
            PCInc4_E <= PCInc4_D;
            IR_E <= IR_D;
            RS <= RS_D;
            RT <= RT_D;
            IMM_E <= IMM_D;
        end
    end
    // Controller
    wire [3:0] ctrl_alu_func;
    wire [1:0] ctrl_alu_in_b_src;
    wire [1:0] ctrl_alu_out_src;
    wire [3:0] ctrl_mul_func;
    controller ctrl_EX (
        .clk(clk),
        .rst_n(rst_n),
        .instr(IR_E),
        .ctrl_alu_func(ctrl_alu_func),
        .ctrl_alu_in_b_src(ctrl_alu_in_b_src),
        .ctrl_alu_out_src(ctrl_alu_out_src),
        .ctrl_mul_func(ctrl_mul_func),
        .ctrl_grf_we(ctrl_grf_we_E), // collision
        .grf_write_addr(A3_E)
    );
    assign mem_to_reg_E = (ctrl_EX.ctrl_grf_wd_src == `fromDm) && ctrl_grf_we_E; // for collision detect
    assign mulEnable_E =  ctrl_EX.ctrl_mul_func != `mulDisable;
    // Forward Logic
    reg [31:0] aluA;
    reg [31:0] aluB;
    always @(*) begin
        case (forwardAluA_E)
            `doNotForward: RS_E = RS;
            `fwdFrom_WD3_W: RS_E = WD3_W;
            `fwdFrom_AO_M: RS_E = AO_M;
            default: RS_E = 32'hx;
        endcase
        case (forwardAluB_E)
            `doNotForward: RT_E = RT;
            `fwdFrom_WD3_W: RT_E = WD3_W;
            `fwdFrom_AO_M: RT_E = AO_M;
            default: RT_E = 32'hx;
        endcase
    end
    // ALU input MUX
    always @(*) begin
        case (ctrl_EX.ctrl_alu_in_a_src)
            `fromGrfRt: aluA = RT_E;
            `fromGrfRs: aluA = RS_E;
        endcase
    end
    always @(*) begin
        case (ctrl_EX.ctrl_alu_in_b_src)
            `fromGrfRt: aluB = RT_E;
            `fromGrfRs: aluB = RS_E;
            `fromImm: aluB = IMM_E;
            `fromShamt: aluB = {27'b0, IR_E[`shamt]};
        endcase
    end
    // ALU & MUL
    wire [31:0] AO;
    alu ALU (
        .A(aluA),
        .B(aluB),
        .Y(AO),
        .ctrl_alu_func(ctrl_EX.ctrl_alu_func),
        .overflow(overflow)
    );
    wire [31:0] LO;
    wire [31:0] HI;
    Multiplier MUL (
        .clk(clk),
        .rst_n(rst_n),
        .A(aluA),
        .B(aluB),
        .start(mulEnable_E),
        .func(ctrl_EX.ctrl_mul_func),
        .busy(mulBusy_E),
        .HI(HI),
        .LO(LO)
    );
    // ALU Out (to next stage) MUX
    always @(*) begin
        case(ctrl_EX.ctrl_alu_out_src)
            `fromALUOut: AO_E = AO;
            `fromLO: AO_E = LO;
            `fromHI: AO_E = HI;
            `directImm: AO_E = IMM_E; // by pass ALU
        endcase
    end
endmodule // ex
