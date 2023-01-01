MEM: EQU 60 ; defines upper boundary of BDOS in kB, after that comes the BIOS

BDOS_START: equ (MEM-7)*1024


            org 0
RESET:      jp start

    ds BDOS_START-$,0xff

include "cpm22.asm"

include "bios.asm"

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

include "defs.asm"

include "puts.asm"
include "hexdump.asm"
include "dph.asm"

include "sdcard.asm"
include "spi.asm"
