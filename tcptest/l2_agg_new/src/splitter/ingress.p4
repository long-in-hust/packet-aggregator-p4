#ifndef INGRESS_P4
#define INGRESS_P4

// ======================== Hành động cơ bản ========================
// Hành động drop() phải được định nghĩa vì mark_to_drop() là một hàm extern, không thể được gọi từ trong bảng.
// Bảng ARP và bảng forwar sẽ dùng drop như hành động mặc định nếu không khớp với mục nào.
action drop() {
    mark_to_drop(std_meta);
}

// ====================== Nhóm hành động và bảng chuyển tiếp L2 cơ bản =====================
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

// ===================== Nhóm hành động trích segment và lưu vào register ========================
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

// ===================== Khối apply ========================
apply {
    if (hdr.ethernet.isValid())
    {
        if (hdr.ethernet.etherType == EtherType.ARP && hdr.arp.isValid()) {
            // Không áp dụng trích segment cho các gói ARP
            // Áp dụng bảng học ARP để phân giải IPv4 sang MAC và báo về host nguồn.
            arp_learning.apply();
        }
        else {
            if (hdr.ethernet.etherType == EtherType.L3AGG && hdr.aggmeta.isValid()) {
                // Trích các segment từ payload nếu đó là gói tổng hợp hợp lệ
                save_buffer();
            }
            if (mta.recirculated) {
                // Đánh lại instance_type về 0 để
                // xem như gói tin thường và bỏ qua điều kiện nhận diện clone ở lần sau,
                // tránh bị lặp lại clone không cần thiết.
                std_meta.instance_type = 0;
            }
            // Chuyển tiếp Layer 2 như gói tin bình thường nếu header ethernet hợp lệ,
            // và không phải ARP (cần gửi ra đúng cồng đi vào).
            eth_forward.apply();
        }
    }
    else {
        // Bỏ gói tin không có header Ethernet hợp lệ
        drop();
    }
}

#endif // INGRESS_P4