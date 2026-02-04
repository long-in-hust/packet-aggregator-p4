#!/bin/bash

packet_id=1

while true; do
    echo "Sending packet ID: $packet_id"
    echo "Packet ID: $packet_id" | nc -u localhost 5000
    ((packet_id++))
    sleep 0.01
done