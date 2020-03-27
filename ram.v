module ram(
        input wire clk,
        input wire rst_n,
        input wire [11:0] addr,
        input wire we,
        input wire [31:0] wd,
        output wire [31:0] rd,
        input wire [31:0] PC
    );
    integer i;
    reg [31:0] dataMemory [0:4095];

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<4096; i=i+1) begin
                dataMemory[i] <= 32'h0;
            end
        end
        else begin
            if (we) begin
                dataMemory[addr] = wd;
                $display("%d@%h: *%h <= %h", $time, PC, {18'd0, addr, 2'd0}, wd);
            end
        end
    end
    
    assign rd = dataMemory[addr];

endmodule
