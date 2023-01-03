# z80computer
FPGA Z80 Computer

## Project Goals

Create a functioning computer with the following features:

- FPGA board iCE40HX8K-EVB from Olimex
- Simulation with Verilator
- Z80 CPU
- UART
- VGA output
- PS/2 input
- SD-Card support via SPI
- Maybe some sound
- CP/M 2.2

## Current status

- The system can boot CP/M 2.2 with a rudimentary BIOS on FPGA and simulation
- CP/M filesystem on SD-Card (currently readonly access)
- User communication via UART
- Firmware programming via UART

## How To Setup

### Simulation

For simulation, CMAKE and Verilator is needed. Clone this git repo and then:

```
cd <repo>/sim
mkdir build && cd build
cmake ..
make sim
```

This builds and runs a Verilator simulation with a test program. CP/M simulation is possible, but very slow.

### FPGA
Target board is the [iCE40HX8K-EVB board](https://www.olimex.com/Products/FPGA/iCE40/iCE40HX8K-EVB/open-source-hardware) with [iCE40-IO](https://www.olimex.com/Products/FPGA/iCE40/iCE40-IO/open-source-hardware) for VGA and PS/2 connectivity. UART and a SD-Card breakout board is attached to the iCE40-IO. I use [OLIMEXINO-32U4](https://www.olimex.com/Products/Duino/AVR/OLIMEXINO-32U4/open-source-hardware) for FPGA programming.

#### Flash

Program the flash:
```
cd <repo>/fpga
make prog
```

#### Firmware

Currently, the FPGA design does not contain any bootloader. The Z80 will start to execute whatever is in the SRAM.

To program the SRAM with firmware, the design contains an [UART master](https://github.com/dirkmo/uartmaster) device, which can access the memory bus and reset the Z80.

```
cd <repo>/sw/os
make disk.img # build cp/m disk image
make prog     # program firmware to SRAM
```

Program the SD-Card (assuming /dev/sdX is the SD-Card device):
```
sudo dd if=disk.img of=/dev/sdX
```

Now CP/M 2.2 should boot and find the CP/M disk image on the connected SD-card.
