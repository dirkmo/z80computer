#!/usr/bin/env python3
import serial
import sys
import time

ser = 0
port = "/dev/ttyUSB0"

def connect_serial():
    global ser
    try:
        ser = serial.Serial(port, baudrate=115200)
        # ser.write(b'Hallo')
    except:
        print(f"ERROR: Cannot open port {port}")
        exit(1)

connect_serial()

ba=bytearray(sys.argv[1],encoding='ascii')

data = bytearray([(b | 0x80) for b in ba])

for i,d in enumerate(data):
    ser.write(d.to_bytes(length=1,byteorder='little'))
    if (i%5 == 4):
        time.sleep(0.01)
