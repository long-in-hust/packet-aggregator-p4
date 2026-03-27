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