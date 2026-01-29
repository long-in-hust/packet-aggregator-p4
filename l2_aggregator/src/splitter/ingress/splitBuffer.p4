// L2 Split buffer logic

action save_buffer() {
    bit<8> count = hdr.aggmeta.segCount;
    bit<10> current_count;
    bit<10> current_tail;
    count_variable.read(current_count, 0);
    head_tail_index.read(current_tail, 1); // use head index for writing

    // save each segment into the register
    if (count > 0) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[0].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail); // update tail index
        }
        hdr.payload[0].setInvalid();
    }
    if (count > 1) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[1].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail); // same for every count increment
        }
        hdr.payload[1].setInvalid();
    }
    if (count > 2) {
        if (std_meta.instance_type == 0) { 
            register_data.write((bit<32>)current_tail, hdr.payload[2].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[2].setInvalid();
    }
    if (count > 3) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[3].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[3].setInvalid();
    }
    if (count > 4) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[4].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[4].setInvalid();
    }
    if (count > 5) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[5].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[5].setInvalid();
    }
    if (count > 6) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[6].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[6].setInvalid();
    }
    if (count > 7) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[7].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[7].setInvalid();
    }
    if (count > 8) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[8].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[8].setInvalid();
    }
    if (count > 9) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[9].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[9].setInvalid();
    }
    if (count > 10) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[10].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[10].setInvalid();
    }
    if (count > 11) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[11].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[11].setInvalid();
    }
    if (count > 12) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[12].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[12].setInvalid();
    }
    if (count > 13) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[13].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[13].setInvalid();
    }
    if (count > 14) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[14].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[14].setInvalid();
    }
    if (count > 15) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[15].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[15].setInvalid();
    }
    if (count > 16) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[16].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[16].setInvalid();
    }
    if (count > 17) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[17].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[17].setInvalid();
    }
    if (count > 18) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[18].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[18].setInvalid();
    }
    if (count > 19) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[19].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[19].setInvalid();
    }
    if (count > 20) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[20].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[20].setInvalid();
    }
    if (count > 21) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[21].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[21].setInvalid();
    }
    if (count > 22) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[22].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[22].setInvalid();
    }
    if (count > 23) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[23].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[23].setInvalid();
    }
    if (count > 24) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[24].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[24].setInvalid();
    }
    if (count > 25) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[25].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[25].setInvalid();
    }
    if (count > 26) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[26].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[26].setInvalid();
    }
    if (count > 27) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[27].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[27].setInvalid();
    }
    if (count > 28) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[28].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[28].setInvalid();
    }
    if (count > 29) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[29].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[29].setInvalid();
    }
    if (count > 30) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[30].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[30].setInvalid();
    }
    if (count > 31) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[31].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[31].setInvalid();
    }
    if (count > 32) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[32].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[32].setInvalid();
    }
    if (count > 33) {
        if (std_meta.instance_type == 0) {
            register_data.write((bit<32>)current_tail, hdr.payload[33].data);
            current_count = current_count + 1;
            count_variable.write(0, current_count);
            current_tail = (current_tail + 1) % MAX_SEG_BUF;
            head_tail_index.write(1, current_tail);
        }
        hdr.payload[33].setInvalid();
    }
    
    // // clone the packet for the next loop
    // debug only
    // stdmeta_logger.write(0, std_meta.instance_type);

    // if (std_meta.instance_type == 1) {
    //     std_meta.instance_type = 0;
    // }

    // debug only
    stdmeta_logger.write(0, std_meta.instance_type);

    if (current_count > 0) {
        mta.resubmitted = true;
        resubmit_preserving_field_list(1);
        clone(CloneType.I2E, 1);
    }
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