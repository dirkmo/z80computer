; .area _HEADER (ABS)
;.org 0
    ld hl, 0
    ld a, 0
loop:
    ld (hl), a
    inc hl
    inc a
    jp loop
