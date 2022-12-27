; sdcard functions

; all functions do not preserve registers

.debug_prints: equ 0


.gen_clks:
    ; after power-up the sd-card needs some clock cycles to initialize
    ; no slave-select needed
    ld a,0xff
    ld b,10
.gen_clks_loop:
    call spi_wait_transmit
    djnz .gen_clks_loop
    ret


; send cmd at (hl) and return R1 in a
.cmd_r1: ; hl: cmd data
    ; send dummy byte, this prevents errors on some cards!?
    ld a,0xff
    call spi_wait_transmit
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
    ret


; send cmd at (hl) and return R3/7 in registers
; R1: a, R3/7 in b,c,d,e
.cmd_r7:
    call .cmd_r1
    push af
    ; read 4 bytes
    ld a,0xff
    call spi_transceive
    ld b,a
    ld a,0xff
    call spi_transceive
    ld c,a
    ld a,0xff
    call spi_transceive
    ld d,a
    ld a,0xff
    call spi_transceive
    ld e,a
    pop af
    ret


.cmd0: ; send cmd0, card is idle afterwards
    ; returns: a=1 on success
    ld hl, .cmd0_data
    call spi_cs_assert
    call .cmd_r1
    call spi_cs_deassert
    ret


.cmd8: ; send cmd8, voltage setup
       ; destroys bc,de
.cmd8_loop:
    ld hl, .cmd8_data
    ; cmd8 returns R7, which is R1 + 4 bytes of data
    call spi_cs_assert
    call .cmd_r7
    call spi_cs_deassert
if .debug_prints
    push af
    push bc
    call hexdump_a
    call puts_crlf
    pop bc
    pop af
endif
    ret ; return a=1 on success


.acmd41: ; send cmd8, voltage setup
    ld b, 10 ; retries
.acmd41_loop:
    ld hl, .cmd55_data
    call spi_cs_assert
    call .cmd_r1
    call spi_cs_deassert
    call spi_cs_assert
    ld hl, .cmd41_data
    call .cmd_r1
    call spi_cs_deassert
    cp 0
    jr z,.acmd41_done
    djnz .acmd41_loop
    ld a,0xff ; error
.acmd41_done:
    ret


sdcard_read: ; read block
    ; block address to read in bc,de
    ; block data is written to (hl)
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
    ; block address in bc,de
    ; data from (hl) written to sdcard block
    push bc
    call iputs
    db "sdcard_write\r\n\0"
    pop bc

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

if .debug_prints
    push af
    push bc
    call hexdump_a
    call puts_crlf
    pop bc
    pop af
endif

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
    ld bc,512
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
    cp 5 ; (5=00101)
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
    ; destroys bc,de
    ld hl, .cmd58_data
    ; cmd8 returns R3, which is R1 + 4 bytes of data
    call spi_cs_assert
    call .cmd_r7
    call spi_cs_deassert
    ret


sdcard_init: ; does not preserve any registers
    ; slow spi clk
    ld a,6
    call spi_setdiv
    call spi_cs_deassert ; apply spi divider

    call .gen_clks

if .debug_prints
    call iputs
    db "cmd0\r\n\0"
endif

    ; put card into spi mode in idle state
    call .cmd0
    cp 1
    jr nz, .sdcard_init_error

    ; fast spi clk
    ld a,0
    call spi_setdiv

if .debug_prints
    call iputs
    db "cmd8\r\n\0"
endif

    call .cmd8
    ; old cards do not return 1 (idle) here
    ; currently, only new cards are supported
    cp 1
    jr nz, .sdcard_init_error

if .debug_prints
    call iputs
    db "cmd58\r\n\0"
endif

    ; read OCR register
    call .cmd58
    cp 1
    jr nz, .sdcard_init_error

if .debug_prints
    call iputs
    db "acmd41\r\n\0"
endif

    ; initialize card and HCS bit
    ld a,1 ; HCS=1 for newer cards
    call .acmd41
    cp 0
    jr nz, .sdcard_init_error

    ; read OCR again
if .debug_prints
    call iputs
    db "cmd58\r\n\0"
endif
    call .cmd58
    cp 0
    jr nz, .sdcard_init_error
    ret
.sdcard_init_error:
    call iputs
    db "SD-Card init error\r\n\0"
    ret


; for cmd17 (read_block) / cmd24 (write_block)
.cmd_scratch: ds 6

;               40:33 32:24 23:16 15:8   7:0  crc
.cmd0_data:  db 0x40, 0x00, 0x00, 0x00, 0x00, 0x95
.cmd8_data:  db 0x48, 0x00, 0x00, 0x01, 0x00, 0xd5 ; 11:8 VHS (001=3.3V)
.cmd41_data: db 0x69, 0x40, 0x00, 0x00, 0x00, 0x77 ; 0x40: HCS bit set
.cmd55_data: db 0x77, 0x00, 0x00, 0x00, 0x00, 0x65
.cmd58_data: db 0x7a, 0x00, 0x00, 0x00, 0x00, 0xfd
