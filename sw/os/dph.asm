;##########################################################################
; Goal: Define a CP/M-compatible filesystem that can be implemented using
; an SDHC card.  An SDHC card is comprised of a number of 512-byte blocks.
;
; Plan:
; - Put 4 128-byte CP/M sectors into each 512-byte SDHC block.
; - Treat each SDHC block as a CP/M track.
;
; This CP/M filesystem has:
;  128 bytes/sector (CP/M requirement)
;  4 sectors/track (Retro BIOS designer's choice)
;  65536 total sectors (max CP/M limit)
;  65536*128 = 8388608 gross bytes (max CP/M limit)
;  65536/4 = 16384 tracks
;  2048 allocation block size BLS (Retro BIOS designer's choice)
;  8388608/2048 = 4096 gross allocation blocks in our filesystem
;  32 = number of reserved tracks to hold the O/S
;  32*512 = 16384 total reserved track bytes
;  floor(4096-16384/2048) = 4088 total allocation blocks, absent the reserved tracks
;  512 directory entries (Retro BIOS designer's choice)
;  512*32 = 16384 total bytes in the directory
;  ceiling(16384/2048) = 8 allocation blocks for the directory
;
;                  DSM<256   DSM>255
;  BLS  BSH BLM    ------EXM--------
;  1024  3    7       0         x
;  2048  4   15       1         0  <----------------------
;  4096  5   31       3         1
;  8192  6   63       7         3
; 16384  7  127      15         7
;
; ** NOTE: This filesystem design is inefficient because it is unlikely
;          that ALL of the allocation blocks will ultimately get used!
;
;##########################################################################
bios_dph:
	dw	0		; XLT sector translation table (no xlation done)
	dw	0		; scratchpad
	dw	0		; scratchpad
	dw	0		; scratchpad
	dw	.bios_dirbuf	; DIRBUF pointer
	dw	.bios_dpb_a	; DPB pointer
	dw	0		; CSV pointer (optional, not implemented)
	dw	.bios_alv_a	; ALV pointer

.bios_dirbuf:
	ds	128		; scratch directory buffer
.bios_wboot_stack:		; (ab)use the BDOS directory buffer as a stack during WBOOT

.bios_dpb_a:
	dw	4       ; SPT sectors per track
	db	4       ; BSH data allocation shift factor
	db	15      ; BLM data allocation block mask
	db	0       ; EXM extend mask
	dw	4087    ; DSM (max allocation block number)
	dw	511     ; DRM total numbers of directores
	db	0xff    ; AL0
	db	0x00    ; AL1
	dw	0       ; CKS
	dw	32      ; OFF reserved tracks at the beginning of disk

.bios_alv_a:
	ds	(4087/8)+1,0xaa	; scratchpad used by BDOS for disk allocation info
.bios_alv_a_end:
