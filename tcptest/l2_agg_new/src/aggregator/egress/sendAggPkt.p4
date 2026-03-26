action formAggPacket() {
    bit<1> inactive_q;
    bit<32> index;

    active_batch.read(inactive_q, 0); // lấy chỉ số batch đang hoạt động
    inactive_q = inactive_q ^ 1; // tính chỉ số batch còn lại (không hoạt động)

    // Chỉ kích hoạt và gắn hdr.aggmeta khi có nhiều hơn 1 segment được tổng hợp
    // vì nếu chỉ có 1 segment thì cũng không khác gì gói tin gốc.
    // Nếu chỉ có 1 segment, thay vì gửi segment, sẽ gửi các byte gốc
    // Việc này nhằm tránh để thừa các byte 0 ở cuối payload, vừa để tối ưu đường truyền,
    // vừa tránh hiện tượng malform UDP packet (gói tin bị lỗi định dạng).
    if (mta.aggCount > 1) {
        // 40 phần tử byte này đã được chuyển thành payload hoàn chỉnh và ghi vào data_queues trong action aggregateSaveBuffer,
        // nên sẽ không còn được sử dụng nữa. Do đó cần khử chúng khỏi header stack để giảm chiếm dụng phần native buffer được BMv2 cấp
        // cho gói tin (độ dài gốc + 512 byte), cũng như tránh dư thừa/sai lệch thông tin khi gửi gói tin đi.
        // Phương thức pop_front với đối số 40 sẽ dịch con trỏ đầu stack lùi về 40 phần tử
        // và đánh dấu 40 phần tử này là inValid (không hợp lệ/không tồn tại).
        hdr.original_payload.pop_front(40);

        hdr.aggmeta.setValid();
        hdr.aggmeta.segCount = (bit<8>)mta.aggCount; // gán số segment hiện có
        hdr.ethernet.etherType = EtherType.L3AGG; // đặt EtherType để nhận biết gói tin tổng hợp

        APPEND_PAYLOAD

    }
}