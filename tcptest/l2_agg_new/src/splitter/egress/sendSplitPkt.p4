// this will be implemented in the egress control

action formSegPacket() {
    if (std_meta.instance_type == PKT_INSTANCE_TYPE_EGRESS_CLONE) {
        return;
    }
    // pop the buffer count
    bit<10> current_count;
    count_variable.read(current_count, 0);

    if (current_count > 0) {
        // change etherType to ARP to forward to host
        hdr.ethernet.etherType = EtherType.IPV4;

        // finalising the header
        hdr.aggmeta.setInvalid();

        current_count = current_count - 1;
        count_variable.write(0, current_count);

        bit<10> current_head;
        head_tail_index.read(current_head, 0); // use head index for reading

        hdr.payload[0].setValid();
        data_queue.read(hdr.payload[0].data, (bit<32>)current_head);

        // update head index
        current_head = (current_head + 1) % LOG_QUEUE_MAX_ALLOC_ELEMENTS_BUF;
        head_tail_index.write(0, current_head);
        
        clone(CloneType.E2E, 1);
        mta.resubmitted = true;
        recirculate_preserving_field_list(1);
    } else {
        drop();
    }
}