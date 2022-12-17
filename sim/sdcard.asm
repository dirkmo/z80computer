; sdcard functions

.gen_clks:
    ; after power-up the sd-card needs some clock cycles to initialize
    ; no slave-select needed
    push af
    push bc
    ld a,0
    ld b,10
.gen_clks_loop:
    call spi_wait
    call spi_transmit
    djnz .gen_clks_loop
    pop bc
    pop af
    ret

; send cmd at (hl) and return R1 in a
cmd_r1: ; hl: cmd data
    push bc
    ld b, 6
    call spi_cs_assert
.cmd_r1_loop:
    ld a, (hl)
    inc hl
    call spi_wait
    call spi_transmit
    djnz .cmd_r1_loop
    ; dummy byte
    call spi_wait
    ld a,0xff
    call spi_transmit
    ; fetch response r1
    call spi_transceive
    call spi_cs_deassert
    pop bc
    ret

.cmd0: ; send cmd0, card is idle afterwards
    ; returns: a=0 on success
    ld hl, .cmd0_data
    call cmd_r1
    dec a ; idle bit (#0) should be set
    ret

.cmd8: ; send cmd8, voltage setup
    ld hl, .cmd8_data
    ; cmd8 returns R7, which is R1 + 4 bytes of data
    call cmd_r1
    push af
    ; read 4 bytes
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    ld a,0xff
    call spi_transceive
    pop af
    ret

.acmd41: ; send cmd8, voltage setup
    ld hl, .cmd55_data
    call cmd_r1
    ld hl, .cmd41_data
    call cmd_r1
    cp 1
    jr z, .acmd41
    ret


sdcard_init:
    push hl
    call .gen_clks
    call .cmd0
    call .cmd8
    call .acmd41
    ;jr nz, .sdcard_init_ret

.sdcard_init_ret:
    pop hl
    ret


.cmd0_data:  db 0x40, 0x00, 0x00, 0x00, 0x00, 0x95
.cmd8_data:  db 0x48, 0x00, 0x00, 0x01, 0x00, 0xd5
.cmd17_data: db 0x51, 0x00, 0x01, 0x00, 0x00, 0x0b
.cmd24_data: db 0x58, 0x00, 0x01, 0x00, 0x00, 0x31
.cmd41_data: db 0x69, 0x40, 0x00, 0x00, 0x00, 0x77
.cmd55_data: db 0x77, 0x00, 0x00, 0x00, 0x00, 0x65
.cmd58_data: db 0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd
