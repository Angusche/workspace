#!/bin/bash
DES_ADDR=0x48
BUS=1


PHY_LANE_COUNT=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x04 0x4a r1@$DES_ADDR)

echo "PHY_LANE_COUNT (0x44a = $PHY_LANE_COUNT), LANE_COUNT=$(((PHY_LANE_COUNT >> 6) + 1))"

PHY_LANE_MAP=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x33 r1@$DES_ADDR)

echo "PHY_LANE_MAP (0x333 = $PHY_LANE_MAP), 2_lane=0x40, 4_lane=0x4e"



PHY0_FREQ=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x1D r1@$DES_ADDR)
PHY1_FREQ=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x20 r1@$DES_ADDR)
PHY2_FREQ=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x23 r1@$DES_ADDR)
PHY3_FREQ=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x26 r1@$DES_ADDR)

echo "PHY0_FREQ (0x31D = $PHY0_FREQ), $(((PHY0_FREQ & 0x1F)*100))Mbps"
echo "PHY1_FREQ (0x320 = $PHY1_FREQ), $(((PHY1_FREQ & 0x1F)*100))Mbps"
echo "PHY2_FREQ (0x323 = $PHY2_FREQ), $(((PHY2_FREQ & 0x1F)*100))Mbps"
echo "PHY3_FREQ (0x326 = $PHY3_FREQ), $(((PHY3_FREQ & 0x1F)*100))Mbps"




PIPE_X=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x01 0x08 r1@$DES_ADDR)
PIPE_Y=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x01 0x1A r1@$DES_ADDR)
PIPE_Z=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x01 0x2C r1@$DES_ADDR)
PIPE_U=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x01 0x3E r1@$DES_ADDR)


echo "VID_LOCK 6 Video pipeline locked 0b0:Video pipeline not locked, 0b1:Video pipeline locked"
echo "VID_PKT_DET 5 Sufficient video Rx packet throughput detected. 0b0:Not enough throughput, 0b1:Sufficient throughput detected"


echo "PIPE_X (0x108 = $PIPE_X),VID_LOCK=$(((PIPE_X >> 5) & 1)),VID_PKT_DET=$(((PIPE_X >> 6) & 1))"
echo "PIPE_Y (0x11A = $PIPE_Y),VID_LOCK=$(((PIPE_Y >> 5) & 1)),VID_PKT_DET=$(((PIPE_Y >> 6) & 1))"
echo "PIPE_Z (0x12C = $PIPE_Z),VID_LOCK=$(((PIPE_Z >> 5) & 1)),VID_PKT_DET=$(((PIPE_Z >> 6) & 1))"
echo "PIPE_U (0x13E = $PIPE_U),VID_LOCK=$(((PIPE_U >> 5) & 1)),VID_PKT_DET=$(((PIPE_U >> 6) & 1))"




OVERFLOW=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x03 0x12 r1@$DES_ADDR)
echo "OVERFLOW register (0x312 = $OVERFLOW)"
if (( OVERFLOW > 0 )); then
    echo "OVERFLOW detected!"
else
    echo "No overflow!"
fi




# Step 0: Selects the type of received packets to count at PKT_CNT bitfield in register CNT3 (0x25).

VAL=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x00 0x2C r1@$DES_ADDR)
echo "PKT_CNT TYPE (0x2C = $VAL)"
VAL_NEW=$(printf "0x%02X" $(( (VAL & 0xF0) | 0x01 )))
i2ctransfer -y -f $BUS w3@$DES_ADDR 0x00 0x2C $VAL_NEW
echo "PKT_CNT TYPE (0x2C = $VAL_NEW)"

VAL=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x00 0x2C r1@$DES_ADDR)
echo "PKT_CNT TYPE (0x2C = $VAL)"




# Step 1: Write PKT_CNT_THR = 0x0F to register 0x0019
# w3 = 2 addr bytes + 1 data byte
i2ctransfer -y -f $BUS w3@$DES_ADDR 0x00 0x19 0x0F
echo "PKT_CNT_THR set to 0x0F"

# Step 2: Enable PKT_CNT_OEN (bit1) in register 0x001C
# Read-modify-write: read first, then set bit1
VAL=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x00 0x1C r1@$DES_ADDR)
VAL_NEW=$(printf "0x%02X" $(( VAL | 0x02 )))
i2ctransfer -y -f $BUS w3@$DES_ADDR 0x00 0x1C $VAL_NEW
echo "PKT_CNT_OEN enabled (0x1C = $VAL_NEW)"

# Step 3: Clear PKT_CNT_FLAG (write 1 to bit1 of 0x001D)
i2ctransfer -y -f $BUS w3@$DES_ADDR 0x00 0x1D 0x02
echo "PKT_CNT_FLAG cleared"

# Step 4: Poll PKT_CNT (0x0025) and FLAGS (0x001D)
echo ""
echo "Polling PKT_CNT and flags (10 iterations)..."
echo "--------------------------------------------"
for i in $(seq 1 100); do
    PKT_CNT=$(i2ctransfer -y -f $BUS w2@$DES_ADDR 0x00 0x25 r1@$DES_ADDR)
    FLAGS=$(i2ctransfer  -y -f $BUS w2@$DES_ADDR 0x00 0x1D r1@$DES_ADDR)
    FLAG_BIT=$(( (FLAGS >> 1) & 0x1 ))
    echo "[$i] PKT_CNT=$PKT_CNT  FLAGS=$FLAGS  PKT_CNT_FLAG=$FLAG_BIT"
    sleep 0.5
done
