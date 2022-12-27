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
    call iputs
    db "CP/M 2.2 (c) 1979 by Digital Research\r\n\0"
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
    ld bc,0
    jp .bios_settrk


; SETTRK
; Register BC contains the track number for subsequent disk accesses on the
; currently selected drive. The sector number in BC is the same as the number
; returned from the SECTRAN entry point. You can choose to seek the selected
; track at this time or delay the seek until the next read or write actually
; occurs. Register BC can take on values in the range 0-76 corresponding t
; valid track numbers for standard floppy disk drives and 0-65535 for
; nonstandard disk subsystems.
.bios_settrk:
	ld (bios_track),bc

if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_settrk\r\n\0"
    call bios_debug_disk
endif
    ret


; SELDSK
; The disk drive given by register C is selected for further operations, where register C contains 0 for drive A, 1 for drive B, and so on up to 15 for drive P (the standard CP/M distribution version supports four drives). On each disk select, SELDSK must return in HL the base address of a 16-byte area, called the Disk Parameter Header, described in Section 6.10. For standard floppy disk drives, the contents of the header and associated tables do not change; thus, the program segment included in the sample CBIOS performs this operation automatically.
; If there is an attempt to select a nonexistent drive, SELDSK returns HL = 0000H
; as an error indicator. Although SELDSK must return the header address on each
; call, it is advisable to postpone the physical disk select operation until an
; I/O function (seek, read, or write) is actually performed, because disk selects
; often occur without ultimately performing any disk I/O, , and many controllers
; unload the head of the current disk before selecting the new drive. This causes
; an excessive amount of noise and disk wear. The least significant bit of
; register E is zero if this is the first occurrence of the drive select since the
; last cold or warm start.
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

; SETSEC
; Register BC contains the sector number, 1 through 26, for subsequent disk
; accesses on the currently selected drive. The sector number in BC is the same
; as the number returned from the SECTRAN entry point. You can choose to send
; this information to the controller at this point or delay sector selection
; until a read or write operation occurs.
.bios_setsec:
	ld	(bios_sector),bc
if _DEBUG_LEVEL > 2
    call iputs
    db ".bios_setsec\r\n\0"
    call bios_debug_disk
endif
    ret

; SETDMA
; Register BC contains the DMA (Disk Memory Access) address for subsequent read
; or write operations. For example, if B = 00H and C = 80H when SETDMA is called,
; all subsequent read operations read their data into 80H through 0FFH and all
; subsequent write operations get their data from 80H through 0FFH, until the next
; call to SETDMA occurs. The initial DMA address is assumed to be 80H. The
; controller need not actually support Direct Memory Access. If, for example, all
; data transfers are through I/O ports, the CBIOS that is constructed uses the
; 128 byte area starting at the selected DMA address for the memory buffer during
; the subsequent read or write operations.
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

.bios_read__:
    ld a, (bios_disk)
    out (PORT_DISK_CFG), a
    ld a, (bios_track)
    out (PORT_DISK_CFG), a
    ld a, (bios_track+1)
    out (PORT_DISK_CFG), a
    ld a, (bios_sector)
    out (PORT_DISK_CFG), a

    ld hl, (bios_dma_addr)
    ld c, 128
.bios_read_1:
    in a, (PORT_DISK_IO)
    ld (hl), a
    inc hl
    dec c
    jr nz, .bios_read_1
	xor	a			; A = 0 = OK
    ret


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
	; 1:1 translation (no skew factor)
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

uart_flush_tx:
    in a, (PORT_UART_ST)
    xor BIT_UART_ST_TXEMPTY
    and BIT_UART_ST_TXEMPTY
    jr z, uart_flush_tx
    ret

simstop: out (0xff), a

include "../test/sdcard.asm"
include "../test/spi.asm"
