PORT_UART_ST:           equ 0
PORT_UART_RX:           equ 1
PORT_UART_TX:           equ 1

BIT_UART_ST_RXEMPTY:    equ 1
BIT_UART_ST_RXFULL:     equ 2
BIT_UART_ST_TXEMPTY:    equ 4
BIT_UART_ST_TXFULL:     equ 8

MEM: EQU 60 ; defines upper boundary of BDOS in kB, after that comes the BIOS

BDOS_START: equ (MEM-7)*1024


            org 0
RESET:      jp start

    ds BDOS_START-$,0xff

include '../cpm22/cpm22.asm'

include 'bios.asm'

bios_stack_lo:
            ds 64,0x55
bios_stack:

start:      ld sp, bios_stack
            ld a,0
            ld (IOBYTE),a
            ld (TDRIVE),a
            jp BOOT

if BDOS_START != CBASE
    ERROR BDOS_START and CBASE not identical.
endif

include 'puts.asm'
include 'hexdump.asm'
include 'dph.asm'
