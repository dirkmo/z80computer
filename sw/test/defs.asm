; UART ports
PORT_UART_ST:           equ 0
PORT_UART_RX:           equ 1
PORT_UART_TX:           equ 1

; UART_ST bit definitions
BIT_UART_ST_RXEMPTY:    equ 1
BIT_UART_ST_RXFULL:     equ 2
BIT_UART_ST_TXEMPTY:    equ 4
BIT_UART_ST_TXFULL:     equ 8

; SPI ports
PORT_SPI_ST:            equ 2
PORT_SPI_RX:            equ 3
PORT_SPI_TX:            equ 3

; SPI_ST bit definitions
BIT_SPI_ST_SEL:         equ 0x01
BIT_SPI_ST_BUSY:        equ 0x80

; LED port
PORT_LEDS:              equ 0x10

; debug uart
PORT_DEBUG:             equ 0x11
