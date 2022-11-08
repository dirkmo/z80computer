_DEBUG_LEVEL: equ 0

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

bios_disk:      db 0
bios_track:     dw 0
bios_sector:    dw 0
bios_dma_addr:  dw 0


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
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_boot\r\n\0"
endif
    ld c,0
    jp .go_cpm

.bios_wboot:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_wboot\r\n\0"
endif
    jp .go_cpm

.bios_const:
    in a, (PORT_UART_ST)
    xor BIT_UART_ST_RXEMPTY
    and BIT_UART_ST_RXEMPTY
    ret z                  ; A = 0 = not ready
    ld a,0xff              ; A = 0xff = ready
    ret

.bios_conin:
    call .bios_const
    jr z, .bios_conin
    ; jp simstop

    in a,(PORT_UART_RX)
    and 0x7f                ; clear parity bit
    ret

.bios_conout:
    in a, (PORT_UART_ST)
if 1
    and BIT_UART_ST_TXFULL
    jr nz, .bios_conout
else
    ; für debug: fifo nicht ausnutzen
    and BIT_UART_ST_TXEMPTY
    jr z, .bios_conout
endif
    ld a,c
    out (PORT_UART_TX), a
    ret

.bios_list:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_list\r\n\0"
endif
    ret

.bios_punch:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_punch\r\n\0"
endif
    ret

.bios_reader:
	ld	a,0x1a
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_reader\r\n\0"
endif
	ret

.bios_home:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_home\r\n\0"
endif
    ; fallthrough settrk intended
    ld bc,0

.bios_settrk:
	ld (bios_track),bc

if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_settrk\r\n\0"
    call bios_debug_disk
endif
    ret

.bios_seldsk:
	ld a,c
	ld	(bios_disk),a
    ld hl,bios_dph

if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_seldsk\r\n\0"
    call bios_debug_disk
endif
    ret

.bios_setsec:
	ld	(bios_sector),bc
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_setsec\r\n\0"
    call bios_debug_disk
endif
    ret

.bios_setdma:
	ld (bios_dma_addr),bc
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_setdma\r\n\0"
    call bios_debug_disk
endif
    ret

; READ
; Assuming the drive has been selected, the track has been set, and the DMA
; address has been specified, the READ subroutine attempts to read one sector
; based upon these parameters and returns the following error codes in
; register A:
; 0 - no errors occurred
; 1 - nonrecoverable error condition occurred
; Currently, CP/M responds only to a zero or nonzero value as the return code.
; That is, if the value in register A is 0, CP/M assumes that the disk
; operation was completed properly. If an error occurs the CBIOS should attempt
; at least 10 retries to see if the error is recoverable. When an error is
; reported the BDOS prints the message BDOS ERR ON x: BAD SECTOR. The operator
; then has the option of pressing a carriage return to ignore the error, or
; CTRL-C to abort.

.bios_read:
	; fake a 'blank'/formatted sector
	ld	hl,(bios_dma_addr)	; HL = buffer address
	ld	de,(bios_dma_addr)
	inc	de			; DE = buffer address + 1
	ld	bc,0x007f		; BC = 127
	ld	(hl),0xe5
	ldir				; set 128 bytes from (hl) to 0xe5
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_read\r\n\0"
endif
	xor	a			; A = 0 = OK
    ret

; Data is written from the currently selected DMA address to the currently
; selected drive, track, and sector. For floppy disks, the data should be marked
; as nondeleted data to maintain compatibility with other CP/M systems. The
; error codes are returned in register A
; 0 - no errors occurred
; 1 - nonrecoverable error condition occurred

.bios_write:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_write\r\n\0"
endif
    ld a,1
    ret

.bios_prstat:
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_prstat\r\n\0"
endif
    ret

.bios_sectrn:
	; 1:1 translation  (no skew factor)
	ld	h,b
	ld	l,c
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_sectrn\r\n\0"
endif
	ret

bios_debug_disk:
	call	iputs
	db	'disk=0x\0'

	ld	a,(bios_disk)
	call	hexdump_a

	call    iputs
	db	", track=0x\0"
	ld	a,(bios_track+1)
	call	hexdump_a
	ld	a,(bios_track)
	call	hexdump_a

	call	iputs
	db	", sector=0x\0"
	ld	a,(bios_sector+1)
	call	hexdump_a
	ld	a,(bios_sector)
	call	hexdump_a

	call	iputs
	db	", dma=0x\0"
	ld	a,(bios_dma_addr+1)
	call	hexdump_a
	ld	a,(bios_dma_addr)
	call	hexdump_a
	call	puts_crlf

	ret

simstop: out (0xff), a