#!/usr/bin/env python3

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
    for i,d in enumerate(rsp):
        if d != 0xff:
            rsp = rsp[i:]
            break
    if echo:
        sys.stdout.write("- R: ")
        for d in rsp:
            sys.stdout.write(f'{d:02x} ')
        print()
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
    # data write
    ab = [(addr >> 24) & 0xff, (addr >> 16) & 0xff, (addr >> 8) & 0xff, addr & 0xff]
    data = gen_cmd(24, ab)
    if echo:
        sys.stdout.write(f"CMD{data[0]&0x3f} ")
        for d in data:
            sys.stdout.write(f'{d:02x} ')
        print()
    spi.cs = True
    spi.transfer(bytes(data))
    rsp = spi.transfer(bytes([0xff]*2)) # r1 and dummy byte
    print(f"rsp: {rsp}")

    spi.transfer(bytes(blockdata))

    rsp = spi.transfer(bytes([0xff]))
    print(f"rsp: {rsp}")
    if rsp[0] != 0:
        return None
    # busy wait while card is writing
    while spi.transfer(bytes([0xff])) != 0xff:
        pass
    spi.cs = False


def cmd55():
    rsp = send_cmd(55, [0,0,0,0])
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

    datablock = cmd17(0)
    print("Data block:")
    for d in datablock:
        sys.stdout.write(f"{d:02x} ")
    print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
