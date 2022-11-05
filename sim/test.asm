PORT_UART_ST: equ 0
PORT_UART_RX: equ 1
PORT_UART_TX: equ 1

; .area _HEADER (ABS)
;.org 0
    ld hl, msg
send:
    ld a, (hl)
    cp 0
    jp z, end
    ld c,a
    call uart_putc
    inc hl
    jp send

end:
    call uart_wait_tx_empty
    out (0xff), a

;wire [7:0] status = { 4'd0, fifo_tx_full, fifo_tx_empty, fifo_rx_full, fifo_rx_empty };

uart_wait_tx_empty:
    push af
uart_wait_tx_empty_loop:
    in a, (PORT_UART_ST)
    and 4 ; 4: fifo_tx_empty
    cp 4
    jr nz, uart_wait_tx_empty_loop
    pop af
    ret

uart_wait_tx:
    push af
uart_wait_tx_loop:
    in a, (PORT_UART_ST)
    and 8 ; 8: fifo_tx_full
    cp 8
    jr z, uart_wait_tx_loop
    pop af
    ret

uart_putc: ; c: char to send
    push af
    call uart_wait_tx
    ld a, c
    out (PORT_UART_TX), a
    pop af
    ret


msg: db "Hallo Welt!",0
