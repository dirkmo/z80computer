include "defs.asm"

    org 0
    call iputs
    db "Start\r\n",0

;    call sdcard_init

    ;ld bc,0x0000
    ;ld de,0x0001
    ;ld hl,diskbuf
    ;call sdcard_write
done:
    out (0xff), a
end:
    jp end

include "debug.asm"
include "uart.asm"
include "spi.asm"
include "sdcard.asm"
include "puts.asm"

diskbuf: ds 512
