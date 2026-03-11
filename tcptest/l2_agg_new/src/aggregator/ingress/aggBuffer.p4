action reset_batch() {
    consecutive_match.write(0, 0);
    bit<1> actv_q;
    active_queue.read(actv_q, 0);
    active_queue.write(0, actv_q ^ 1); // bit flip to toggle active queue for next batch

    current_batch_count.read(mta.aggCount, 0); // get the count of segments in the batch to be sent (now inactive)
    current_batch_count.write(0, 0); // reset batch count
    mta.toggleSendAgg = 1; // set metadata to indicate batch is ready to send
}

action aggregateSaveBuffer() {
    // get active queue
    bit<1> actv_q;
    active_queue.read(actv_q, 0);

    consecutive_match.write(0, 1);
    bit<6> count;
    current_batch_count.read(count, (bit<32>)actv_q);
    count = count + 1; // calculate new count in advance to predict if max size will be reached

    bit<1> queue_id;
    active_queue.read(queue_id, 0); // read current active queue

    // write data
    bit<32> write_index = (bit<32>)actv_q * MAX_SEG + (bit<32>)count;

    data_queues.write(write_index, hdr.payload[0].data);
    current_batch_count.write(0, (bit<6>)count);
    if ((int)count * 38 >= MAX_BATCH_SIZE_BYTES || count == MAX_SEG) {
        hdr.payload[0].setInvalid();
        reset_batch();
    }
    else {
        macAddr_t last_dest_mac;
        last_dst_addr.read(last_dest_mac, 0);
        if (hdr.ethernet.dstAddr == last_dest_mac) {
            drop(); // Why drop if the dst_mac is the same as the last ?
            // Because the header is being unused
            // If the dst_mac is different, it means
            // the header is holding the value of the real last destination MAC due to the swap,
            // which means that header is going to be assembled with the previously aggregated payload.
        }
    }
}

table aggregating {
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    actions = {
        aggregateSaveBuffer;
        NoAction;
    }
}