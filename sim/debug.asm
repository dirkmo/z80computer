debug_putc: ; c: char to send
    ld a,c
    out (PORT_DEBUG), a
    ret

debug_puts: ; hl: string to send, null-terminated
    ; destroys af
    push bc
.debug_puts_loop:
    ld a, (hl)
    cp 0
    jp z, .debug_puts_done
    ld c,a
    call debug_putc
    inc hl
    jr .debug_puts_loop
.debug_puts_done:
    pop bc
    ret

;#############################################################################
; Print the value in A in hex
; Clobbers C
;#############################################################################
hexdump_a:
	push	af
	srl	a
	srl	a
	srl	a
	srl	a
	call	.hexdump_nib
	pop	af
	push	af
	and	0x0f
	call	.hexdump_nib
	pop	af
	ret

.hexdump_nib:
	add	'0'
	cp	'9'+1
	jp	m,.hexdump_num
	add	'A'-'9'-1
.hexdump_num:
	ld	c,a
	jp	debug_putc	   ; tail

crlf:
    ld c,13
    call debug_putc
    ld c,10
    jp debug_putc
