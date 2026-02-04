#!/bin/bash

packet_id=1

while true; do
    echo "Sending packet ID: $packet_id"
    echo "pktid: $packet_id" | nc -u -w0 10.0.0.3 5000
    ((packet_id++))
    sleep 0.01
done