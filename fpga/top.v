`timescale 1ns / 1ps

module top(
    input i_clk,
    input i_reset_n,
    output [17:0] o_addr,
    inout  [7:0] dat,
    output sram_cs,
    output sram_oe,
    output sram_we,
    input i_int,
    input i_nmi,
    output uart_tx,
    input uart_rx
);

wire [15:0] cpu_addr;
reg [7:0] cpu_di;
wire [7:0] cpu_do;
wire cpu_wr;
wire cpu_cs;
wire cpu_we;

z80computer computer(
    .i_clk(i_clk),
    .i_reset(~i_reset_n),
    .o_addr(cpu_addr),
    .o_dat(cpu_do),
    .i_dat(cpu_di),
    .o_we(cpu_wr),
    .o_cs(cpu_cs),
    .i_ack(1'b1),
    .i_int(1'b0),
    .i_nmi(1'b0)
);

assign o_addr = {2'b00, cpu_addr};
assign dat = cpu_we ? cpu_do : 8'dz;
assign sram_cs = cpu_cs;
assign sram_oe = ~cpu_wr;
assign sram_we = cpu_wr;


endmodule
