PORT_UART_ST:           equ 0
PORT_UART_RX:           equ 1
PORT_UART_TX:           equ 1

BIT_UART_ST_RXEMPTY:    equ 1
BIT_UART_ST_RXFULL:     equ 2
BIT_UART_ST_TXEMPTY:    equ 4
BIT_UART_ST_TXFULL:     equ 8

MEM: EQU 60 ; defines upper boundary of BDOS in kB, after that comes the BIOS

BDOS_START: equ (MEM-7)*1024



            org 0
RESET:      jp start


    ds BDOS_START-$,0xff

include '../cpm22/cpm22.asm'

include 'bios.asm'

bios_stack_lo:
            ds 64,0x55
bios_stack:

start:      ld sp, bios_stack

            call iputs
            db "start\r\n\0"

            ld a,0
            ld (IOBYTE),a
            ld (TDRIVE),a

            jp BOOT


;##############################################################
; Write the null-terminated string starting after the call
; instruction invoking this subroutine to the console.
; Clobbers AF, C
;##############################################################
iputs:
        ex      (sp),hl                 ; hl = @ of string to print
	call	.puts_loop
        inc     hl                      ; point past the end of the string
        ex      (sp),hl
        ret

;##############################################################
; Write the null-terminated staring starting at the address in
; HL to the console.
; Clobbers: AF, C
;##############################################################
puts:
	push	hl
	call	.puts_loop
	pop	hl
	ret

.puts_loop:
        ld      a,(hl)                  ; get the next byte to send
        or      a
        jr      z,.puts_done             ; if A is zero, return
        ld      c,a
        call    CONOUT
        inc     hl                      ; point to next byte to write
        jp      .puts_loop
.puts_done:
        ret

if BDOS_START != CBASE
    ERROR BDOS_START and CBASE not identical.
endif
