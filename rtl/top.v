`timescale 1ns / 1ps

module top(
    input i_clk,
    input i_reset
);

reg [7:0] mem[0:8191];

wire [15:0] cpu_addr;
wire [7:0] cpu_di;
wire [7:0] cpu_do;
wire cpu_wr;
wire cpu_mreq;
wire cpu_ioreq;


NextZ80 cpu0(
    .DI(mem[cpu_addr[12:0]]),
    .DO(cpu_do),
    .ADDR(cpu_addr),
    .WR(cpu_wr),
    .MREQ(cpu_mreq),
    .IORQ(cpu_ioreq),
    .HALT(),
    .M1(),
    .CLK(i_clk),
    .RESET(i_reset),
    .INT(1'b0),
    .NMI(1'b0),
    .WAIT(1'b0)
);

assign cpu_di = mem[cpu_addr[12:0]];

always @(posedge i_clk) begin
    if (cpu_mreq && cpu_wr)
        mem[cpu_addr[12:0]] <= cpu_do;
end

initial begin
$readmemh("test.mem", mem);
$display("reading test.mem");
end

endmodule
