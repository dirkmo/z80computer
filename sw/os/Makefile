all: cpm22.asm build

SEND=../../import/uartmaster/scripts/send.py

build: sys.bin

cpm22.asm:
	make -C ../cpm22

sys.bin: cpm22.asm main.asm bios.asm puts.asm hexdump.asm dph.asm
	z80asm -I../cpm22 -I../test -o $@ --list=sys.lst --label=sys.sym main.asm

sys.mem: sys.bin
	hexdump -ve '1/1 "%02x "' $^ > $@

disk.img:
	mkfs.cpm -f z80-retro-2k-8m $@
	cpmcp -f z80-retro-2k-8m $@ ../cpm22/filesystem/* 0:

clean:
	rm -f sys.bin sys.lst sys.sym sys.mem

prog: sys.mem
	${SEND} ,L0000W
	sed 's/ //g' $^ | xargs ${SEND}
	${SEND} .
