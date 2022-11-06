all: cpm22.asm build

cpm22.asm:
	make -C ../cpm22

build: cpm22.asm main.asm
	z80asm -o sys.bin --list=sys.lst --label=sys.sym main.asm

clean:
	rm -f sys.bin sys.lst sys.sym
