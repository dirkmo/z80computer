; spi functions
spi_transmit: ; a: data to send
    out (PORT_SPI_TX),a
    ret

spi_wait_transmit: ; a: data to send
    call spi_wait
    out (PORT_SPI_TX),a
    ret

spi_transceive: ; a: data to send
    call spi_wait_transmit
    call spi_wait
    in a,(PORT_SPI_RX)
    ret

spi_wait:
    push af
.spi_wait_loop:
    in a, (PORT_SPI_ST)
    and BIT_SPI_ST_BUSY
    jr nz, .spi_wait_loop
    pop af
    ret

spi_cs_assert:
    push af
    ld a, (.spi_divider)
    or BIT_SPI_ST_SEL
    out (PORT_SPI_ST), a
    pop af
    ret

spi_cs_deassert:
    push af
    ld a, (.spi_divider)
    out (PORT_SPI_ST), a
    pop af
    ret

spi_setdiv: ; a: divider 0..7
    and 0x7
    sla a
    ld (.spi_divider),a
    ret

.spi_divider: db 0
