PROJ = top
PIN_DEF = fpga.pcf
DEVICE = hx8k
SOURCES = top.v
SOURCES+=$(wildcard ../rtl/*.v)
SOURCES+=$(wildcard ../import/uartmaster/rtl/*.v)
SOURCES+=$(wildcard ../import/tv80/rtl/core/*.v)
all: $(PROJ).rpt $(PROJ).bin

pll:
	#icepll -i 100 -o 25 -m -f pll.v

%.blif: pll %.v
	yosys -p 'synth_ice40 -top top -blif $@' $(SOURCES)

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^ -P ct256

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
