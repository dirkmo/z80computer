all: cpm22.asm build

cpm22.asm:
	make -C ../cpm22

build: cpm22.asm main.asm bios.asm puts.asm hexdump.asm dph.asm
	z80asm -o sys.bin --list=sys.lst --label=sys.sym main.asm

disk.img:
	mkfs.cpm -f z80-retro-2k-8m $@
	cpmcp -f z80-retro-2k-8m $@ ../cpm22/filesystem/* 0:

clean:
	rm -f sys.bin sys.lst sys.sym
