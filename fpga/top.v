`timescale 1ns / 1ps
`default_nettype none

`include "pll.v"

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
reg [7:0] cpu_di;
wire [7:0] cpu_do;
wire cpu_we;
wire cpu_cs;
wire cpu_ack;

wire clk25mhz;

reg [2:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @(posedge clk25mhz) begin
    if (!resetn)
        resetn_counter <= resetn_counter + 1;
end

wire pll_locked;
pll pll0(.clock_in(i_clk100mhz), .clock_out(clk25mhz),	.locked(pll_locked));

wire reset = ~pll_locked || ~i_reset_n || ~resetn;

wire cpu_ack;

z80computer #(.BAUDRATE(115200),.SYS_FREQ(25000000)) computer(
    .i_clk(clk25mhz),
    .i_reset(reset),
    .o_addr(cpu_addr),
    .o_dat(cpu_do),
    .i_dat(cpu_di),
    .o_we(cpu_we),
    .o_cs(cpu_cs),
    .i_ack(cpu_ack),
    .i_int(1'b0),
    .i_nmi(1'b0),
    .i_uart_rx(uart_rx),
    .o_uart_tx(uart_tx),
    .o_led1(o_led1),
    .o_led2(o_led2)
);

assign o_addr = {2'b00, cpu_addr};
assign dat = cpu_we ? cpu_do : 8'dz;
assign sram_cs_n = ~cpu_cs;
assign sram_oe_n = cpu_we;
assign sram_we_n = ~cpu_we;

reg [11:0] waitcnt = 0;
assign cpu_ack = &waitcnt;
always @(posedge clk25mhz) begin
    if (cpu_cs) begin
        if(~cpu_ack) begin
            waitcnt <= waitcnt + 1;
        end
    end else begin
        waitcnt <= 0;
    end
end


always @* begin
    case(cpu_addr[15:0])
`include "../fpga/rom.inc"
        default: cpu_di = dat;
    endcase
end

endmodule
