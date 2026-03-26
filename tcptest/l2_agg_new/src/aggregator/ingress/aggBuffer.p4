// Hành động này sẽ được gọi trong aggregating() để đánh dấu batch mới được sử dụng để lưu gói tin,
// đồng thời đánh dấu batch cũ đã sẵn sàng để được ghép vào gói tin hiện tại và gửi đi.

// Tham số dạng "inout" kết hợp khả năng của cả "in" (sao chép giá trị đối số truyền vào)
// và "out" (cho phép truyền giá trị đã thay đổi ra ngoài sau khi thực hiện action).
action reset_batch(inout bit<1> param_actv_q) {
    // Trước khi đặt lại số segment trong của batch đang hoạt động về 0,
    // cần đọc số segment đã có trong batch đó vào mta.aggCount để có thể gán vào header aggmeta khi tạo gói tin tổng hợp.
    // Các phương thức read và write của register đều yêu cầu tham số chỉ số có kiểu bit<32>,
    // nên cần cast param_actv_q sang bit<32>.
    current_batch_count.read(mta.aggCount, (bit<32>)param_actv_q);
    // Đặt lại số segment về 0
    // viết vào thanh ghi current_batch_count tại chỉ số là chỉ số của batch đang hoạt động.
    current_batch_count.write((bit<32>)param_actv_q, 0);
    // Chuyển chỉ số batch đang hoạt động sang batch còn lại
    // Vì biến 1 bit nên có thể XOR với 1 để chuyển đổi giữa 0 và 1
    param_actv_q = param_actv_q ^ 1;
    // Ghi chỉ số mới vào active_batch để cập nhật batch đang hoạt động
    active_batch.write(0, param_actv_q ^ 1);
    // đánh dấu batch cũ đã sẵn sàng để ghép vào gói tin hiện tại và gửi đi
    mta.toggleSendAgg = 1;
}

// Hành động này sẽ được gọi trong aggregating() để lưu dữ liệu payload của segment vào data_queues.
// Tham số param_current_count là số segment đã có trong batch đang hoạt động
// được dùng để tính chỉ số phần tử trong data_queues để ghi dữ liệu, cũng như sẽ được cập nhật tăng lên 1 sau khi ghi.
// Tham số truyền vào với định hướng "in" sao chép giá trị đối số truyền vào,
// nhưng không cho phép thay đổi và truyền sự thay đổi ngược ra ngoài.
// Việc này không cần thiết vì giá trị mới sẽ được ghi vào register.
action aggregateSaveBuffer(in bit<6> param_current_count, in bit<1> param_actv_q) {
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

// Hành động đầu vào cho luồng tổng hợp gói tin. Hành động này sẽ xét các điều kiện để quyết định việc tiếp tục
// lưu gói tin vào batch hiện tại hay là tạo gói tin tổng hợp mới từ batch đã đầy và chuyển sang batch còn lại để lưu gói tin tiếp theo.
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
    
    // Lấy số segment đã có trong batch đang hoạt động từ register current_batch_count
    // chỉ số được lấy theo theo chỉ số batch đang hoạt động
    bit<6> count;
    current_batch_count.read(count, (bit<32>)active_q);

    // Lấy địa chỉ MAC đích của gói tin liền trước để so sánh với địa chỉ MAC đích của gói hiện tại
    // Do phương thức read của register trả về kiểu void, giá trị đọc không được trả về trực tiếp
    // mà được truyền lại ra ngoài qua tham số thứ nhất, nên không thể so sánh trực tiếp.
    // Cần gán vào một biến tạm như last_dest_mac để so sánh.
    macAddr_t last_dest_mac;
    last_dst_addr.read(last_dest_mac, 0);
    
    
    if (hdr.ethernet.dstAddr != last_dest_mac
        || count == MAX_SEGMENTS_PER_BATCH)
    {
        // Nếu địa chỉ MAC đích của gói tin hiện tại khác với địa chỉ MAC đích của gói tin liền trước,
        // hoặc số segment đã có trong batch đang hoạt động đã đạt giới hạn tối đa,
        // tiến hành đánh dấu sẵn sàng tổng hợp và reset batch cũ,
        // chuyển chỉ số batch đang hoạt động sang batch còn lại, và lưu gói tin vào batch mới.

        // cập nhật lại địa chỉ MAC đích gần nhất thành địa chỉ MAC đích của gói tin hiện tại (vì đã sang batch mới)
        // Cập nhật vào thanh ghi để các gói sau có thể đọc được và so sánh với địa chỉ MAC đích của chúng.
        last_dst_addr.write(0, hdr.ethernet.dstAddr);

        // Vì gói tin tổng hợp sẽ mang thông tin địa chỉ MAC đích
        // của các gói tin trong batch cũ (các gói tin tính đến gói liền trước),
        // cần ghi địa chỉ MAC đích của gói tin liền trước cho header Ethernet
        // Điều này có thể thực hiện dược nhờ lưu địa chỉ MAC đích cũ vào biến tạm last_dest_mac.
        // (tương tự việc thực hiện hoán đổi 2 biến thông qua một biến trung gian)
        hdr.ethernet.dstAddr = last_dest_mac;
        // Hành động reset batch cũng sẽ cập nhật lại biến active_q sang batch mới
        reset_batch(active_q);
        // Sau khi reset và chuyển sang batch mới, lưu gói tin hiện tại vào batch mới này
        aggregateSaveBuffer(0, active_q);
        // Chúng ta không drop vì header của gói tin này sẽ được dùng làm khung để dựng gói tin tổng hợp.
    } else {
        // Ngược lại, nếu chưa đạt giới hạn và địa chỉ MAC đích vẫn giống nhau, tiếp tục lưu payload của gói tin vào batch hiện tại.
        aggregateSaveBuffer(count, active_q);
        // Sau khi lưu payload vào register data_queues, vì gói tin không được sử dụng nữa, cần drop để không gửi ra ngoài cũng như tránh chiếm dụng tài nguyên.
        drop();
    }
}

// Địa chỉ sẽ được truyền vào bảng qua API từ control plane.
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