module pll (
	input  clock_in,
	output clock_out,
	output reg locked
	);

parameter W = 1;

reg [W:0] cnt;

always @(posedge clock_in)
    cnt <= cnt + 1;

always @(posedge clock_in)
	if (&cnt)
		locked <= 1;

assign clock_out = cnt[W];

endmodule
