 `include "constants.v"
 module stage_wb(
    input wire clk,
    input wire rst_n,
    // from Stage MM
    input wire [31:0] PCInc4_M,
    input wire [31:0] IR_M,
    input wire [31:0] DM_M,
    input wire [31:0] AO_M,
    input wire [31:0] WD3_M,
    // to other stages
    output wire [4:0] A3_W,
    output reg [31:0] WD3_W,
    // control signal output
    output wire ctrl_grf_we_W
 );
    // pipeline
    reg [31:0] PCInc4_W;
    reg [31:0] IR_W;
    reg [31:0] DM_W;
    reg [31:0] AO_W;
    always @(posedge clk) begin
        if (!rst_n) begin
            PCInc4_W <= 0;
            IR_W <= 0;
            DM_W <= 0;
            AO_W <= 0;
            WD3_W <= 0;
        end
        else begin
            PCInc4_W <= PCInc4_M;
            IR_W <= IR_M;
            DM_W <= DM_M;
            AO_W <= AO_M;
            WD3_W <= WD3_M;
        end
    end
    // Controller
    wire [1:0] ctrl_grf_wd_src;
    wire [1:0] ctrl_grf_wa_src;
    controller Controller (
        .clk(clk),
        .rst_n(rst_n),
        .instr(IR_W),
        .ctrl_grf_we(ctrl_grf_we_W),
        .grf_write_addr(A3_W)
    );
    // Debug
    always @(posedge clk) begin
        if (ctrl_grf_we_W && A3_W != 0)
            $display("%d@%h: $%d <= %h", $time, PCInc4_W-4, A3_W, WD3_W);
    end
 endmodule // stage_wb
