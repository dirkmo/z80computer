#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <verilated_vcd_c.h>
#include "verilated.h"
#include "Vtop_z80computer__B1c200.h"
#include "Vtop_top.h"
#include "Vtop.h"

#include "uart.h"
#include "console.h"
#include "disk.h"

//#define _DEBUG_PRINTS

#define PORT_DISK_CFG 2
#define PORT_DISK_IO  3

Vtop *pCore;
VerilatedVcdC *pTrace = NULL;
uint64_t tickcount = 0;
uint64_t clockcycle_ps = 10000; // clock cycle length in ps

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
        pCore->i_clk100mhz = 1;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += clockcycle_ps / 2;
    }
    if (t&2) {
        pCore->i_clk100mhz = 0;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += clockcycle_ps / 2;
    }
}

void reset() {
    pCore->i_reset_n = 0;
    tick();
    pCore->i_reset_n = 1;
}

void handle_mem(Vtop *pCore) {
    static int ackcnt = 0;
    if (pCore->sram_cs_n) {
        if (pCore->sram_we_n) {
#if defined(_DEBUG_PRINTS)
            if (pCore->z80computer->cpu_opcode_fetch_n) {
                printf("write %04x = %02x\n", pCore->o_addr, pCore->o_dat);
            }
#endif
            mem[pCore->o_addr] = pCore->dat;
        } else {
            pCore->dat = mem[pCore->o_addr];
#if defined(_DEBUG_PRINTS)
            if (pCore->z80computer->cpu_opcode_fetch_n) {
                printf("read %04x = %02x\n", pCore->o_addr, pCore->i_dat);
            }
#endif
        }
    }
}


void handle(Vtop *pCore) {
    handle_mem(pCore);
    int rxbyte;
    if (uart_handle(&rxbyte)) {
        printf("%c", rxbyte);
        fflush(stdout);
    }
#ifdef _DEBUG_PRINTS
    if (!pCore->z80computer->cpu_opcode_fetch_n) {
        printf("OP %04x\n", pCore->o_addr);
    }
#endif
    unsigned char ch = console_getc();
    if (ch != 255) {
        uart_putc(0, ch);
    }
    tick();
}

int program_load(const char *fn, uint16_t offset) {
    FILE *f = fopen(fn, "rb");
    if (!f) {
        fprintf(stderr, "%s: Failed to open file\n", __func__);
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
    printf("z80-computer simulator\n");

    if (program_load(argv[1], 0)) {
        fprintf(stderr, "ERROR: Failed to load program file '%s'\n", argv[1]);
        return -2;
    }

    pCore = new Vtop();

#ifdef TRACE
    Verilated::traceEverOn(true);
    opentrace("trace.vcd");
    printf("Trace enabled.\n");
#endif

    uart_init(&pCore->uart_rx, &pCore->uart_tx, &pCore->i_clk100mhz, pCore->top->computer->SYS_FREQ/pCore->top->computer->BAUDRATE);
    if (disk_init("disk.img", 4) < 0) {
        fprintf(stderr, "ERROR: Failed to load disk image '%s'\n", "disk.img");
        // return -3;
    }

    console_init();

    reset();

    uart_send(1, "L1234W56");

    printf("-------\n");
    while( !Verilated::gotFinish()) {
        handle(pCore);
#ifdef TRACE
        if(tickcount > 100000*clockcycle_ps) {
            break;
        }
#endif
    }

    pCore->final();
    delete pCore;

    if (pTrace) {
        pTrace->close();
        delete pTrace;
    }
}
