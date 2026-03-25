action formAggPacket() {
    bit<1> inactive_q;
    bit<32> index;

    active_batch.read(inactive_q, 0); // get active queue
    inactive_q = inactive_q ^ 1; // get inactive queue

    // Chỉ kích hoạt và gắn hdr.aggmeta khi có nhiều hơn 1 segment được tổng hợp
    // vì nếu chỉ có 1 segment thì cũng không khác gì gói tin gốc.
    if (mta.aggCount > 1) {
        hdr.aggmeta.setValid();
        hdr.aggmeta.segCount = (bit<8>)mta.aggCount; // set segment count in header metadata
        hdr.ethernet.etherType = EtherType.L3AGG; // set EtherType for aggregated packet
    }

    APPEND_PAYLOAD

}