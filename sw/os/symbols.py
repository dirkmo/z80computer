#!/usr/bin/env python3
import os
import sys


def createDictFromSymbols(fn):
    f=open(fn)
    lines=f.readlines()
    f.close()
    d = {}
    for l in lines:
        l = l.split("\t")
        l[1] = l[1].split(" ")[1].strip()[1:]
        d[l[1]] = l[0]
    return d

def replace(fn, symbols):
    f=open(fn)
    lines = f.readlines()
    for l in lines:
        if l[0:2] == "OP":
            addr = l[3:].strip()
            if addr in symbols:
                print(symbols[addr])
            #else:
            #    print(l.strip())
        #else:
        #    print(l.strip())



symbols = createDictFromSymbols("sys.sym")
# print(symbols)

replace("out.txt", symbols)
