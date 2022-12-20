all: rom.inc

SRCS=test.asm

rom.inc: rom.mem
	./make-rom.py $^ > $@

rom.mem: rom.bin
	hexdump -ve '1/1 "%02x "' rom.bin > rom.mem

rom.bin: $(SRCS)
	z80asm -o $@ --list=rom.lst --label=rom.sym $^

clean:
	rm -f rom.bin rom.mem rom.inc rom.lst rom.sym
