.PHONY: all clean sim wave iverilog asm

UNAME := $(shell uname -s)

VERILATOR_OUTPUTDIR = verilator

INCDIR=-I$(VERILATOR_OUTPUTDIR) -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd

DEFINES=+define+SIM=1

VFLAGS = -O0 --cc -CFLAGS "$(CXXFLAGS)" -LDFLAGS "$(LDFLAGS)" --trace $(INCDIR) --exe --Mdir $(VERILATOR_OUTPUTDIR) $(DEFINES)
GTKWAVE := gtkwave
ifeq ($(UNAME),Darwin)
VFLAGS += --compiler clang
GTKWAVE := /Applications/gtkwave.app/Contents/MacOS/gtkwave-bin
endif

CXXFLAGS=-g -Wall -O0  # -DVL_USER_STOP
LDFLAGS=-lncurses

CPPSRC=sim.cpp #dcpu.c uart.cpp
VERILOGSRC=../rtl/top.v ../rtl/nextz80/NextZ80*.v

all: top

verilator: $(VERILOGSRC) $(CPPSRC)
	verilator $(VFLAGS) $(VERILOGSRC) $(CPPSRC)

top: verilator
	make OPT_FAST="" -C $(VERILATOR_OUTPUTDIR) -j -f Vtop.mk

asm: test.asm
	z80asm -i test.asm -o test.bin
	hexdump -ve '1/1 "%.2x "' test.bin > test.mem

sim: top asm
	$(VERILATOR_OUTPUTDIR)/Vtop test.bin

wave: sim
	gtkwave sim.gtkw &

iverilog:
	iverilog -Wall $(VERILOGSRC)

yosys:
	yosys -Wall -p "synth_ice40 -dsp" $(VERILOGSRC)

clean:
	rm -f trace.vcd a.out
	rm -f $(VERILATOR_OUTPUTDIR)/*
	-rm -r $(VERILATOR_OUTPUTDIR)
	rm -f a.out *.s19 *ihx *.lst *.map *.sym *.rel *.bin *.mem