`include "constants.v"
module stage_mm(
    input wire clk,
    input wire rst_n,
    // from Stage EX
    input wire [31:0] PCInc4_E,
    input wire [31:0] IR_E,
    input wire [31:0] AO_E,
    input wire [31:0] RT_E,
    // to Stage WB
    output reg [31:0] PCInc4_M,
    output reg [31:0] IR_M,
    output wire [31:0] DM_M,
    output reg [31:0] WD3_M,
    output wire [4:0] A3_M,
    // to other stages
    output reg [31:0] AO_M,
    // forward control
    output wire ctrl_grf_we_M,
    output wire mem_to_reg_M
);
    // Pipeline
    reg [31:0] RT_M;
    always @(posedge clk) begin
        if (!rst_n) begin
            PCInc4_M <= 0;
            IR_M <= 0;
            AO_M <= 0;
            RT_M <= 0;
        end
        else begin
            PCInc4_M <= PCInc4_E;
            IR_M <= IR_E;
            AO_M <= AO_E;
            RT_M <= RT_E;
        end
    end
    // Controller
    wire ctrl_dm_we;
    wire ctrl_dm_extend;
    wire [1:0] ctrl_dm_width;
    wire ctrl_grf_wd_src;
    wire [1:0] ctrl_grf_wa_src;
    controller Controller (
        .clk(clk),
        .rst_n(rst_n),
        .instr(IR_M),
        .ctrl_dm_we(ctrl_dm_we),
        .ctrl_dm_extend(ctrl_dm_extend),
        .ctrl_dm_width(ctrl_dm_width),
        .ctrl_grf_wd_src(ctrl_grf_wd_src),
        .grf_write_addr(A3_M),
        .ctrl_grf_we(ctrl_grf_we_M) // to collision unit
    );
    assign mem_to_reg_M = (ctrl_grf_wd_src == `fromDm) && ctrl_grf_we_M; // for collision detect
    always @(*) begin
        case (ctrl_grf_wd_src)
            `fromALU: WD3_M = AO_M;
            `fromDm: WD3_M = DM_M;
        endcase
    end
    // Other Blocks
    dm DataMemory (
        .clk(clk),
        .rst_n(rst_n),
        .addr(AO_M),
        .ctrl_dm_width(ctrl_dm_width),
        .ctrl_dm_extend(ctrl_dm_extend),
        .we(ctrl_dm_we),
        .wd(RT_M),
        .rd(DM_M),
        .PC(PCInc4_M-4)
    );
endmodule // stage_mm
