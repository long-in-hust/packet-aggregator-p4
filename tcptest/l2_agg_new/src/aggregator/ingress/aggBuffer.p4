// Tham số dạng "inout" kết hợp khả năng của cả "in" (cho phép thay đổi giá trị trong quá trình thực hiện action)
// và "out" (cho phép truyền giá trị đã thay đổi ra ngoài sau khi thực hiện action).
action reset_batch(inout bit<1> param_actv_q) {
    // đặt lại số phần tử của batch đang hoạt động về 0
    current_batch_count.write((bit<32>)param_actv_q, 0);
    // Chuyển chỉ số batch đang hoạt động sang batch còn lại
    // Vì biến 1 bit nên có thể XOR với 1 để chuyển đổi giữa 0 và 1
    param_actv_q = param_actv_q ^ 1;
    // Ghi chỉ số mới vào active_batch để cập nhật batch đang hoạt động
    active_batch.write(0, param_actv_q ^ 1);
    // đánh dấu batch cũ đã sẵn sàng để ghép vào gói tin hiện tại và gửi đi
    mta.toggleSendAgg = 1;
}

// Tham số truyền vào với định hướng "in" cho phép thay đổi giá trị trong quá trình thực hiện action
action aggregateSaveBuffer(in bit<6> param_current_count, bit<1> param_actv_q) {
    // Tính chỉ số phần tử trong data_queue để ghi dữ liệu theo công thức:
    // chỉ số trong data_queue = chỉ số batch đang hoạt động * số segment tối đa mỗi batch + số segment đã có trong batch đó
    bit<32> write_index = (bit<32>)param_actv_q * MAX_SEGMENTS_PER_BATCH + (bit<32>)param_current_count;
    // Ghi dữ liệu payload vào data_queues tại chỉ số write_index
    data_queues.write(write_index, mta.payload_data);
    // Ghi độ dài thực tế của payload gốc vào payload_lengths tại chỉ số write_index
    payload_lengths.write(write_index, (bit<8>)mta.segLen);
    // Tăng số segment đã có trong batch đó lên 1
    current_batch_count.write((bit<32>)param_actv_q, (bit<6>)(param_current_count + 1));
}

action aggregating() {
    // 40 phần tử byte này đã được sao chép vào mta.payload_data, và sẽ được ghi vào data_queues trong action aggregateSaveBuffer,
    // nên sẽ không còn được sử dụng nữa. Do đó cần khử chúng khỏi header stack để giảm chiếm dụng phần native buffer được BMv2 cấp
    // cho gói tin (độ dài gốc + 512 byte), cũng như tránh dư thừa/sai lệch thông tin khi gửi gói tin đi.
    // Phương thức pop_front với đối số 40 sẽ dịch con trỏ đầu stack lùi về 40 phần tử
    // và đánh dấu 40 phần tử này là inValid (không hợp lệ/không tồn tại).
    hdr.original_payload.pop_front(40);

    // Lấy chỉ số batch đang hoạt động từ register active_batch
    bit<1> active_q;
    active_batch.read(active_q, 0);
    
    bit<6> count;
    current_batch_count.read(count, (bit<32>)active_q);

    // get last destination MAC from register
    macAddr_t last_dest_mac;
    last_dst_addr.read(last_dest_mac, 0);
    
    if (hdr.ethernet.dstAddr != last_dest_mac
        || count == MAX_SEGMENTS_PER_BATCH)
    {
        last_dst_addr.write(0, hdr.ethernet.dstAddr);
        hdr.ethernet.dstAddr = last_dest_mac; // Yeah, this is basically a swap.
        // Why swapping ?
        // It's because this header will be used for the aggregated packet
        // while its payload will be saved into the other queue.
        // Ponzi scheme moment !
        reset_batch(active_q);
        aggregateSaveBuffer(0, active_q);
    } else {
        aggregateSaveBuffer(count, active_q);
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