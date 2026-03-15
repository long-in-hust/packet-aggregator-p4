action reset_batch(bit<1> param_actv_q) {
    consecutive_match.write(0, 0);
    active_queue.write(0, param_actv_q ^ 1);

    current_batch_count.read(mta.aggCount, (bit<32>)param_actv_q); // get the count of segments in the batch to be sent (now inactive)
    current_batch_count.write((bit<32>)param_actv_q, 0); // reset batch count
    mta.toggleSendAgg = 1; // set metadata to indicate batch is ready to send
}

action aggregateSaveBuffer(bit<1> param_actv_q, bit<6> param_current_count) {
    // write data
    bit<32> write_index = (bit<32>)param_actv_q * MAX_SEG + (bit<32>)param_current_count;
    data_queues.write(write_index, hdr.payload[0].data);

    bit<6> count = param_current_count + 1;
    current_batch_count.write((bit<32>)param_actv_q, (bit<6>)count);
    hdr.payload[0].setInvalid();
}

action aggregating() {
    // get active queue
    bit<1> active_q;
    active_queue.read(active_q, 0);
    
    bit<6> count;
    current_batch_count.read(count, (bit<32>)active_q);

    // get last destination MAC from register
    macAddr_t last_dest_mac;
    last_dst_addr.read(last_dest_mac, 0);
    
    if (hdr.ethernet.dstAddr != last_dest_mac
        || (bit<32>)count * 39 >= MAX_BATCH_SIZE_BYTES || count == MAX_SEG - 1) 
    {
        consecutive_match.write(0, 0);
        last_dst_addr.write(0, hdr.ethernet.dstAddr);
        hdr.ethernet.dstAddr = last_dest_mac; // Yeah, this is basically a swap.
        // Why swapping ?
        // It's because this header will be used for the aggregated packet
        // while its payload will be saved into the other queue.
        // Ponzi scheme moment !
        reset_batch(active_q);
        aggregateSaveBuffer(active_q ^ 1, 0);
    } else {
        consecutive_match.write(0, 1);
        aggregateSaveBuffer(active_q, count);
        drop(); // Why drop if the dst_mac is the same as the last ?
            // Because the header is being unused
            // If the dst_mac is different, it means
            // the header is holding the value of the real last destination MAC due to the swap,
            // which means that header is going to be assembled with the previously aggregated payload.
    }
}

table tbl_aggregation {
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    actions = {
        aggregating;
        NoAction;
    }
    default_action = NoAction();
}