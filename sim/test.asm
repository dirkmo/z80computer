; UART ports
PORT_UART_ST:           equ 0
PORT_UART_RX:           equ 1
PORT_UART_TX:           equ 1

; UART_ST bit definitions
BIT_UART_ST_RXEMPTY:    equ 1
BIT_UART_ST_RXFULL:     equ 2
BIT_UART_ST_TXEMPTY:    equ 4
BIT_UART_ST_TXFULL:     equ 8

PORT_LEDS:              equ 0x10


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

uart_wait_tx_empty:
    push af
uart_wait_tx_empty_loop:
    in a, (PORT_UART_ST)
    and 4 ; 4: fifo_tx_empty
    cp 4
    jr nz, uart_wait_tx_empty_loop
    pop af
    ret

uart_putc: ; c: char to send
    ; destroys af
    in a, (PORT_UART_ST)
    and BIT_UART_ST_TXFULL
    jr nz, uart_putc
    ld a,c
    out (PORT_UART_TX), a
    ret

msg: db "Hallo Welt!",13,10,0
