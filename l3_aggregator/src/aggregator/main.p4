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
            1: parse_l4; // ICMP
            default: accept;
        }
    }

    state parse_l4 {
        pkt.extract(hdr.payload[0]);
        transition accept;
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
    
    #include "ingress/L2Actions.p4"

    #include "ingress/aggBuffer.p4"

    apply {
        if (hdr.ethernet.isValid()) {
            if (hdr.ethernet.etherType == EtherType.ARP && 
                hdr.arp.isValid() && 
                hdr.arp.op_code == ArpOpCode.REQUEST) 
            {
                arp_learning.apply();
            }
            else {
                if (hdr.ethernet.etherType == EtherType.L3AGG) {
                    NoAction();
                }
                else {
                    aggr_buffer.apply();
                }
                eth_forward.apply();
            }
        } else {
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

    #include "egress/sendAggPkt.p4"

    apply {
        if (hdr.ethernet.isValid()) {
            eth_forward.apply();
        } else {
            drop();
        }
    }
}

control checksum_recalc(inout headers hdr, inout metadata mta) {
    apply {
	    // update_checksum(
	    //     hdr.ipv4.isValid(),
        //     { 
        //         hdr.ipv4.version,
	    //         hdr.ipv4.ihl,
        //         hdr.ipv4.diffserv,
        //         hdr.ipv4.totalLen,
        //         hdr.ipv4.identification,
        //         hdr.ipv4.flags,
        //         hdr.ipv4.fragOffset,
        //         hdr.ipv4.ttl,
        //         hdr.ipv4.protocol,
        //         hdr.ipv4.srcAddr,
        //         hdr.ipv4.dstAddr 
        //     },
        //     hdr.ipv4.hdrChecksum,
        //     HashAlgorithm.csum16);
    }
}

control sw_deparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.aggmeta);
        pkt.emit(hdr.payload);
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