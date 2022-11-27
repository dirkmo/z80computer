`timescale 1ns / 1ps
`default_nettype none

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
    input i_nmi,
    input i_uart_rx,
    output o_uart_tx,
    output reg o_led1,
    output reg o_led2
);

parameter
    BAUDRATE /* verilator public */ = 115200,
    SYS_FREQ /* verilator public */ = 25000000;

// wire vgamaster_access;
// reg r_vgamaster_active;
reg r_uartmaster_active;
reg r_cpumaster_active;

// CPU
wire cpu_m1_n;
wire cpu_mreq_n;
wire cpu_iorq_n;
wire cpu_rd_n;
wire cpu_wr_n;
wire cpu_we = ~cpu_wr_n & (~cpu_mreq_n || ~cpu_iorq_n);
wire cpu_memcs = (~cpu_wr_n || ~cpu_rd_n) && ~cpu_mreq_n;
wire cpu_iocs /* verilator public */ = (~cpu_wr_n || ~cpu_rd_n) && (~cpu_iorq_n && cpu_m1_n);
wire [15:0] o_cpu_addr;
wire [7:0] o_cpu_dat;
wire [7:0] i_cpu_dat;
wire cpu_int;
wire cpu_int_ack = cpu_iorq_n && cpu_m1_n;
wire cpu_opcode_fetch_n /* verilator public */ = cpu_mreq_n || cpu_m1_n;
wire cpu_wait_n;
wire halt_n;

wire reset;

tv80s #(.Mode(0), .T2Write(1), .IOWait(0)) cpu0 (
  .clk(i_clk),
  .reset_n(~reset),

  .m1_n(cpu_m1_n),
  .mreq_n(cpu_mreq_n),
  .iorq_n(cpu_iorq_n),
  .rd_n(cpu_rd_n),
  .wr_n(cpu_wr_n),
  .rfsh_n(),
  .halt_n(halt_n),
  .busak_n(),
  .A(o_cpu_addr),
  .do(o_cpu_dat),
  .di(i_cpu_dat),
  .wait_n(cpu_wait_n),
  .int_n(1'b1), //~cpu_int),
  .nmi_n(1'b1), //~i_nmi),
  .busrq_n(1'b1)
);

// UART master/slave
wire [15:0] o_uartmaster_addr;
wire [7:0] o_uartmaster_dat;
wire uartmaster_we;
wire uartmaster_cs;
wire uartmaster_ack;

wire [7:0] o_uartslave_dat;
wire [7:0] i_uartslave_dat;
wire o_uartslave_ack;
wire i_uartslave_we;
wire i_uartslave_cs;

wire o_uart_reset;
wire o_uart_int;

UartMasterSlave #(.BAUDRATE(BAUDRATE),.SYS_FREQ(SYS_FREQ)) uart(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_master_data(i_dat),
    .o_master_data(o_uartmaster_dat),
    .o_master_addr(o_uartmaster_addr),
    .i_master_ack(uartmaster_ack),
    .o_master_we(uartmaster_we),
    .o_master_cs(uartmaster_cs),

    .i_slave_data(o_dat),
    .o_slave_data(o_uartslave_dat),
    .i_slave_addr(o_addr[0]),
    .o_slave_ack(o_uartslave_ack),
    .i_slave_we(cpu_we),
    .i_slave_cs(i_uartslave_cs),
    .o_int(o_uart_int),

    .i_uart_rx(i_uart_rx),
    .o_uart_tx(o_uart_tx),

    .o_reset(o_uart_reset)
);

assign i_uartslave_cs = cpu_iocs && (o_cpu_addr[7:1] == 7'd0); // uart-slave on port 0 (status), 1 (rx/tx)



// multi-master handling

assign reset = o_uart_reset || i_reset;

// note: vgamaster never outputs data
assign          o_dat = r_uartmaster_active ? o_uartmaster_dat :
                         r_cpumaster_active ? o_cpu_dat : 0;

assign         o_addr =  //r_vgamaster_active ? o_vgamaster_addr :
                        r_uartmaster_active ? o_uartmaster_addr :
                         r_cpumaster_active ? o_cpu_addr : 0;

assign           o_we =   //r_vgamaster_active ? 1'b0 :
                         r_uartmaster_active ? uartmaster_we :
                          r_cpumaster_active ? cpu_we : 0;

assign           o_cs =   //r_vgamaster_active ? vgamaster_cs :
                         r_uartmaster_active ? uartmaster_cs :
                          r_cpumaster_active ? cpu_memcs : 0;

wire cpu_ioack = i_uartslave_cs && o_uartslave_ack;
assign i_cpu_dat = i_uartslave_cs ? o_uartslave_dat : i_dat;

assign cpu_ack      = r_cpumaster_active && ((cpu_memcs == i_ack) || (cpu_iocs == cpu_ioack));
assign uartmaster_ack = r_uartmaster_active && uartmaster_cs && i_ack;

always @(posedge i_clk)
begin
    // r_vgamaster_active <= 0;
    r_uartmaster_active <= 0;
    r_cpumaster_active <= 0;
    // if (vgamaster_access)
    //     r_vgamaster_active  <= 1; // vga has highest bus priority
    //else
    if (uartmaster_cs)
        r_uartmaster_active <= 1;
    else
        r_cpumaster_active  <= 1; // cpu has lowest priority
end

reg [7:0] waitcnt = 0;
wire cpu_ack = &waitcnt;
always @(posedge i_clk) begin
    if (o_cs) begin
        if(~cpu_ack) begin
            waitcnt <= waitcnt + 1;
        end
    end else begin
        waitcnt <= 0;
    end
end

assign cpu_int = i_int || o_uart_int;

//assign cpu_wait_n = o_cs ? cpu_ack : 1'b1;
assign cpu_wait_n = r_cpumaster_active  ? (cpu_memcs ? i_ack : 1'b1)
                                        : 1'b0;

// leds
wire leds_cs = cpu_iocs && (o_cpu_addr[7:0] == 8'h10);
always @(posedge i_clk) begin
    if (leds_cs && cpu_we) begin
        {o_led2, o_led1} <= o_cpu_dat[1:0];
    end
end

`ifdef SIM
always @(posedge i_clk)
   if (o_cpu_addr[7:0] == 8'hff && ~cpu_iorq_n)
       $finish;
`endif

endmodule
