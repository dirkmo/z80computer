#!/usr/bin/env python3

# this script demonstrates how to access a SD card with a Bus Pirate.


# According to SD specs version 9.00 August 22, 2022

# CMD     Argument                Resp    Abbreviation        Description
# CMD0    [31:0] stuff bits       R1      GO_IDLE_STATE       Reset Memory Card
# CMD8    [11:8] Supply voltage
#         (VHS)
#         [7:0] check pattern     R7      SEND_IF_COND        Host supply voltage
# CMD17   [31:0] address          R1      READ_SINGLE_BLOCK   Read a block
# CMD18   [31:0] address          R1      READ_MULTIPLE_BLOCK Continuously read blocks until STOP_TRANSMISSION cmd
# CMD24   [31:0] address          R1      WRITE_BLOCK         Write a block
# CMD55   [31:0] stuff bits       R1      APP_CMD             Next command is app specific command
# CMD58   [31:0] stuff bits       R3      READ_OCR            Reads OCR register. CCS bit OCR[30]
# ACMD13  [31:0] stuff bits       R2      SD_STATUS           SD Status (Table 4-44)
# ACMD41  [30] HCS, other bits 0  R1      SD_SEND_OP_COND     Sends host capacity support info and active init process


import sys
import libscrc
from pyBusPirateLite.SPI import SPI

class R1:
    def __init__(self, rsp):
        self.in_idle_state = rsp & 1
        self.erase_reset = rsp & 2
        self.illegal_command = rsp & 4
        self.com_crc_error = rsp & 8
        self.erase_sequence_error = rsp & 16
        self.address_error = rsp & 32
        self.parameter_error = rsp & 64


def setup_buspirate():
    global spi
    spi = SPI()
    #spi.pins = SPI.PIN_POWER | SPI.PIN_CS | SPI.PIN_PULLUP
    spi.pins = SPI.PIN_POWER | SPI.PIN_CS
    spi.config = SPI.CFG_IDLE | SPI.CFG_PUSH_PULL
    spi.speed = '125kHz'


def send_clocks():
    spi.cs = False
    spi.transfer(bytes([0xff]*10))


def gen_cmd(idx, data):
    l = len(data)
    if l < 4:
        data = data + [0] * 4-l
    data = [idx|0x40] + data
    crc7 = ((libscrc.crc7(bytes(data)) << 1) & 0xff) | 1
    data = data + [crc7]
    return data


def send_cmd(idx, data, echo=False):
    global spi
    data = gen_cmd(idx, data)
    if echo:
        sys.stdout.write(f"CMD{idx} ")
        for d in data:
            sys.stdout.write(f'{d:02x} ')
    spi.cs = True
    spi.transfer(bytes(data))
    rsp = spi.transfer(bytes([0xff] * 8))
    spi.cs = False
    if echo:
        sys.stdout.write("- R: ")
        for d in rsp:
            sys.stdout.write(f'{d:02x} ')
        print()

    for i,d in enumerate(rsp):
        if d != 0xff:
            rsp = rsp[i:]
            break
    return rsp


def cmd0():
    # CMD0 switches card to SPI mode
    # after power-up card might need some SPI clocks to get ready
    send_clocks()
    rsp = send_cmd(0, [0,0,0,0], echo=True )
    r1 = R1(rsp[0])
    return r1.in_idle_state


def cmd8(): #p320
    # VHS: 0: not defined, 1: 3.3V
    rsp = send_cmd(8, [0,0,1,0], echo=True)
    # CMD8 returns R7, which is R1 + 4 Bytes.
    # R1 must be 0 or 1
    return rsp[0] in [0,1]


