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
        call    uart_putc
        inc     hl                      ; point to next byte to write
        jp      .puts_loop
.puts_done:
        ret

;##############################################################
; Print a CRLF
; Clobbers AF, C
;##############################################################
puts_crlf:
        call    iputs
        defb    '\r\n\0'
        ret
