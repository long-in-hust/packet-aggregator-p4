// this will be implemented in the egress control

action formAggPacket() {
    // retrieve aggId from metadata
    bit<8> aggId = mta.aggId;
    // read count
    bit<6> count;
    register_count.read(count, (bit<32>)aggId);
    bit<11> size_in_bytes = ((bit<11>)count + 1) * 64;

    if ((bit<11>)size_in_bytes > MAX_AGG_SIZE_BYTE) {
        // ---- if max size will be exceeded with the next packet ----
        // construct aggregated payload - unrolled loop
        bit<32> base_index = (bit<32>)aggId * (bit<32>)MAX_SEG;
        bit<512> segment_data;
        
        // Unroll for max possible count (MAX_AGG_SIZE_BYTE * 8 / 272 = ~30 segments)
        if (count > 0) {
            register_data.read(segment_data, base_index + 0);
            hdr.payload[0].setValid();
            hdr.payload[0].data = segment_data;
        }
        if (count > 1) {
            register_data.read(segment_data, base_index + 1);
            hdr.payload[1].setValid();
            hdr.payload[1].data = segment_data;
        }
        if (count > 2) {
            register_data.read(segment_data, base_index + 2);
            hdr.payload[2].setValid();
            hdr.payload[2].data = segment_data;
        }
        if (count > 3) {
            register_data.read(segment_data, base_index + 3);
            hdr.payload[3].setValid();
            hdr.payload[3].data = segment_data;
        }
        if (count > 4) {
            register_data.read(segment_data, base_index + 4);
            hdr.payload[4].setValid();
            hdr.payload[4].data = segment_data;
        }
        if (count > 5) {
            register_data.read(segment_data, base_index + 5);
            hdr.payload[5].setValid();
            hdr.payload[5].data = segment_data;
        }
        if (count > 6) {
            register_data.read(segment_data, base_index + 6);
            hdr.payload[6].setValid();
            hdr.payload[6].data = segment_data;
        }
        if (count > 7) {
            register_data.read(segment_data, base_index + 7);
            hdr.payload[7].setValid();
            hdr.payload[7].data = segment_data;
        }
        if (count > 8) {
            register_data.read(segment_data, base_index + 8);
            hdr.payload[8].setValid();
            hdr.payload[8].data = segment_data;
        }
        if (count > 9) {
            register_data.read(segment_data, base_index + 9);
            hdr.payload[9].setValid();
            hdr.payload[9].data = segment_data;
        }
        if (count > 10) {
            register_data.read(segment_data, base_index + 10);
            hdr.payload[10].setValid();
            hdr.payload[10].data = segment_data;
        }
        if (count > 11) {
            register_data.read(segment_data, base_index + 11);
            hdr.payload[11].setValid();
            hdr.payload[11].data = segment_data;
        }
        if (count > 12) {
            register_data.read(segment_data, base_index + 12);
            hdr.payload[12].setValid();
            hdr.payload[12].data = segment_data;
        }
        if (count > 13) {
            register_data.read(segment_data, base_index + 13);
            hdr.payload[13].setValid();
            hdr.payload[13].data = segment_data;
        }
        if (count > 14) {
            register_data.read(segment_data, base_index + 14);
            hdr.payload[14].setValid();
            hdr.payload[14].data = segment_data;
        }
        if (count > 15) {
            register_data.read(segment_data, base_index + 15);
            hdr.payload[15].setValid();
            hdr.payload[15].data = segment_data;
        }
        if (count > 16) {
            register_data.read(segment_data, base_index + 16);
            hdr.payload[16].setValid();
            hdr.payload[16].data = segment_data;
        }
        if (count > 17) {
            register_data.read(segment_data, base_index + 17);
            hdr.payload[17].setValid();
            hdr.payload[17].data = segment_data;
        }
        if (count > 18) {
            register_data.read(segment_data, base_index + 18);
            hdr.payload[18].setValid();
            hdr.payload[18].data = segment_data;
        }
        if (count > 19) {
            register_data.read(segment_data, base_index + 19);
            hdr.payload[19].setValid();
            hdr.payload[19].data = segment_data;
        }
        if (count > 20) {
            register_data.read(segment_data, base_index + 20);
            hdr.payload[20].setValid();
            hdr.payload[20].data = segment_data;
        }
        if (count > 21) {
            register_data.read(segment_data, base_index + 21);
            hdr.payload[21].setValid();
            hdr.payload[21].data = segment_data;
        }
        if (count > 22) {
            register_data.read(segment_data, base_index + 22);
            hdr.payload[22].setValid();
            hdr.payload[22].data = segment_data;
        }
        if (count > 23) {
            register_data.read(segment_data, base_index + 23);
            hdr.payload[23].setValid();
            hdr.payload[23].data = segment_data;
        }
        if (count > 24) {
            register_data.read(segment_data, base_index + 24);
            hdr.payload[24].setValid();
            hdr.payload[24].data = segment_data;
        }
        if (count > 25) {
            register_data.read(segment_data, base_index + 25);
            hdr.payload[25].setValid();
            hdr.payload[25].data = segment_data;
        }
        if (count > 26) {
            register_data.read(segment_data, base_index + 26);
            hdr.payload[26].setValid();
            hdr.payload[26].data = segment_data;
        }
        if (count > 27) {
            register_data.read(segment_data, base_index + 27);
            hdr.payload[27].setValid();
            hdr.payload[27].data = segment_data;
        }
        if (count > 28) {
            register_data.read(segment_data, base_index + 28);
            hdr.payload[28].setValid();
            hdr.payload[28].data = segment_data;
        }
        if (count > 29) {
            register_data.read(segment_data, base_index + 29);
            hdr.payload[29].setValid();
            hdr.payload[29].data = segment_data;
        }

        // change protocol of IPv4 to indicate aggregated packet
        hdr.ipv4.protocol = Ipv4Protocol.L3AGG;

        // set aggmeta header
        hdr.aggmeta.setValid();
        hdr.aggmeta.aggId = mta.aggId;
        hdr.aggmeta.segCount = (bit<8>)count;

        // reset count
        register_count.write((bit<32>)aggId, (bit<6>)0);
        mta.aggSize_bit = (bit<16>)0;
    }
    else {
        drop();
    }
}

table eth_forward{
    actions = {
        formAggPacket;
        NoAction;
    }
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    size = 40;
    default_action = NoAction();
}