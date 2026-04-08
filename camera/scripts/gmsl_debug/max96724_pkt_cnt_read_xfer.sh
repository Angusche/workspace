#!/bin/bash
# max96724_pkt_cnt_read_xfer.sh
#
# Read MAX96724 MIPI packet count/activity registers via i2ctransfer.
# Registers 0x08D0–0x08D3, fields as in your table (CSI2 and PHY pkt_cnt). [file:1]

BUS="${BUS:-1}"
ADDR="${ADDR:-0x27}"
INTERVAL="${INTERVAL:-1}"
CPHY_EN_ARR=(1 1 1 1)

# Read one 8‑bit register using 16‑bit address (MSB first)
read_reg() {
    reg=$1
    hi=$(( (reg >> 8) & 0xFF ))
    lo=$(( reg & 0xFF ))
    # 3 bytes write (addr MSB, LSB) then 1 byte read
    i2ctransfer -y -f "$BUS" w2@"$ADDR" "$hi" "$lo" r1
}

decode_nibbles() {
    reg=$1
    val_hex=$2          # like 0x1a
    val=$((val_hex))

    low=$(( val & 0x0F ))
    high=$(( (val >> 4) & 0x0F ))

    printf "  "
    case $reg in
        0x08D0) echo "CSI2_CTL0 = 0x$(printf '%X' "$low"), CSI2_CTL1 = 0x$(printf '%X' "$high")" ;;
        0x08D1) echo "CSI2_CTL2 = 0x$(printf '%X' "$low"), CSI2_CTL3 = 0x$(printf '%X' "$high")" ;;
        0x08D2) echo "PHY0      = 0x$(printf '%X' "$low"), PHY1      = 0x$(printf '%X' "$high")" ;;
        0x08D3) echo "PHY2      = 0x$(printf '%X' "$low"), PHY3      = 0x$(printf '%X' "$high")" ;;
    esac
}

read_once() {
    for reg in 0x08D0 0x08D1 0x08D2 0x08D3; do
        raw=$(read_reg "$reg") || {
            echo "Failed to read $reg"
            continue
        }
        # i2ctransfer returns like: 0x1a
        echo "$(printf '0x%04X' "$reg") = $raw"
        decode_nibbles "$reg" "$raw"
        echo
    done
}

watch_regs() {
    prev=""
    while true; do
        line=""
        for reg in 0x08D0 0x08D1 0x08D2 0x08D3; do
            raw=$(read_reg "$reg" || echo "0x00")
            line="$line $(printf '0x%04X' "$reg")=$raw"
        done
        ts=$(date '+%F %T')
        echo "[$ts]$line"
        sleep "$INTERVAL"
    done
}


print_init_link() {


#device id
val=$(read_reg 0x000d)
echo "Device ID Register 0x000D = $val (A2: MAX96724 0xA3: MAX96724F 0xA4: MAX96724R)"
echo

#Using which default MIPI Profile
val=$(read_reg 0x06e1)
echo "MIPI Profile Select register 0x06e1 = $val"

#Using which default GMSL Profile
val=$(read_reg 0x06ea)
echo "GMSL Profile Link A/B register 0x06ea = $val"

val=$(read_reg 0x06eb)
echo "GMSL Profile Link C/D register 0x06eb = $val"
echo

val=$(read_reg 0x0006)

bit() {
    echo $(((val >> $1) & 0x1))
}

mode_str() {
    [ "$1" -eq 0 ] && echo "GMSL1" || echo "GMSL2"
}

en_str() {
    [ "$1" -eq 0 ] && echo "Link Disable" || echo "Link Enable"
}

bit7=$(bit 7)
bit6=$(bit 6)
bit5=$(bit 5)
bit4=$(bit 4)
bit3=$(bit 3)
bit2=$(bit 2)
bit1=$(bit 1)
bit0=$(bit 0)

echo "Register 0x0006 = 0x$(printf '%02X' "$val")"
echo "GMSL Link/PHY Enable and Mode Select Register"
echo

echo "Mode Select:"
echo "  Bit 7: PHY D = $bit7 -> $(mode_str "$bit7")"
echo "  Bit 6: PHY C = $bit6 -> $(mode_str "$bit6")"
echo "  Bit 5: PHY B = $bit5 -> $(mode_str "$bit5")"
echo "  Bit 4: PHY A = $bit4 -> $(mode_str "$bit4")"
echo

echo "Link Enable:"
echo "  Bit 3: PHY D = $bit3 -> $(en_str "$bit3")"
echo "  Bit 2: PHY C = $bit2 -> $(en_str "$bit2")"
echo "  Bit 1: PHY B = $bit1 -> $(en_str "$bit1")"
echo "  Bit 0: PHY A = $bit0 -> $(en_str "$bit0")"

echo "-------------------------------------------"

}


