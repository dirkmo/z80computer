include "defs.asm"

    org 0

    ld hl, msg
send:
    ld a, (hl)
    cp 0
    jp z, done
    ld c,a
    call uart_putc
    inc hl
    jp send
done:
    call uart_wait_tx_empty
    out (0xff), a
end:
    inc a
    out (PORT_LEDS),a
    jp end

include "spi.asm"
include "uart.asm"

msg: db "Hallo SPI!",13,10,13,10,0
