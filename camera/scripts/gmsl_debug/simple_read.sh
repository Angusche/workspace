#!/bin/bash

BUS="${BUS:-23}"
ADDR="${ADDR:-0x54}"

# Read one 8‑bit register using 16‑bit address (MSB first)
read_reg() {
    reg=$1
    hi=$(( (reg >> 8) & 0xFF ))
    lo=$(( reg & 0xFF ))
    # 3 bytes write (addr MSB, LSB) then 1 byte read
    i2ctransfer -y -f "$BUS" w2@"$ADDR" "$hi" "$lo" r1
}

for reg in 0x078a 0xbf14 0x8aff 0x0153 0x8af0 0x0144 0x8af1 0x8afe; do
    raw=$(read_reg "$reg") || {
       echo "Failed to read $reg"
       continue
    }
    echo "(0x$(printf '%04X' "$reg")) = $raw"
done


