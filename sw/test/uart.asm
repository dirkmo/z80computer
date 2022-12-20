; uart functions
uart_wait_tx_empty:
    push af
.uart_wait_tx_empty_loop:
    in a, (PORT_UART_ST)
    and BIT_UART_ST_TXEMPTY
    cp BIT_UART_ST_TXEMPTY
    jr nz, .uart_wait_tx_empty_loop
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

uart_puts: ; hl: string to send, null-terminated
    ; destroys af
    push bc
.uart_puts_loop:
    ld a, (hl)
    cp 0
    jp z, .uart_puts_done
    ld c,a
    call uart_putc
    inc hl
    jr .uart_puts_loop
.uart_puts_done:
    pop bc
    ret
