// this will be implemented in the egress control

action formSegPacket() {
    // debug only
    // stdmeta_logger.write(0, std_meta.instance_type);

    // if (std_meta.instance_type == 1) {
    //     recirculate_preserving_field_list(1);
    // }

    // read the count variable
    bit<10> current_count;
    count_variable.read(current_count, 0);
    if (current_count == 0) {
        // no segments to send, drop packet
        drop();
        return;
    }
    
    // change etherType to ARP to forward to host
    hdr.ethernet.etherType = EtherType.IPV4;

    // make payload valid again and set data
    hdr.payload[0].setValid();
    register_data.read(hdr.payload[0].data, (bit<32>)0);

    // finalising the header
    hdr.aggmeta.setInvalid();

    // pop the buffer count
    current_count = current_count - 1;
    count_variable.write(0, current_count);

    bit<10> current_head;
    head_tail_index.read(current_head, 0); // use head index for reading
    current_head = (current_head + 1) % MAX_SEG_BUF;
    head_tail_index.write(0, current_head); // update head index
}