#include <core.p4>
#include <v1model.p4>

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/* 
------- Define headers --------
*/
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header arp_t {
  bit<16>   h_type;
  bit<16>   p_type;
  bit<8>    h_len;
  bit<8>    p_len;
  bit<16>   op_code;
  macAddr_t src_mac;
  ip4Addr_t src_ip;
  macAddr_t dst_mac;
  ip4Addr_t dst_ip;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

/*
------- Define custom enums --------
*/
enum bit<16> EtherType {
  IPV4      = 0x0800,
  ARP       = 0x0806
}
enum bit<16> ArpOpCode {
  REQUEST  = 1,
  REPLY    = 2
}

/* 
------- Define custom structures --------
*/
struct headers {
    ethernet_t   ethernet;
    arp_t        arp;
    ipv4_t       ipv4;
}
struct metadata {
    /* empty */
}

/* 
------- Switch logic --------
*/
parser pkt_parser(packet_in pkt, out headers hdr,
                      inout metadata mta, inout standard_metadata_t std_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            EtherType.IPV4: parse_ipv4;
            EtherType.ARP:  parse_arp;
            default:        accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_arp {
        pkt.extract(hdr.arp);
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

    // L2 forwarding logic
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
        size = 1024;
        default_action = drop();
    }

    // L2 Aggregation logic
    action aggregate() {
        // Implement aggregation logic here
    }

    apply {
        if (hdr.ethernet.isValid()) {
            if (hdr.ethernet.etherType == EtherType.ARP && hdr.arp.isValid() && hdr.arp.op_code == ArpOpCode.REQUEST) {
                arp_learning.apply();
            }
            else {
                eth_forward.apply();
            }
        } else {
            drop();
        }
    }
}

control sw_egress(inout headers hdr, inout metadata mta,
               inout standard_metadata_t std_meta) {
    apply {
        // Add egress logic here
    }
}

control checksum_recalc(inout headers hdr, inout metadata mta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

control sw_deparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
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