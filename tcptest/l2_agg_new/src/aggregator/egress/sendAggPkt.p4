action formAggPacket() {
    bit<1> inactive_q;
    bit<32> index;

    active_batch.read(inactive_q, 0); // lấy chỉ số batch đang hoạt động
    inactive_q = inactive_q ^ 1; // tính chỉ số batch còn lại (không hoạt động)

    // Chỉ kích hoạt và gắn hdr.aggmeta khi có nhiều hơn 1 segment được tổng hợp
    // vì nếu chỉ có 1 segment thì cũng không khác gì gói tin gốc.
    if (mta.aggCount > 1) {
        hdr.aggmeta.setValid();
        hdr.aggmeta.segCount = (bit<8>)mta.aggCount; // gán số segment hiện có
        // gán flow id của batch chuẩn bị được gắn vào gói tổng hợp (đang không thu nhận gói tin)
        // Giá trị được lưu tại aggmeta.flow_id để đánh dấu gói tin tổng hợp này thuộc flow đó
        current_flow_id.read(hdr.aggmeta.flow_id, (bit<32>)inactive_q);
        hdr.ethernet.etherType = EtherType.L3AGG; // đặt EtherType để nhận biết gói tin tổng hợp
        hdr.ethernet.srcAddr = DEVICE_MAC; // giữ nguyên địa chỉ MAC nguồn
    }

    APPEND_PAYLOAD

}