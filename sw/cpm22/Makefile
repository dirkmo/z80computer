# Create the CP/M source code file we need by downloading and extracting it

all: CPM22.Z80 cpm22.asm filesystem

CPM22.Z80: cpm2-asm.zip
	unzip cpm2-asm.zip $@
	touch $@

cpm2-asm.zip:
	wget -nd http://www.cpm.z80.de/download/cpm2-asm.zip

cpm22-b.zip:
	wget -nd http://www.cpm.z80.de/download/cpm22-b.zip

filesystem: cpm22-b.zip
	mkdir -p filesystem
	unzip -d filesystem cpm22-b.zip

clean:
	rm -f CPM22.*
	rm -rf filesystem

cpm22.asm: CPM22.Z80
	expand $^ | sed -e 's/\(^MEM \)/;\1/' -e 's/,M/,(HL)/g' -e 's/^\([[:alpha:]]*:[[:space:]]*JP[[:space:]]*0\)/;\1/' -e 's/^\([[:alpha:]][^: ]*\)\([[:space:]]\)/\1:\2/' > $@
