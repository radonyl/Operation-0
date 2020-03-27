module im(
    input wire clk,
    input wire [31:0] PC,
    output wire [31:0] instr 
);

reg [31:0] instMem [0:4095];
wire [31:0] readAddr = PC - 32'h3000;
initial begin
    $readmemh("code.txt", instMem);
    //$readmemh("../code_handler.txt", instMem, 1120, 2047);
end
assign instr = instMem[readAddr[13:2]];
endmodule