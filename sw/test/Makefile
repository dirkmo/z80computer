all: rom.inc

SEND=../../import/uartmaster/scripts/send.py

rom.inc: rom.mem
	./make-rom.py $^ > $@

rom.mem: rom.bin
	hexdump -ve '1/1 "%02x "' rom.bin > rom.mem

rom.bin: test.asm uart.asm spi.asm sdcard.asm debug.asm defs.asm puts.asm
	z80asm -o $@ --list=rom.lst --label=rom.sym test.asm

clean:
	rm -f rom.bin rom.mem rom.inc rom.lst rom.sym

prog: rom.mem
	${SEND} ,L0000W
	sed 's/ //g' $^ | xargs ${SEND}
	${SEND} .
