include "defs.asm"

    org 0
    call iputs
    db "SD-Card test program\r\n",0

    call sdcard_init

    ld bc,0
    ld de,0
    ld hl, diskbuf
    call sdcard_read

    ld hl, diskbuf
    ld bc, 512
    ld e,1
    call hexdump


    ld hl, diskbuf
    ld a,(hl)
    inc a
    ld (hl),a

    ld hl,diskbuf+511
    ld a,(hl)
    inc a
    inc a
    ld (hl),a

    ld bc,0
    ld de,0
    ld hl, diskbuf
    call sdcard_write

    call iputs
    db "done\r\n",0

done:
   ; out (0xff), a
end:
    jp end

;include "debug.asm"
include "uart.asm"
include "spi.asm"
include "sdcard.asm"
include "puts.asm"
include "hexdump.asm"

diskbuf: ds 512
