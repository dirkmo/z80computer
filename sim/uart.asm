; uart functions
uart_wait_tx_empty:
    push af
uart_wait_tx_empty_loop:
    in a, (PORT_UART_ST)
    and BIT_UART_ST_TXEMPTY
    cp BIT_UART_ST_TXEMPTY
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