def cmd17(addr, echo=True):
    # data read
    ab = [(addr >> 24) & 0xff, (addr >> 16) & 0xff, (addr >> 8) & 0xff, addr & 0xff]
    data = gen_cmd(17, ab)
    if echo:
        sys.stdout.write(f"CMD{data[0]&0x3f} ")
        for d in data:
            sys.stdout.write(f'{d:02x} ')
        print()
    spi.cs = True
    spi.transfer(bytes(data))
    rsp = 0xff
    while rsp == 0xff:
        rsp = spi.transfer(bytes([0xff]))[0]
    if rsp != 0:
        return None # error
    rsp = 0xff
    while rsp != 0xfe:
        rsp = spi.transfer(bytes([0xff]))[0]
    block = bytes()
    for i in range(512//16):
        block = block + spi.transfer(bytes([0xff] * 16))
    crc = spi.transfer(bytes([0xff, 0xff]))
    spi.cs = False
    sys.stdout.write("CRC: ")
    for c in crc:
        sys.stdout.write(f"{c:02x} ")
    print()
    return block


def cmd24(addr, blockdata, echo=True):
    assert(len(blockdata)==512)
    # data write
    ab = [(addr >> 24) & 0xff, (addr >> 16) & 0xff, (addr >> 8) & 0xff, addr & 0xff]
    data = gen_cmd(24, ab)
    if echo:
        sys.stdout.write(f"CMD{data[0]&0x3f} ")
        for d in data:
            sys.stdout.write(f'{d:02x} ')
    spi.cs = True
    spi.transfer(bytes(data))
    rsp = spi.transfer(bytes([0xff]*3)) # r1 and dummy byte
    if echo:
        sys.stdout.write("R: ")
        for r in rsp:
            sys.stdout.write(f"{r:02x} ")
        print()
    # prefix data with start block token 0xfe (spec 7.3.3.2)
    spi.transfer(bytes([0xfe]))
    # send data
    for i in range(512//16):
        spi.transfer(bytes(blockdata[i*16:(i+1)*16]))
    # receive crc
    crc = spi.transfer(bytes([0xff,0xff])) # always ff when crc disabled (?)
    if echo:
        sys.stdout.write("crc: ")
        for c in crc:
            sys.stdout.write(f"{c:02x} ")
    # receive response token (7.3.3.1): xxx0sss1
    rsp = spi.transfer(bytes([0xff]))
    if rsp[0] & 0x1f != 5:
        return None # data rejected from card
    if echo:
        sys.stdout.write("R: ")
        for r in rsp:
            sys.stdout.write(f"{r:02x} ")
        print()

    # poll busy
    busy = 0
    if echo:
        sys.stdout.write("busy poll: ")
    while busy != 0xff:
        busy = spi.transfer(bytes([0xff]))[0]
        if echo:
            sys.stdout.write(f"{busy:02x} ")
    if echo:
        print()

    spi.cs = False


def cmd55():
    rsp = send_cmd(55, [0,0,0,0], echo=True)
    return rsp[0] in [0,1]


def acmd41(hcs = 0x40):
    # ACMD41 will put card into ready state (from idle state)
    # this might take retries according to spec
    retry = 10
    while retry > 0:
        cmd55()
        rsp = send_cmd(41, [hcs,0,0,0], echo=True)
        if rsp[0] == 0:
            return True
        retry = retry - 1
    return False


def cmd58(expectIdle=0):
    rsp = send_cmd(58, [0,0,0,0], echo=True)
    # CMD58 returns R3, which is R3 + OCR (4 bytes)
    if rsp[0] != expectIdle:
        return None # return None on error
    return (rsp[1] >> 6) & 1 # return CCS bit


def main():
    setup_buspirate()

    cmd0() # reset card

    if not cmd8():
        # old cards do not support CMD8
        print("V1.x SD memory card")
        if cmd58(expectIdle=1) == None: # not mandatory
            print("Card not usable")
            exit(1)
        acmd41(0)
    else:
        print("V2.00 or later SD memory card")
        if cmd58(expectIdle=1) == None: # not mandatory
            print("Card not usable")
            exit(1)
        acmd41(0x40)
        ccs = cmd58(expectIdle=0)
        if ccs == None:
            print("Card not usable")
            exit(1)
        if ccs:
            print(f"SDHC or SDUC card (ccs={ccs})")
        else:
            print(f"Standard SD card (ccs={ccs})")

    # read
    datablock = cmd17(0x10000)
    assert(len(datablock) == 512)
    print("Data block:")
    for d in datablock:
        sys.stdout.write(f"{d:02x} ")
    print()

    block = []
    for b in datablock:
        block.append(int(b))

    block[0] = block[0] + 1
    block[511] = block[511] + 2

    # write
    cmd24(0x10000, block, echo=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
