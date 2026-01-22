// this will be implemented in the egress control

action formSegPacket() {
    hdr.payload[0].setValid();
}

// L2 forwarding logic
action sendPacket(egressSpec_t port) {
    std_meta.egress_spec = port;
}

action sendSegPacket(egressSpec_t port) {
    formSegPacket();
    std_meta.egress_spec = port;
}

table eth_forward{
    actions = {
        sendSegPacket;
        sendPacket;
        drop;
    }
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    size = 40;
    default_action = drop();
}