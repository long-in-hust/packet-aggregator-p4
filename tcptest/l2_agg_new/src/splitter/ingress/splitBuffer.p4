// L2 Split buffer logic

action save_buffer() {
    // Số segment cần trích xuất từ gói tin tổng hợp
    mta.aggCount = hdr.aggmeta.segCount;
    bit<10> current_count;
    bit<10> current_tail;

    // Đọc số lượng segment hiện có trong register.
    count_variable.read(current_count, 0);
    // Đọc chỉ số đuôi của "hàng đợi" (không phải native, được dựng lên thông qua register)
    head_tail_index.read(current_tail, 1);

    // Lấy MAC đích từ register ra để so sánh với MAC đích trong header ethernet của gói tổng hợp.
    macAddr_t current_flow_dst_mac;
    flow_dst_macs.read(current_flow_dst_mac, (bit<32>)hdr.aggmeta.flow_id);
    if (current_flow_dst_mac == 0 || current_flow_dst_mac == hdr.ethernet.dstAddr) {
        // Nếu chưa có MAC đích nào được lưu cho flow này (current_flow_dst_mac == 0)
        // hoặc nếu đã có và khớp với MAC đích của gói tổng hợp, thì tiếp tục.
        // Gắn MAC đích của gói tổng hợp (và cũng là của flow) vào register flow_dst_macs.
        flow_dst_macs.write((bit<32>)hdr.aggmeta.flow_id, hdr.ethernet.dstAddr);
    }
    else {
        // Ngược lại, nếu MAC đích của flow trong register không khớp với MAC đích và flow_id
        // của gói tổng hợp đi vào, đã có sự không nhất quán về thông tin flow.
        // Cần loại bỏ gói này để tránh gây sai lệch thông tin flow cho các gói tổng hợp tiếp theo.
        // Nếu cần reset lại bảng flow, có thể truyền giá trị 0 vào phần tử trong register từ control plane.
        drop();
        return;
    }

    // save each segment into the register
    RETRIEVE_PAYLOAD

}