print_mipi_phy(){

    PHY_MODE=$(read_reg 0x08a0)
    echo "MIPI PHY Mode Select Register:0x08a0 = $PHY_MODE"

    FORCE_CLK=$(( (PHY_MODE >> 7) & 0x1))
    if ((FORCE_CLK > 0)); then
       echo "force all MIPI clocks running"
    fi

    FORCE_CLK=$(( (PHY_MODE >> 6) & 0x1))
    if ((FORCE_CLK > 0)); then
       echo "force PHY 3 MIPI clocks running"
    fi

    FORCE_CLK=$(( (PHY_MODE >> 8) & 0x1))
    if ((FORCE_CLK > 0)); then
       echo "force PHY 0  MIPI clocks running"
    fi

    MODE=$(( (PHY_MODE >> 4) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY 1x4b + 2x2 Mode"
    fi

    MODE=$(( (PHY_MODE >> 3) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY 1x4a + 2x2 Mode"
    fi

    MODE=$(( (PHY_MODE >> 2) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY 2x4 Mode"
    fi

    MODE=$(( (PHY_MODE >> 0) & 0x1))
    if ((MODE > 0)); then
       echo "4x2 Mode"
    fi
    echo ""


    PHY_ENABLE=$(read_reg 0x08a2)
    echo "MIPI PHY Enable Register:0x08a2 = $PHY_ENABLE"

    MODE=$(( (PHY_ENABLE >> 4) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY0 Enabled"
    else
       echo "MIPY PHY0 in standby mode"
    fi
    
    MODE=$(( (PHY_ENABLE >> 5) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY1 Enabled"
    else
       echo "MIPY PHY1 in standby mode"
    fi
    MODE=$(( (PHY_ENABLE >> 6) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY2 Enabled"
    else
       echo "MIPY PHY2 in standby mode"
    fi
    MODE=$(( (PHY_ENABLE >> 7) & 0x1))
    if ((MODE > 0)); then
       echo "MIPI PHY3 Enabled"
    else
       echo "MIPY PHY3 in standby mode"
    fi
    
    echo



    echo "0x08A3 : PHY1(D1+D0)+PHY0(D1+D0)  0x08A4 : PHY3(D1+D0)+PHY2(D1+D0)"
    for reg in 0x08a3 0x08a4; do
        raw=$(read_reg "$reg") || {
            echo "Failed to read $reg"
            continue
        }

        echo "MIPI_PHY_LANE_MAPPING (0x$(printf '%04X' "$reg")) = $raw"
    done
    echo ""

}


check_lock() {
    local reg="$1"
    local name="$2"

    # Read 8‑bit register
    val_hex=$(read_reg "$reg")
    # Convert to integer
    val=$((val_hex))

    # Extract bit 3
    bit3=$(((val >> 3) & 0x1))

    if [ "$bit3" -eq 1 ]; then
        status="LOCKED (GMSL2)"
    else
        status="NOT locked"
    fi

    printf "Link %s: reg %s = 0x%02X, bit3=%d -> %s\n" \
        "$name" "$reg" "$val" "$bit3" "$status"
}

print_check_lock () {
echo "Checking GMSL2 link lock status"
check_lock 0x001A "A"
check_lock 0x000A "B"
check_lock 0x000B "C"
check_lock 0x000C "D"
echo ""
}

print_video_pipe() {

# Helpers ---------------------------------------------------------

link_name() {
    case "$1" in
        0) echo "A" ;;
        1) echo "B" ;;
        2) echo "C" ;;
        3) echo "D" ;;
        *) echo "?" ;;
    esac
}

stream_name() {
    case "$1" in
        0) echo "0 (Pipe X)" ;;
        1) echo "1 (Pipe Y)" ;;
        2) echo "2 (Pipe Z)" ;;
        3) echo "3 (Pipe U)" ;;
        *) echo "?" ;;
    esac
}

# Read registers --------------------------------------------------

val=$(read_reg 0x0006)




F0_HEX=$(read_reg 0x00F0)
F1_HEX=$(read_reg 0x00F1)
F4_HEX=$(read_reg 0x00F4)

F0=$((F0_HEX))
F1=$((F1_HEX))
F4=$((F4_HEX))

echo "Video Pipe Registers"
printf "  0x00F0 = 0x%02X\n" "$F0"
printf "  0x00F1 = 0x%02X\n" "$F1"
printf "  0x00F4 = 0x%02X\n" "$F4"
echo

# Extract enable bits (0–3) and STREAM_SEL_ALL (bit 4)[web:33]
ENA0=$(( (F4 >> 0) & 1 ))
ENA1=$(( (F4 >> 1) & 1 ))
ENA2=$(( (F4 >> 2) & 1 ))
ENA3=$(( (F4 >> 3) & 1 ))
SSA=$(( (F4 >> 4) & 1 ))

echo "Stream Select All: $SSA (1=enabled, 0=disabled)"
echo

# Pipe 0/1 from 0x00F0, Pipe 2/3 from 0x00F1[web:33]

dump_pipe() {
    pipe="$1"
    en="$2"
    regval="$3"
    shiftbits="$4"

    link=$(( (regval >> (shiftbits+2)) & 0x3 ))
    sid=$(( (regval >> shiftbits) & 0x3 ))

    printf "Pipe %d: %s, Link %s, Stream ID %s\n" \
        "$pipe" \
        "$( [ "$en" -eq 1 ] && echo ENABLED || echo disabled )" \
        "$(link_name "$link")" \
        "$(stream_name "$sid")"
}

dump_pipe 0 "$ENA0" "$F0" 0
dump_pipe 1 "$ENA1" "$F0" 4
dump_pipe 2 "$ENA2" "$F1" 0
dump_pipe 3 "$ENA3" "$F1" 4

echo ""
}



print_tx10(){
    index=0
    for reg in 0x090a 0x094a 0x098a 0x09ca; do
        raw=$(read_reg "$reg") || {
            echo "Failed to read $reg"
            continue
        }
        # Convert hex (e.g. 0x3b) to decimal for POSIX [ ] arithmetic
        DEC=$(printf '%d\n' "$raw")

        # CSI2_LANE_CNT is bits[7:6]
	LANE_CNT=$(( ((DEC >> 6) & 0x3) + 1 ))

        # CSI2_CPHY_EN is bit[5]
        CPHY_EN=$(( (DEC >> 5) & 0x1 ))

        CPHY_EN_ARR[$index]=$CPHY_EN
	index=$((index + 1))
        echo "MIPI_TX10 (0x$(printf '%04X' "$reg")) = $raw, CSI2_LANE_CNT = $LANE_CNT data lanes,  CSI2_CPHY_EN  = $CPHY_EN"
    done
    echo "${CPHY_EN_ARR[@]}"
}


print_phy_freq(){
    index=0
    for reg in 0x0415 0x0418 0x041b 0x041e; do
        raw=$(read_reg "$reg") || {
            echo "Failed to read $reg"
            continue
        }
        # Convert hex (e.g. 0x3b) to decimal for POSIX [ ] arithmetic
        DEC=$(printf '%d\n' "$raw")

        # bits[4:0]
	FREQ=$((((DEC) & 0x1F)*100))

	data_rate_info=""
        #CPHY_EN=$(printf '%d\n' "$CPHY_EN")

	if ((CPHY_EN_ARR[$index] > 0)); then
	    #rate= $((FREQ * 2.28))
	    rate=$(echo "$FREQ * 2.28" | bc -l)
	    data_rate_info="CPHY data rate/trio : $rate Mbps/trio"
	else
	    data_rate_info="DPHY data rate/lane : $FREQ Mbps/lane"
	fi
	index=$((index +1))

        echo "BACKTOP (0x$(printf '%04X' "$reg")) = $raw, Freq=$FREQ Mhz DPLL, $data_rate_info"
    done

}



read_basic_info() {


    print_init_link
    ##MIPI PHY Settings Registers
    #
    print_mipi_phy

    print_video_pipe

    print_check_lock
    ## lane count and cphy or dphy	
    print_tx10

    ## print freq
    print_phy_freq
    
    overflow=$(read_reg 0x040a)
    echo "overflow register (0x40a = $overflow)"
    if (( overflow > 0 )); then
        echo "overflow detected!"
    else
        echo "No overflow!"
    fi


}



read_basic_info;

case "$1" in
    once|"")
        read_once
        ;;
    watch)
        watch_regs
        ;;
    *)
        echo "Usage:"
        echo "  BUS=2 ADDR=0x29 ./max96724_pkt_cnt_read_xfer.sh once"
        echo "  BUS=2 ADDR=0x29 INTERVAL=0.5 ./max96724_pkt_cnt_read_xfer.sh watch"
        exit 1
        ;;
esac
