action formAggPacket() {
    bit<1> inactive_q;
    bit<32> index;
    data_t segment_data;
    bit<16> segment_length;

    active_queue.read(inactive_q, 0); // get active queue
    inactive_q = inactive_q ^ 1; // get inactive queue

    if (mta.aggCount > 1) {
        hdr.aggmeta.setValid();
        hdr.aggmeta.segCount = (bit<8>)mta.aggCount; // set segment count in header metadata
        hdr.ethernet.etherType = EtherType.L3AGG; // set EtherType for aggregated packet
    }
    // hdr.longPayload.setValid();
    // hdr.longPayload.data = 0;
    
    APPEND_PAYLOAD

}