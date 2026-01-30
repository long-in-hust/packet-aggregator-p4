// L3 Aggregation logic

action save_buffer(bit<8> aggId) {
    // set aggId in metadata
    mta.aggId = aggId;
    // read count
    bit<6> count;
    register_count.read(count, (bit<32>)aggId);
    count = count + 1; // calculate new count in advance to predict if max size will be reached

    // write data  
    if ((bit<11>)count * 64 <= MAX_AGG_SIZE_BYTE && count < 63) {
        // ---- if max size is not reached ----
        // must be count - 1 because the new payload starts from the old count
        bit<32> write_index = (bit<32>)aggId * MAX_SEG + (bit<32>)count - 1;
        register_data.write(write_index, hdr.payload[0].data);
        register_count.write((bit<32>)aggId, (bit<6>)count);
        mta.aggSize_bit = (bit<16>)count * 512;
    }
    else {
        drop();
    }
}

table aggr_buffer {
    actions = {
        save_buffer;
        drop;
    }
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    size = 64;
    default_action = drop();
}
