`timescale 1ns / 1ps

module z80computer(
    input i_clk,
    input i_reset,
    output [15:0] o_addr,
    output  [7:0] o_dat,
    input   [7:0] i_dat,
    output o_we,
    output o_cs,
    input i_ack,
    input i_int,
    input i_nmi
);

wire w_m1_n;
wire w_mreq_n;
wire w_iorq_n;
wire w_rd_n;
wire w_wr_n;

tv80s #(.Mode(1), .T2Write(1), .IOWait(0)) cpu0 (
  .clk(i_clk),
  .reset_n(~i_reset),

  .m1_n(w_m1_n),
  .mreq_n(w_mreq_n),
  .iorq_n(w_iorq_n),
  .rd_n(w_rd_n),
  .wr_n(w_wr_n),
  .rfsh_n(),
  .halt_n(),
  .busak_n(),
  .A(o_addr),
  .do(o_dat),
  .di(i_dat),
  .wait_n(o_cs ? i_ack : 1'b1),
  .int_n(~i_int),
  .nmi_n(~i_nmi),
  .busrq_n(1'b1)
);

assign o_we = ~w_wr_n & (~w_mreq_n | ~w_iorq_n);
assign o_cs = (~w_wr_n | ~w_rd_n) & (~w_mreq_n | ~w_iorq_n | ~w_m1_n);


endmodule
