// this will be implemented in the egress control

action formAggPacket() {
    // retrieve aggId from metadata
    bit<8> aggId = mta.aggId;
    // read count
    bit<6> count;
    register_count.read(count, (bit<32>)aggId);
    count = count + 1; // calculate new count in advance to predict if max size can be reached with the next packet

    if ((int)count * 272 > MAX_AGG_SIZE_BYTE * 8) {
        // ---- if max size will be exceeded with the next packet ----
        // construct aggregated payload
        bit<8> i;
        for (i = 0; i < (bit<8>)count - 1; i = i + 1) {
            bit<32> read_index = (bit<32>)aggId * (bit<32>)MAX_SEG + (bit<32>)i;
            bit<272> segment_data;
            register_data.read(segment_data, read_index);
            // hdr.agg_payload.data = (hdr.agg_payload.data << 272) | segment_data;
            hdr.payload[i].data = segment_data;
        }

        // change ethernet type to indicate aggregated packet
        hdr.ethernet.etherType = EtherType.L3AGG;

        // set aggmeta header
        hdr.aggmeta.setValid();
        hdr.aggmeta.aggId = mta.aggId;

        // reset count
        register_count.write((bit<32>)aggId, (bit<6>)0);
        mta.aggSize_bit = (bit<16>)0;
    }
}

// L2 forwarding logic
action sendPacket(egressSpec_t port) {
    std_meta.egress_spec = port;
}

table eth_forward{
    actions = {
        sendAggPacket;
        drop;
    }
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    size = 64;
    default_action = drop();
}