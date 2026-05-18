#ifndef INGRESS_P4
#define INGRESS_P4

// =================== Định nghĩa hành động chung ===================

// Hành động drop() phải được định nghĩa vì mark_to_drop() là một hàm extern, không thể được gọi từ trong bảng.
// Hành động này là một thủ tục và sẽ được gọi từ trong bảng hoặc trong khối apply(), chứ chưa chạy ngay
action drop() {
    // Đánh dấu std_meta.egress_spec bằng DROP_PORT,
    // gói tin sẽ được chuyển tới cổng này
    // trước khi vào control tiếp theo và bị bỏ đi.
    mark_to_drop(std_meta);
}

// ================== Nhóm hành động và bảng cho thao tác L2 cơ bản ==================
// Phân giải IP thành MAC và trả về ARP một cách thủ công
action mac_resolve(macAddr_t resolved_mac) {
    hdr.arp.op_code = ArpOpCode.REPLY;
    // địa chỉ nguồn của gói ARP REPLY là địa chỉ đích của gói ARP REQUEST,
    // còn địa chỉ đích của ARP REPLY là địa chỉ được phân giải và truyền vào action này
    hdr.arp.dst_mac = hdr.arp.src_mac;
    hdr.arp.src_mac = resolved_mac;
    // Hoán đổi địa chỉ IP nguồn và đích
    // Gói tin ARP REPLY có hai địa chỉ này ngược lại so với gói tin ARP REQUEST
    ip4Addr_t temp_ip = hdr.arp.dst_ip;
    hdr.arp.dst_ip = hdr.arp.src_ip;
    hdr.arp.src_ip = temp_ip;
    // đặt lại địa chỉ MAC trong header Ethernet tương ứng với địa chỉ MAC trong header ARP
    hdr.ethernet.dstAddr = hdr.arp.dst_mac;
    hdr.ethernet.srcAddr = hdr.arp.src_mac;
    // Trả về gói tin Reply qua đúng cổng ingress để về lại host yêu cầu ARP
    std_meta.egress_spec = std_meta.ingress_port;
}

table arp_learning{
    actions = {
        mac_resolve;
        drop;
    }
    key = {
        hdr.arp.dst_ip: exact;
    }
    size = 64;
    default_action = drop();
}

// L2 forwarding logic
action forward(egressSpec_t port) {
    std_meta.egress_spec = port;
}

// Bảng này sẽ đóng vai trò gần giống với bảng địa chỉ MAC trong switch truyền thống,
// gắn địa chỉ MAC đích với cổng ra tương ứng.
// Hiện chưa tích hợp tính năng gắn mục động cho bảng này.
table eth_forward{
    actions = {
        forward;
        drop;
    }
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    size = 64;
    default_action = drop();
}

// ================== Nhóm hành động và bảng cho lưu payload vào register ==================
// Hành động này sẽ được gọi trong aggregating() để đánh dấu batch mới được sử dụng để lưu gói tin,
// đồng thời đánh dấu batch cũ đã sẵn sàng để được ghép vào gói tin hiện tại và gửi đi.

// Tham số dạng "inout" kết hợp khả năng của cả "in" (sao chép giá trị đối số truyền vào)
// và "out" (cho phép truyền giá trị đã thay đổi ra ngoài sau khi thực hiện action).
action reset_batch(inout bit<1> param_actv_q, in bit<8> flow_id) {
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
    active_batch.write(0, param_actv_q);
    // Ghi FlowID vào register current_flow_id tại chỉ số là chỉ số của batch đang hoạt động
    // Batch m đang tổng hợp cho flow id n
    current_flow_id.write((bit<32>)param_actv_q, flow_id);
    // Sau khi reset, đây là gói tin đầu tiên của batch mới, nên cần ghi thời gian vào register
    first_pkt_arrival.write(0, std_meta.ingress_global_timestamp);
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
    // Ghi địa chỉ MAC nguồn của segment vào segment_src_macs tại cùng chỉ số write_index
    segment_src_macs.write(write_index, hdr.ethernet.srcAddr);
    // Tăng số segment đã có trong batch đó lên 1
    current_batch_count.write((bit<32>)param_actv_q, (bit<6>)(param_current_count + 1));
}

// Hành động đầu vào cho luồng tổng hợp gói tin. Hành động này sẽ xét các điều kiện để quyết định việc tiếp tục
// lưu gói tin vào batch hiện tại hay là tạo gói tin tổng hợp mới từ batch đã đầy và chuyển sang batch còn lại để lưu gói tin tiếp theo.
action aggregating(bit<8> flow_id) {
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

    // Lấy thời gian đến của gói đầu tiên trong batch từ register first_pkt_arrival,
    // so sánh với thời gian của gói tin hiện tại
    // Nếu thời gian lớn hơn ngưỡng (tạm đặt là 0.2s hoặc 200000 microsec),
    // ngừng thêm gói tin vào batch hiện tại, đổi batch lưu segment và chuẩn bị tổng hợp cho batch vừa xong
    timestamp_t first_pkt_time;
    first_pkt_arrival.read(first_pkt_time, 0);

    if (hdr.ethernet.dstAddr != last_dest_mac || count == MAX_SEGMENTS_PER_BATCH
        || std_meta.ingress_global_timestamp - first_pkt_time >= MAX_WAIT_TIME) {
        // Nếu địa chỉ MAC đích của gói tin hiện tại khác với địa chỉ MAC đích của gói tin liền trước,
        // hoặc số segment đã có trong batch đang hoạt động đã đạt giới hạn tối đa,
        // hoặc thời gian chờ đã vượt ngưỡng,
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
        reset_batch(active_q, flow_id);
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

// =================== Khối apply() của control sw_ingress ===================
apply {
    if (hdr.ethernet.isValid()) {
        // Nếu gói tin là ARP request, thực hiện chức năng ARP cơ bản để lấy địa chỉ MAC đích khi được yêu cầu.
        // Tuy không phải vấn đề chính trong đồ án, chức năng này quan trọng vì thiết bị gửi cần biết
        // địa chỉ MAC đích để gửi gói tin đi.
        if (hdr.ethernet.etherType == EtherType.ARP && 
            hdr.arp.isValid() && 
            hdr.arp.op_code == ArpOpCode.REQUEST) 
        {
            arp_learning.apply();
        }
        else {
            if (hdr.ethernet.etherType == EtherType.IPV4) {
                tbl_aggregation.apply();
            }
            if (std_meta.egress_spec != DROP_PORT) {
                eth_forward.apply();
            }
        }
    } else {
        drop();
    }
    
}

#endif // INGRESS_P4