// L2 Split buffer logic

action save_buffer() {
    mta.aggCount = hdr.aggmeta.segCount;
    bit<10> current_count;
    bit<10> current_tail;
    count_variable.read(current_count, 0);
    head_tail_index.read(current_tail, 1); // use head index for writing

    // save each segment into the register

    RETRIEVE_PAYLOAD

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