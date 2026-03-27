// Phương thức push_front sẽ dịch con trỏ đầu stack lên trước 1 phần tử, tạo một phần tử mới ở đầu stack,
// và đẩy tất cả phần tử đã có lên sau phần tử mới này.
// Sử dụng phương pháp push_front sẽ không phải quá quan tâm về chỉ số, vì phần tử mới luôn ở đầu stack (chỉ số bằng 0)
// Thứ tự của các segment vẫn giữ nguyên vì lấy từ cuối stack - chỉ số tính theo công thức:
// chỉ số batch không hoạt động * số segment tối đa mỗi batch + số segment đã có trong batch đó - 1 (vì chỉ số bắt đầu từ 0)
#define APPEND_SEGMENT                     \
    if (mta.aggCount > 0) {                           \
        hdr.agg_segments.push_front(1);   \
        hdr.agg_segments[0].setValid();    \
        index = (bit<32>)inactive_q * MAX_SEGMENTS_PER_BATCH + (bit<32>)mta.aggCount - 1;  \
        data_queues.read(hdr.agg_segments[0].data, index);  \
        segment_src_macs.read(hdr.agg_segments[0].src_mac, index);  \
        mta.aggCount = mta.aggCount - 1;   \
    }   \
    else {  \
        return; \
    }

#define APPEND_PAYLOAD \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT