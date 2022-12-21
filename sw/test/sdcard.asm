; sdcard functions

.gen_clks:
    ; after power-up the sd-card needs some clock cycles to initialize
    ; no slave-select needed
    push af
    push bc
    ld a,0
    ld b,10
.gen_clks_loop:
    call spi_wait_transmit
    djnz .gen_clks_loop
    pop bc
    pop af
    ret

; send cmd at (hl) and return R1 in a
.cmd_r1: ; hl: cmd data
    push bc
    ld b, 6
.cmd_r1_loop:
    ld a, (hl)
    inc hl
    call spi_wait_transmit
    djnz .cmd_r1_loop
    ; fetch response r1
    ld b,8
.cmd_r1_rsp_loop:
    ld a,0xff
    call spi_transceive
    ld c,a
    and 0x80
    jr z,.cmd_r1_done
    djnz .cmd_r1_rsp_loop
.cmd_r1_done:
    ld a,c
    pop bc
    ret

.cmd0: ; send cmd0, card is idle afterwards
    ; returns: a=0 on success
    ld hl, .cmd0_data
    call spi_cs_assert
    call .cmd_r1
    call spi_cs_deassert

    push af
    call uart_hexdump_a
    call puts_crlf
    pop af
    dec a ; idle bit (#0) should be set
    ret

.cmd8: ; send cmd8, voltage setup
    ld hl, .cmd8_data
    ; cmd8 returns R7, which is R1 + 4 bytes of data
    call spi_cs_assert
    call .cmd_r1
    push af

    call uart_hexdump_a
    call puts_crlf

    ; read 4 bytes
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    call spi_cs_deassert
    pop af
    ret

.acmd41: ; send cmd8, voltage setup
    ld hl, .cmd55_data
    call spi_cs_assert
    call .cmd_r1
    call spi_cs_deassert
    call spi_cs_assert
    ld hl, .cmd41_data
    call .cmd_r1
    call spi_cs_deassert
    push af

    call uart_hexdump_a
    call puts_crlf

    pop af
    cp 1
    jr z, .acmd41
    ret

sdcard_read: ; read block
    ; destroys a, hl
    ; sector in bc,de
    ; written to (hl)
    ld a,17|0x40
    ld (.cmd_scratch),a
    ld a,b
    ld (.cmd_scratch+1), a
    ld a,c
    ld (.cmd_scratch+2), a
    ld a,d
    ld (.cmd_scratch+3), a
    ld a,e
    ld (.cmd_scratch+4), a
    push hl
    ld hl, .cmd_scratch
    call spi_cs_assert
    call .cmd_r1
    pop hl
    and 0xfe
    cp 0
    jr nz,.sdcard_read_ret ; jump-on-error
    ; wait for start block token
.sdcard_read_fe:
    ld a,0xff
    call spi_transceive
    cp 0xfe
    jr nz, .sdcard_read_fe
    ; receive 512 bytes
    ld bc,512
.sdcard_read_loop:
    ld a,0xff
    call spi_transceive
    ld (hl),a
    inc hl
    dec bc
    ld a,b
    or c
    jr nz,.sdcard_read_loop
    ; fetch crc
    call spi_transceive
    call spi_transceive
.sdcard_read_ret:
    call spi_cs_deassert
    ret

sdcard_write: ; write block
    ; destroys a, hl
    ; sector in bc,de
    ; data from (hl) written to sdcard
    ld a,24|0x40
    ld (.cmd_scratch),a
    ld a,b
    ld (.cmd_scratch+1), a
    ld a,c
    ld (.cmd_scratch+2), a
    ld a,d
    ld (.cmd_scratch+3), a
    ld a,e
    ld (.cmd_scratch+4), a
    push hl
    ld hl, .cmd_scratch
    call spi_cs_assert
    call .cmd_r1
    pop hl
    and 0xfe
    cp 0
    jr nz,.sdcard_write_ret ; jump-on-error
    ; send dummy byte
    ld a, 0xff
    call spi_wait_transmit
    ; send block start token
    ld a, 0xfe
    call spi_wait_transmit
    ; send block data
    ld bc,5;512
.sdcard_write_loop:
    ld a,(hl)
    inc hl
    call spi_wait_transmit
    dec bc
    ld a,b
    or c
    jr nz,.sdcard_write_loop
    ; send crc
    ld a,0xff
    call spi_wait_transmit
    call spi_wait_transmit
    ; receive data response token xxx00101
    call spi_transceive
    and 0x1f
    cp 5
    jr nz, .sdcard_write_ret
.sdcard_write_busy:
    ; wait while sdcard is busy
    ld a,0xff
    call spi_transceive
    cp 0
    jr z, .sdcard_write_busy
.sdcard_write_ret:
    call spi_cs_deassert
    ret

.cmd58: ; read OCR
    ld hl, .cmd58_data
    ; cmd8 returns R3, which is R1 + 4 bytes of data
    call spi_cs_assert
    call .cmd_r1
    push af

    call uart_hexdump_a
    call puts_crlf

    ; read 4 bytes
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    call spi_cs_deassert
    pop af
    ret

sdcard_init:
    push hl

    call spi_cs_deassert

    call iputs
    db "genclks\r\n\0"
    call .gen_clks

    call iputs
    db "cmd0\r\n\0"
    call .cmd0

    call iputs
    db "cmd8\r\n\0"
    ;call .cmd8

    call iputs
    db "cmd58\r\n\0"
    ;call .cmd58

    call iputs
    db "acmd41\r\n\0"
    ;call .acmd41

    call iputs
    db "cmd58\r\n\0"
    ;call .cmd58

    pop hl
    ret

.cmd_scratch: ds 6


.cmd0_data:  db 0x40, 0x00, 0x00, 0x00, 0x00, 0x95
.cmd8_data:  db 0x48, 0x00, 0x00, 0x01, 0x00, 0xd5
.cmd41_data: db 0x69, 0x40, 0x00, 0x00, 0x00, 0x77
.cmd55_data: db 0x77, 0x00, 0x00, 0x00, 0x00, 0x65
.cmd58_data: db 0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd
