#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <verilated_vcd_c.h>
#include "verilated.h"
#include "Vz80computer.h"
#include "Vz80computer_z80computer.h"

#include "uart.h"
#include "console.h"
#include "spislave.h"
#include "sdcard.h"

//#define _DEBUG_PRINTS

Vz80computer *pCore;
VerilatedVcdC *pTrace = NULL;
uint64_t tickcount = 0;
uint64_t clockcycle_ps = 10000; // clock cycle length in ps

uint8_t mem[0x10000];

bool posedge_clk25mhz = false;

void opentrace(const char *vcdname) {
    if (!pTrace) {
        pTrace = new VerilatedVcdC;
        pCore->trace(pTrace, 99);
        pTrace->open(vcdname);
    }
}

void tick(int t = 3) {
    if (t&1) {
        pCore->i_clk = 1;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += clockcycle_ps / 2;
    }
    if (t&2) {
        pCore->i_clk = 0;
        pCore->eval();
        if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
        tickcount += clockcycle_ps / 2;
    }
}

void reset() {
    pCore->i_reset = 1;
    tick();
    tick();
    tick();
    pCore->i_reset = 0;
}

void handle_mem(Vz80computer *pCore) {
    if (pCore->o_cs) {
        if (pCore->o_we) {
#if defined(_DEBUG_PRINTS)
            if (pCore->z80computer->cpu_opcode_fetch_n) {
                printf("write %04x = %02x\n", pCore->o_addr, pCore->o_dat);
            }
#endif
            mem[pCore->o_addr] = pCore->o_dat;
        } else {
            pCore->i_dat = mem[pCore->o_addr];
#if defined(_DEBUG_PRINTS)
            if (pCore->z80computer->cpu_opcode_fetch_n) {
                printf("read %04x = %02x\n", pCore->o_addr, pCore->i_dat);
            }
#endif
        }
        pCore->i_ack = 1;
    } else {
        pCore->i_ack = 0;
    }
}


void handle(Vz80computer *pCore) {
    handle_mem(pCore);
    int rxbyte;
    if (uart_handle(&rxbyte)) {
        printf("%c", (char)(rxbyte & 0x7f));
        fflush(stdout);
    }
    int spibyte = spislave_handle();
    if (spibyte >= 0) {
        int sdout = sdcard_handle(spibyte);
        if (sdout >= 0) {
            spislave_set_miso((uint8_t)sdout);
        }
    }
#if defined(_DEBUG_PRINTS)
    if (!pCore->z80computer->cpu_opcode_fetch_n) {
        printf("OP %04x: %02x\n", pCore->o_addr, pCore->i_dat);
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

    pCore = new Vz80computer();

#ifdef TRACE
    Verilated::traceEverOn(true);
    opentrace("trace.vcd");
    printf("Trace enabled.\n");
#endif

    uart_init(&pCore->i_uart_rx, &pCore->o_uart_tx, &pCore->z80computer->i_clk, pCore->z80computer->SYS_FREQ/pCore->z80computer->BAUDRATE);
    // if (disk_init("disk.img", 4) < 0) {
    //     fprintf(stderr, "ERROR: Failed to load disk image '%s'\n", "disk.img");
    //     // return -3;
    // }

    console_init();

    spislave_init(&pCore->o_sck, &pCore->i_miso, &pCore->o_mosi, &pCore->o_ss);

    reset();

    // uart_send(1, "La2f4W5b");
    // uart_send(1, "La2f4R");

    printf("-------\n");
    while(!Verilated::gotFinish()) {
        handle(pCore);
#ifdef TRACE
        if(tickcount > 20000*clockcycle_ps) {
            printf("timeout\n");
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
