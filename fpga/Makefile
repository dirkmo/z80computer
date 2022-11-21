PROJ = top
PIN_DEF = fpga.pcf
DEVICE = hx8k
SOURCES =$(wildcard ../rtl/*.v)
SOURCES+=$(wildcard ../import/uartmaster/rtl/*.v)
SOURCES+=$(wildcard ../import/tv80/rtl/core/*.v)
SOURCES+=pll.v top.v

# Automatic Variables
# $@ The file name of the target of the rule
# $< The name of the first prerequisite
# $^ The names of all the prerequisites


all: $(PROJ).rpt $(PROJ).bin

pll.v:
	icepll -i 100 -o 25 -m -f $@

%.json: pll.v %.v
	yosys -p synth_ice40 -o $@ $(SOURCES)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --freq 25 --top top --$(DEVICE) --json $(basename $@).json --pcf $< --asc $@ --package ct256

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	iceprogduino $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprogduino $<

clean:
	rm -f $(PROJ).asc $(PROJ).bin $(PROJ).rpt $(PROJ).json

.PHONY: all prog clean pll
