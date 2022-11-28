
PROJ = top
PIN_DEF = fpga.pcf
DEVICE = hx8k
SOURCES =$(wildcard ../rtl/*.v)
SOURCES+=$(wildcard ../import/uartmaster/rtl/*.v)
SOURCES+=$(wildcard ../import/tv80/rtl/core/*.v)
#SOURCES+=pll.v
SOURCES+=top.v

PROG=../sim/test.asm

# Automatic Variables
# $@ The file name of the target of the rule
# $< The name of the first prerequisite
# $^ The names of all the prerequisites


all: $(PROJ).rpt $(PROJ).bin

rom.inc: rom.mem
	./make-rom.py $^ > $@

rom.mem: $(PROG)
	z80asm -o rom.bin $^
	hexdump -ve '1/1 "%02x "' rom.bin > rom.mem

pll.v:
	icepll -i 100 -o 25 -m -f $@

%.json: rom.inc pll.v %.v
	yosys -p synth_ice40 -o $@ $(SOURCES)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --top top --$(DEVICE) --json $(basename $@).json --pcf $< --asc $@ --package ct256 --freq 25

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	iceprogduino $<

clean:
	rm -f $(PROJ).asc $(PROJ).bin $(PROJ).rpt $(PROJ).json rom.inc rom.mem rom.bin pll.v

.SECONDARY: %.asc %.json
.PHONY: all prog clean
