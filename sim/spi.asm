; spi functions
spi_transmit: ; a: data to send
    out (PORT_SPI_TX),a
    ret

spi_transceive: ; a: data to send
    call spi_transmit
    call spi_wait
    in a,(PORT_SPI_RX)

spi_wait:
    push af
    in a, (PORT_SPI_ST)
    cp BIT_SPI_ST_BUSY
    jr z, spi_wait
    pop af
    ret
