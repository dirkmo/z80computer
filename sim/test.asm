include "defs.asm"

    org 0

    call sdcard_init

done:
    out (0xff), a

end:
    inc a
    out (PORT_LEDS),a
    jp end

include "uart.asm"
include "spi.asm"
include "sdcard.asm"