#!/usr/bin/env python3

import sys

rom = []

with open(sys.argv[1], "r") as f:
    lines = f.readlines()
    for l in lines:
        rom = rom + l.strip().split(" ")

for i,r in enumerate(rom):
    print(f"16'h{i:04x}: cpu_di = 8'h{r};")
