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
    spi.pins = SPI.PIN_POWER | SPI.PIN_CS | SPI.PIN_PULLUP
    spi.config = SPI.CFG_IDLE
    spi.speed = '125kHz'

def send_clocks():
    spi.cs = False
    spi.transfer(bytes([0xff]*10))

def send_cmd(idx, data, echo=False):
    global spi
    l = len(data)
    if l < 4:
        data = data + [0] * 4-l
    data = [idx|0x40] + data
    crc7 = ((libscrc.crc7(bytes(data)) << 1) & 0xff) | 1
    data = data + [crc7]
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

def cmd55():
    rsp = send_cmd(55, [0,0,0,0])
    return rsp[0] in [0,1]

def acmd41(hcs = 0x40):
    retry = 10
    while retry > 0:
        cmd55()
        rsp = send_cmd(41, [hcs,0,0,0], echo=True)
        if rsp[0] == 0:
            return True
        retry = retry - 1
    return False

setup_buspirate()

cmd0()

if not cmd8():
    print("V1.x SD memory card")
    acmd41(0)
else:
    print("V2.00 or later SD memory card")
    acmd41(0x40)