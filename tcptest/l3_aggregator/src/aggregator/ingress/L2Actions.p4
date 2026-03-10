// ARP Learning action(s) and table
action mac_resolve(macAddr_t dst_mac) {
    hdr.arp.op_code = ArpOpCode.REPLY;
    // swap MAC addresses
    hdr.arp.dst_mac = hdr.arp.src_mac;
    hdr.arp.src_mac = dst_mac;
    // swap IP addresses
    ip4Addr_t temp_ip = hdr.arp.dst_ip;
    hdr.arp.dst_ip = hdr.arp.src_ip;
    hdr.arp.src_ip = temp_ip;
    // set ethernet addresses
    hdr.ethernet.dstAddr = hdr.arp.dst_mac;
    hdr.ethernet.srcAddr = hdr.arp.src_mac;
    // return the packet out from the ingress port (back to the sender)
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

// L3 forwarding logic
action forward(egressSpec_t port) {
    std_meta.egress_spec = port;
}

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