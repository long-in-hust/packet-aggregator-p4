// L2 Split buffer logic

action save_buffer() {
    bit<8> count = hdr.aggmeta.segCount - 1; // exclude the first payload extracted during parsing
    bit<10> current_count;
    bit<10> current_tail;
    count_variable.read(current_count, 0);
    head_tail_index.read(current_tail, 1); // use head index for writing

    // save each segment into the register
    if (count > 0) {
        register_data.write((bit<32>)current_tail, hdr.payload[0].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[0].setInvalid();
    }
    if (count > 1) {
        register_data.write((bit<32>)current_tail, hdr.payload[1].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[1].setInvalid();
    }
    if (count > 2) {
        register_data.write((bit<32>)current_tail, hdr.payload[2].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[2].setInvalid();
    }
    if (count > 3) {
        register_data.write((bit<32>)current_tail, hdr.payload[3].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[3].setInvalid();
    }
    if (count > 4) {
        register_data.write((bit<32>)current_tail, hdr.payload[4].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[4].setInvalid();
    }
    if (count > 5) {
        register_data.write((bit<32>)current_tail, hdr.payload[5].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[5].setInvalid();
    }
    if (count > 6) {
        register_data.write((bit<32>)current_tail, hdr.payload[6].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[6].setInvalid();
    }
    if (count > 7) {
        register_data.write((bit<32>)current_tail, hdr.payload[7].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[7].setInvalid();
    }
    if (count > 8) {
        register_data.write((bit<32>)current_tail, hdr.payload[8].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[8].setInvalid();
    }
    if (count > 9) {
        register_data.write((bit<32>)current_tail, hdr.payload[9].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[9].setInvalid();
    }
    if (count > 10) {
        register_data.write((bit<32>)current_tail, hdr.payload[10].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[10].setInvalid();
    }
    if (count > 11) {
        register_data.write((bit<32>)current_tail, hdr.payload[11].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[11].setInvalid();
    }
    if (count > 12) {
        register_data.write((bit<32>)current_tail, hdr.payload[12].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[12].setInvalid();
    }
    if (count > 13) {
        register_data.write((bit<32>)current_tail, hdr.payload[13].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[13].setInvalid();
    }
    if (count > 14) {
        register_data.write((bit<32>)current_tail, hdr.payload[14].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[14].setInvalid();
    }
    if (count > 15) {
        register_data.write((bit<32>)current_tail, hdr.payload[15].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[15].setInvalid();
    }
    if (count > 16) {
        register_data.write((bit<32>)current_tail, hdr.payload[16].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[16].setInvalid();
    }
    if (count > 17) {
        register_data.write((bit<32>)current_tail, hdr.payload[17].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[17].setInvalid();
    }
    if (count > 18) {
        register_data.write((bit<32>)current_tail, hdr.payload[18].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[18].setInvalid();
    }
    if (count > 19) {
        register_data.write((bit<32>)current_tail, hdr.payload[19].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[19].setInvalid();
    }
    if (count > 20) {
        register_data.write((bit<32>)current_tail, hdr.payload[20].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[20].setInvalid();
    }
    if (count > 21) {
        register_data.write((bit<32>)current_tail, hdr.payload[21].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[21].setInvalid();
    }
    if (count > 22) {
        register_data.write((bit<32>)current_tail, hdr.payload[22].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[22].setInvalid();
    }
    if (count > 23) {
        register_data.write((bit<32>)current_tail, hdr.payload[23].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[23].setInvalid();
    }
    if (count > 24) {
        register_data.write((bit<32>)current_tail, hdr.payload[24].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[24].setInvalid();
    }
    if (count > 25) {
        register_data.write((bit<32>)current_tail, hdr.payload[25].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[25].setInvalid();
    }
    if (count > 26) {
        register_data.write((bit<32>)current_tail, hdr.payload[26].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[26].setInvalid();
    }
    if (count > 27) {
        register_data.write((bit<32>)current_tail, hdr.payload[27].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[27].setInvalid();
    }
    if (count > 28) {
        register_data.write((bit<32>)current_tail, hdr.payload[28].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[28].setInvalid();
    }
    if (count > 29) {
        register_data.write((bit<32>)current_tail, hdr.payload[29].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[29].setInvalid();
    }
    if (count > 30) {
        register_data.write((bit<32>)current_tail, hdr.payload[30].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[30].setInvalid();
    }
    if (count > 31) {
        register_data.write((bit<32>)current_tail, hdr.payload[31].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[31].setInvalid();
    }
    if (count > 32) {
        register_data.write((bit<32>)current_tail, hdr.payload[32].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[32].setInvalid();
    }
    if (count > 33) {
        register_data.write((bit<32>)current_tail, hdr.payload[33].data);
        current_count = current_count + 1;
        current_tail = (current_tail + 1) % MAX_SEG_BUF;
        hdr.payload[33].setInvalid();
    }
    count_variable.write(0, current_count);
    head_tail_index.write(1, current_tail); // update tail index
    
    // clone the packet for the next loop
    clone(CloneType.I2E, 1);
}

// table split_buffer {
//     actions = {
//         save_buffer;
//         drop;
//     }
//     key = {
//         hdr.ethernet.dstAddr: exact;
//     }
//     size = 64;
//     default_action = drop();
// }