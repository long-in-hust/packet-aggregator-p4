#include <core.p4>
#include <v1model.p4>
#include "dataStructs.p4"

/* 
------- Switch logic --------
*/
parser pkt_parser(packet_in pkt, out headers hdr,
                      inout metadata mta, inout standard_metadata_t std_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            EtherType.ARP:  parse_arp;
            EtherType.IPV4: parse_ipv4;
            default:        accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            Ipv4Protocol.L4AGG: parse_l4agg;
            default: accept;
        }
    }

    state parse_l4agg {
        pkt.extract(hdr.aggmeta);
        mta.segCountRemaining = hdr.aggmeta.segCount;
        transition parse_payloads;
    }

    state parse_payloads {
        pkt.extract(hdr.payload.next);
        mta.segCountRemaining = mta.segCountRemaining - 1;
        transition select(mta.segCountRemaining) {
            0: accept;
            default: parse_payloads;
        }
    }
}

control checksum_verifier(inout headers hdr, inout metadata mta) {
    apply {
        // Will leave it empty for now
    }
}

control sw_ingress(inout headers hdr, inout metadata mta,
                inout standard_metadata_t std_meta) {
    // default drop action
    action drop() {
        mark_to_drop(std_meta);
    }
    
    #include "ingress/splitBuffer.p4"
    #include "ingress/L2Actions.p4"

    apply {
        if (hdr.ethernet.isValid())
        {
            if (hdr.ethernet.etherType == EtherType.ARP && hdr.arp.isValid()) {
                arp_learning.apply();
            }
            else {
                if (hdr.ethernet.etherType == EtherType.IPV4) {
                    if (hdr.ipv4.protocol == Ipv4Protocol.L4AGG && hdr.aggmeta.isValid()) {
                        save_buffer();
                    }
                }
                eth_forward.apply();
            }
        }
        else {
            drop();
        }
    }
}

control sw_egress(inout headers hdr, inout metadata mta,
               inout standard_metadata_t std_meta) {
                // default drop action
    action drop() {
        mark_to_drop(std_meta);
    }

    #include "egress/sendSplitPkt.p4"

    apply {
        if (hdr.ethernet.isValid())
        {
            if (hdr.ethernet.etherType == EtherType.IPV4) {
                if (hdr.ipv4.protocol == Ipv4Protocol.L4AGG && hdr.aggmeta.isValid()) {
                    formSegPacket();
                }
            }
        }
        else {
            drop();
        }
    }
}

control checksum_recalc(inout headers hdr, inout metadata mta) {
    apply {
    }
}

control sw_deparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        // pkt.emit(hdr.aggmeta);
        pkt.emit(hdr.payload[0]);
    }
}

/*
------- Instantiate the switch --------
*/

V1Switch(
    pkt_parser(),
    checksum_verifier(),
    sw_ingress(),
    sw_egress(),
    checksum_recalc(),
    sw_deparser()
) main;