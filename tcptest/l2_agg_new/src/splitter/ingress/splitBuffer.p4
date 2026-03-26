// L2 Split buffer logic

action save_buffer() {
    // Số segment cần trích xuất từ gói tin tổng hợp
    mta.aggCount = hdr.aggmeta.segCount;
    bit<10> current_count;
    bit<10> current_tail;

    // Đọc số lượng segment hiện có trong register.
    count_variable.read(current_count, 0);
    // Đọc chỉ số đuôi của hàng đợi (không phải native, được dựng lên thông qua register)
    head_tail_index.read(current_tail, 1);

    // save each segment into the register

    RETRIEVE_PAYLOAD

}