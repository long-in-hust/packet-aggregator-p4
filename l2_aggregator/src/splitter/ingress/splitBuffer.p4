// L2 Split buffer logic

action save_buffer() {
    bit<8> aggId = hdr.aggmeta.aggId;
    bit<8> count = hdr.aggmeta.segCount - 1; // exclude the first payload extracted during parsing
    bit<6> last_count;
    register_count.read(last_count, (bit<32>)aggId);
    bit<32> base_index = (bit<32>)aggId * (MAX_SEG - 1) + (bit<32>)last_count;

    // save each segment into the register
    if (count > 0) {
        register_data.write(base_index + 0, hdr.payload[0].data);
        hdr.payload[0].setInvalid();
    }
    if (count > 1) {
        register_data.write(base_index + 1, hdr.payload[1].data);
        hdr.payload[1].setInvalid();
    }
    if (count > 2) {
        register_data.write(base_index + 2, hdr.payload[2].data);
        hdr.payload[2].setInvalid();
    }
    if (count > 3) {
        register_data.write(base_index + 3, hdr.payload[3].data);
        hdr.payload[3].setInvalid();
    }
    if (count > 4) {
        register_data.write(base_index + 4, hdr.payload[4].data);
        hdr.payload[4].setInvalid();
    }
    if (count > 5) {
        register_data.write(base_index + 5, hdr.payload[5].data);
        hdr.payload[5].setInvalid();
    }
    if (count > 6) {
        register_data.write(base_index + 6, hdr.payload[6].data);
        hdr.payload[6].setInvalid();
    }
    if (count > 7) {
        register_data.write(base_index + 7, hdr.payload[7].data);
        hdr.payload[7].setInvalid();
    }
    if (count > 8) {
        register_data.write(base_index + 8, hdr.payload[8].data);
        hdr.payload[8].setInvalid();
    }
    if (count > 9) {
        register_data.write(base_index + 9, hdr.payload[9].data);
        hdr.payload[9].setInvalid();
    }
    if (count > 10) {
        register_data.write(base_index + 10, hdr.payload[10].data);
        hdr.payload[10].setInvalid();
    }
    if (count > 11) {
        register_data.write(base_index + 11, hdr.payload[11].data);
        hdr.payload[11].setInvalid();
    }
    if (count > 12) {
        register_data.write(base_index + 12, hdr.payload[12].data);
        hdr.payload[12].setInvalid();
    }
    if (count > 13) {
        register_data.write(base_index + 13, hdr.payload[13].data);
        hdr.payload[13].setInvalid();
    }
    if (count > 14) {
        register_data.write(base_index + 14, hdr.payload[14].data);
        hdr.payload[14].setInvalid();
    }
    if (count > 15) {
        register_data.write(base_index + 15, hdr.payload[15].data);
        hdr.payload[15].setInvalid();
    }
    if (count > 16) {
        register_data.write(base_index + 16, hdr.payload[16].data);
        hdr.payload[16].setInvalid();
    }
    if (count > 17) {
        register_data.write(base_index + 17, hdr.payload[17].data);
        hdr.payload[17].setInvalid();
    }
    if (count > 18) {
        register_data.write(base_index + 18, hdr.payload[18].data);
        hdr.payload[18].setInvalid();
    }
    if (count > 19) {
        register_data.write(base_index + 19, hdr.payload[19].data);
        hdr.payload[19].setInvalid();
    }
    if (count > 20) {
        register_data.write(base_index + 20, hdr.payload[20].data);
        hdr.payload[20].setInvalid();
    }
    if (count > 21) {
        register_data.write(base_index + 21, hdr.payload[21].data);
        hdr.payload[21].setInvalid();
    }
    if (count > 22) {
        register_data.write(base_index + 22, hdr.payload[22].data);
        hdr.payload[22].setInvalid();
    }
    if (count > 23) {
        register_data.write(base_index + 23, hdr.payload[23].data);
        hdr.payload[23].setInvalid();
    }
    if (count > 24) {
        register_data.write(base_index + 24, hdr.payload[24].data);
        hdr.payload[24].setInvalid();
    }
    if (count > 25) {
        register_data.write(base_index + 25, hdr.payload[25].data);
        hdr.payload[25].setInvalid();
    }
    if (count > 26) {
        register_data.write(base_index + 26, hdr.payload[26].data);
        hdr.payload[26].setInvalid();
    }
    if (count > 27) {
        register_data.write(base_index + 27, hdr.payload[27].data);
        hdr.payload[27].setInvalid();
    }
    if (count > 28) {
        register_data.write(base_index + 28, hdr.payload[28].data);
        hdr.payload[28].setInvalid();
    }
    if (count > 29) {
        register_data.write(base_index + 29, hdr.payload[29].data);
        hdr.payload[29].setInvalid();
    }
    if (count > 30) {
        register_data.write(base_index + 30, hdr.payload[30].data);
        hdr.payload[30].setInvalid();
    }
    if (count > 31) {
        register_data.write(base_index + 31, hdr.payload[31].data);
        hdr.payload[31].setInvalid();
    }
    if (count > 32) {
        register_data.write(base_index + 32, hdr.payload[32].data);
        hdr.payload[32].setInvalid();
    }
    if (count > 33) {
        register_data.write(base_index + 33, hdr.payload[33].data);
        hdr.payload[33].setInvalid();
    }
    if (count > 34) {
        register_data.write(base_index + 34, hdr.payload[34].data);
        hdr.payload[34].setInvalid();
    }
    hdr.aggmeta.setInvalid();
    hdr.ethernet.etherType = EtherType.IPV4; // change etherType to ARP to forward to host
}

table split_buffer {
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