#!/bin/bash

packet_id=1

while true; do
    pktid_str="$packet_id"
    # if [ "$packet_id" -lt 1000 ]; then
    #     pktid_str="0$pktid_str"
    # fi
    # if [ "$packet_id" -lt 100 ]; then
    #     pktid_str="0$pktid_str"
    # fi
    # if [ "$packet_id" -lt 10 ]; then
    #     pktid_str="0$pktid_str"
    # fi
    echo "Sending packet ID: $pktid_str"
    echo "pktid: $pktid_str" | nc -u -w0 10.0.0.3 5000
    (((packet_id++)%10000))
    sleep_time=$(((1 + RANDOM % 100) / 100))
    sleep $sleep_time
done