// L2 Aggregation logic

action aggregate() {
    
}

table ip_aggregate{
    actions = {
        aggregate;
        drop;
    }
    key = {
        hdr.ipv4.dstAddr: lpm;
    }
    size = 64;
    default_action = drop();
}

