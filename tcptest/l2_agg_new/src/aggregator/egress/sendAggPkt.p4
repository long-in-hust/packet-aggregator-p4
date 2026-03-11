action formAggPacket() {
    bit<1> inactive_q;
    bit<32> index;
    data_t segment_data;

    hdr.aggmeta.setValid();
    hdr.aggmeta.segCount = (bit<8>)mta.aggCount; // set segment count in header metadata

    active_queue.read(inactive_q, 0);
    inactive_q = inactive_q ^ 1; // get inactive queue

    APPEND_PAYLOAD
    
}