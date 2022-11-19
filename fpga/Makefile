PROJ = top
PIN_DEF = fpga.pcf
DEVICE = hx8k
SOURCES =$(wildcard ../rtl/*.v)
SOURCES+=$(wildcard ../import/uartmaster/rtl/*.v)
SOURCES+=$(wildcard ../import/tv80/rtl/core/*.v)
SOURCES+=top.v

# Automatic Variables
# $@ The file name of the target of the rule
# $< The name of the first prerequisite
# $^ The names of all the prerequisites


all: $(PROJ).rpt $(PROJ).bin

pll:
	#icepll -i 100 -o 25 -m -f pll.v

%.json: pll %.v
	yosys -p synth_ice40 -o $@ $(SOURCES)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --top top --$(DEVICE) --json $(basename $@).json --pcf $< --asc $@ --package ct256

sources:
	echo $(SOURCES)

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
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).bin $(PROJ).rpt

.PHONY: all prog clean pll
