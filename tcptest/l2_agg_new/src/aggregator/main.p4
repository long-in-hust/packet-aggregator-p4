#include <core.p4>
#include <v1model.p4>

#define CPU_PORT 510
#define DROP_PORT 511

#include "dataStructs.p4"
#include "macros/loop_unroll.p4"

/* 
------- Switch logic --------
*/
parser pkt_parser(packet_in pkt, out headers hdr,
                      inout metadata mta, inout standard_metadata_t std_meta) {
    bit<16> tmpLength;
    bit<16> leftShiftAmount;
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            EtherType.ARP:  parse_arp;
            EtherType.IPV4: pre_parse_l3;
            default:        accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state pre_parse_l3 {
        mta.segLen = pkt.lookahead<bit<32>>()[15:0];
        tmpLength = mta.segLen;
        leftShiftAmount = 40 - (mta.segLen);
        transition select(tmpLength) {
            0: accept;
            default: parse_l3;
        }
    }

    state parse_l3 {
        pkt.extract(hdr.original_payload.next);
        mta.payload_data = mta.payload_data << 8;
        mta.payload_data = mta.payload_data | (data_t)hdr.original_payload.last.chunk;
        tmpLength = tmpLength - 1;
        transition select(tmpLength) {
            0: pre_shift_left;
            default: parse_l3;
        }
    }

    state pre_shift_left {
        transition select(leftShiftAmount) {
            0: accept;
            default: shift_left;
        }
    }

    state shift_left {
        mta.payload_data = mta.payload_data << 8;
        leftShiftAmount = leftShiftAmount - 1;
        transition select(leftShiftAmount) {
            0: accept;
            default: shift_left;
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
                if (hdr.ethernet.etherType == EtherType.IPV4) {
                    hdr.original_payload.pop_front(40);
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
            if (mta.toggleSendAgg == 1) {
                formAggPacket();
            }
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
        pkt.emit(hdr.parsed_payload);
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