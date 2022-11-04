#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <verilated_vcd_c.h>
#include "verilated.h"
#include "Vz80computer.h"
#include "Vz80computer_z80computer.h"
#include "uart.h"

Vz80computer *pCore;
VerilatedVcdC *pTrace = NULL;
uint64_t tickcount = 0;
uint64_t ts = 1000;

uint8_t mem[0x10000];

void opentrace(const char *vcdname) {
    if (!pTrace) {
        pTrace = new VerilatedVcdC;
        pCore->trace(pTrace, 99);
        pTrace->open(vcdname);
    }
}

void tick(int t = 3) {
    if (t&1) {
        pCore->i_clk = 0;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += ts / 2;
    }
    if (t&2) {
        pCore->i_clk = 1;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += ts / 2;
    }
}

void reset() {
    pCore->i_reset = 1;
    tick();
    pCore->i_reset = 0;
}

void handle_mem(Vz80computer *pCore) {
    if (pCore->o_cs) {
        if (pCore->o_we) {
            mem[pCore->o_addr] = pCore->o_dat;
            pCore->i_dat = 0;
        } else {
            pCore->i_dat = mem[pCore->o_addr];
        }
    }
    pCore->i_ack = pCore->o_cs;
}

void handle(Vz80computer *pCore) {
    handle_mem(pCore);
    int rxbyte;
    uart_handle(&rxbyte);
    tick();
}

int program_load(const char *fn, uint16_t offset) {
    FILE *f = fopen(fn, "rb");
    if (!f) {
        fprintf(stderr, "Failed to open file\n");
        return -1;
    }
    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);
    fread(mem, size, 1, f);
    fclose(f);
    return 0;
}

int main(int argc, char *argv[]) {
    printf("z80-computer simulator\n\n");

    if (program_load(argv[1], 0)) {
        fprintf(stderr, "ERROR: Failed to load file '%s'\n", argv[1]);
        return -2;
    }

    Verilated::traceEverOn(true);
    pCore = new Vz80computer();
    opentrace("trace.vcd");

    uart_init(&pCore->i_uart_rx, &pCore->o_uart_tx, &pCore->i_clk, pCore->z80computer->SYS_FREQ/pCore->z80computer->BAUDRATE);

    reset();
    pCore->i_ack = 1;

    while(tickcount < 100*ts) {
        handle(pCore);
    }

    pCore->final();
    delete pCore;

    if (pTrace) {
        pTrace->close();
        delete pTrace;
    }
}
