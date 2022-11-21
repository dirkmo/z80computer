`timescale 1ns / 1ps

module top(
    input i_clk100mhz,
    input i_reset_n,
    output [17:0] o_addr,
    inout  [7:0] dat,
    output sram_cs_n,
    output sram_oe_n,
    output sram_we_n,
    input i_int,
    input i_nmi,
    output uart_tx,
    input uart_rx,
    output o_led1,
    output o_led2
);

wire [15:0] cpu_addr;
wire [7:0] cpu_di;
wire [7:0] cpu_do;
wire cpu_wr;
wire cpu_cs;
wire cpu_we;

wire clk25mhz;

pll pll0(.clock_in(i_clk100mhz), .clock_out(clk25mhz),	.locked());

z80computer #(.BAUDRATE(9600),.SYS_FREQ(25000000)) computer(
    .i_clk(clk25mhz),
    .i_reset(~i_reset_n),
    .o_addr(cpu_addr),
    .o_dat(cpu_do),
    .i_dat(cpu_di),
    .o_we(cpu_wr),
    .o_cs(cpu_cs),
    .i_ack(1'b1),
    .i_int(1'b0),
    .i_nmi(1'b0),
    .o_led2(o_led2)
);

assign o_addr = {2'b00, cpu_addr};
assign dat = cpu_we ? cpu_do : 8'dz;
assign sram_cs_n = ~cpu_cs;
assign sram_oe_n = cpu_wr;
assign sram_we_n = ~cpu_wr;

reg [23:0] counter;
always @(posedge clk25mhz)
    if(i_reset_n)
        counter <= counter + 1;

assign o_led1 = o_cs;

always @* begin
    case(o_addr)
`include "rom.inc"
        default: cpu_di = dat;
    endcase
end

endmodule
