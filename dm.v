`include "constants.v"
module dm(
        input wire clk,
        input wire rst_n,
        input wire [31:0] addr,
        input wire [1:0] ctrl_dm_width,
        input wire ctrl_dm_extend,
        input wire we,
        input wire [31:0] wd,
        output reg [31:0] rd,
        input wire [31:0] PC // debug
    );
    reg [31:0] ramWd;
    reg [31:0] readData;
    wire [31:0] ramRd;
    ram RAM (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr[13:2]),
        .we(we),
        .wd(ramWd),
        .rd(ramRd),
        .PC(PC)
    );
    always @(*) begin
        case (ctrl_dm_width)
            `dmWidth1: begin
                case (addr[1:0])
                    2'b00: begin
                        ramWd = {ramRd[31:8], wd[7:0]};
                        readData = ramRd[7:0];
                    end
                    2'b01: begin
                        ramWd = {ramRd[31:16], wd[7:0], ramRd[7:0]};
                        readData = ramRd[15:8];
                    end
                    2'b10: begin
                        ramWd = {ramRd[31:24], wd[7:0], ramRd[15:0]};
                        readData = ramRd[23:16];
                    end
                    2'b11: begin
                        ramWd = {wd[7:0], ramRd[23:0]};
                        readData = ramRd[31:24];
                    end
                endcase
                case (ctrl_dm_extend)
                    `signExt: rd = {{24{readData[7]}}, readData[7:0]};
                    `zeroExt: rd = {24'd0, readData[7:0]};
                endcase
            end
            `dmWidth2: begin
                case (addr[1])
                    1'b0: begin
                        ramWd = {ramRd[31:16], wd[15:0]};
                        readData = ramRd[15:0];
                    end
                    1'b1: begin
                        ramWd = {wd[15:0], ramRd[15:0]};
                        readData = ramRd[31:16];
                    end
                endcase
                case (ctrl_dm_extend)
                    `signExt: rd = {{16{readData[15]}}, readData[15:0]};
                    `zeroExt: rd = {16'd0, readData[15:0]};
                endcase
            end
            `dmWidth4: begin
                ramWd = wd;
                rd = ramRd;
            end
            default: ;
        endcase
    end
endmodule
