.PHONY: all clean sim wave iverilog asm

UNAME := $(shell uname -s)

VERILATOR_OUTPUTDIR = verilator

INCDIR=-I$(VERILATOR_OUTPUTDIR) -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd

DEFINES=+define+SIM=1

VFLAGS = --top-module z80computer --language 1364-2005 -no-timing -O0 --cc -CFLAGS "$(CXXFLAGS)" -LDFLAGS "$(LDFLAGS)" --trace $(INCDIR) --exe --Mdir $(VERILATOR_OUTPUTDIR) $(DEFINES)
GTKWAVE := gtkwave
ifeq ($(UNAME),Darwin)
VFLAGS += --compiler clang
GTKWAVE := /Applications/gtkwave.app/Contents/MacOS/gtkwave-bin
endif

CXXFLAGS=-g -Wall -O0  # -DVL_USER_STOP
LDFLAGS=-lncurses

CPPSRC=sim.cpp #dcpu.c uart.cpp

VERILOGSRC=../rtl/z80computer.v
VERILOGSRC+=../import/tv80/rtl/core/*.v
VERILOGSRC+=../import/uartmaster/rtl/*.v

all: z80computer

verilator: $(VERILOGSRC) $(CPPSRC)
	verilator $(VFLAGS) $(VERILOGSRC) $(CPPSRC)

z80computer: verilator
	make OPT_FAST="" -C $(VERILATOR_OUTPUTDIR) -j -f Vz80computer.mk

asm: test.asm
	z80asm -i test.asm -o test.bin
	hexdump -ve '1/1 "%.2x "' test.bin > test.mem

sim: z80computer asm
	$(VERILATOR_OUTPUTDIR)/Vz80computer test.bin

wave: sim
	gtkwave sim.gtkw &

iverilog:
	iverilog -Wall -Wno-timescale $(VERILOGSRC)

yosys:
	yosys -Wall -p "synth_ice40 -dsp" $(VERILOGSRC)

clean:
	rm -f trace.vcd a.out
	rm -f $(VERILATOR_OUTPUTDIR)/*
	-rm -r $(VERILATOR_OUTPUTDIR)
	rm -f a.out *.s19 *ihx *.lst *.map *.sym *.rel *.bin *.mem