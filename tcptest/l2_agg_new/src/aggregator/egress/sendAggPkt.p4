action sendAggPacket() {
    bit<1> inactive_q;
    active_queue.read(inactive_q, 0);
    inactive_q = inactive_q ^ 1; // get inactive queue

    bit<32> index = (bit<32>)inactive_q * MAX_SEG + (bit<32>)mta.aggCount - 1;
    data_t segment_data;
    data_queues.read(segment_data, index);
    hdr.payload.push_front(1); // make space for new payload
    hdr.payload[0].setValid();
    hdr.payload[0].data = segment_data;

    mta.aggCount = mta.aggCount - 1;

    if (mta.aggCount == 0) {
        hdr.ethernet.etherType = EtherType.L3AGG; // set custom EtherType for aggregated packet
        return;
    }
    // if mta.aggCount > 0:
    clone(CloneType.E2E, 1);
    drop();
}