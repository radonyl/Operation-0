module regs(
    input wire clk,
    input wire rst_n,
    // port 1
    input wire [4:0] a1,
    output reg [31:0] rd1,
    // port 2
    input wire [4:0] a2,
    output reg [31:0] rd2,
    // port 3
    input wire we3,
    input wire [4:0] a3,
    input wire [31:0] wd3
);
    reg [31:0] registers [0:31];
    // reg write
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
           for (i = 0; i < 31; i = i + 1) begin
               registers[i] <= 0;
           end 
        end
        else begin
           if (we3 && a3 != 5'h0) begin
               registers[a3] <= wd3;   
           end
        end
    end

    always @(*) begin
        if (a1 == 0)
            rd1 = 0;
        else if (a1 == a3 && we3)
            rd1 = wd3;
        else
            rd1 = registers[a1];
    end
    always @(*) begin
        if (a2 == 0)
            rd2 = 0;
        else if (a2 == a3 && we3)
            rd2 = wd3;
        else
            rd2 = registers[a2];
    end
endmodule // regs