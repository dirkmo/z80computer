; BIOS jump table

BOOT:   JP .bios_boot
WBOOT:  JP .bios_wboot
CONIN:  JP .bios_conin
CONST:  JP .bios_const
CONOUT: JP .bios_conout
LIST:   JP .bios_list
PUNCH:  JP .bios_punch
READER: JP .bios_reader
HOME:   JP .bios_home
SELDSK: JP .bios_seldsk
SETTRK: JP .bios_settrk
SETSEC: JP .bios_setsec
SETDMA: JP .bios_setdma
READ:   JP .bios_read
WRITE:  JP .bios_write
PRSTAT: JP .bios_prstat
SECTRN: JP .bios_sectrn


.go_cpm:
	ld	a,0xc3		; opcode for JP
	ld	(0),a
	ld	hl,WBOOT
	ld	(1),hl		; address 0 now = JP WBOOT

	ld	(5),a		; opcode for JP
	ld	hl,FBASE
	ld	(6),hl		; address 6 now = JP FBASE

	ld	bc,0x80		; this is here because it is in the example CBIOS (AG p.52)
	call	.bios_setdma

	ld	c,0		; The ONLY valid drive WE have is A!
	jp	CBASE

.bios_boot:

    call iputs
    db ".bios_boot\r\n\0"

    ld c,0
    jp .go_cpm

.bios_wboot:

    call iputs
    db ".bios_wboot\r\n\0"
    jp .go_cpm

.bios_const:
    in a, (PORT_UART_ST)
    and BIT_UART_ST_RXEMPTY
    ret z                   ; A = 0 = not ready
    ld a,0xff               ; A = 0xff = ready
    ret

.bios_conin:
    call .bios_const
    jr z, .bios_conin
    in a,(PORT_UART_RX)
    and 0x7f                ; clear parity bit
    ld c,a
    ret

.bios_conout:
    in a, (PORT_UART_ST)
    ; so besser:
    ;and BIT_UART_ST_TXFULL
    ;jr nz, .bios_conout
    ; für debug: fifo nicht ausnutzen
    and BIT_UART_ST_TXEMPTY
    jr z, .bios_conout
    ld a,c
    out (PORT_UART_TX), a
    ret

.bios_list:
    call iputs
    db ".bios_list\r\n\0"
    ret

.bios_punch:
    call iputs
    db ".bios_punch\r\n\0"
    ret

.bios_reader:
    call iputs
    db ".bios_reader\r\n\0"
	ld	a,0x1a
	ret

.bios_home:
    call iputs
    db ".bios_home\r\n\0"
    ld bc,0
    ; fallthrough settrk intended

.bios_settrk:
    call iputs
    db ".bios_settrk\r\n\0"
	;ld (bios_disk_track),bc
    ret

.bios_seldsk:
    call iputs
    db ".bios_seldsk\r\n\0"
	ld a,c
    ret

.bios_setsec:
    call iputs
    db ".bios_setsec\r\n\0"
	;ld	(bios_disk_sector),bc
    ret


.bios_setdma:
    call iputs
    db ".bios_setdma\r\n\0"
	;ld (bios_disk_dma),bc
    ret


.bios_read:
    call iputs
    db ".bios_read\r\n\0"
    ld a,1
    ret

.bios_write:
    call iputs
    db ".bios_write\r\n\0"
    ld a,1
    ret

.bios_prstat:
    call iputs
    db ".bios_prstat\r\n\0"
    ret

.bios_sectrn:
    call iputs
    db ".bios_sectrn\r\n\0"
	; 1:1 translation  (no skew factor)
	ld	h,b
	ld	l,c
	ret
