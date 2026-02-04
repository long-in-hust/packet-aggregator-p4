const int MAX_FLOWS   = 3; // maximum aggregation flows
const int MAX_SEG   = 256; // maximum segments per aggregation flow
const int MAX_AGG_SIZE_BYTE = 512; // maximum aggregation size in bytes

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/*
------ Registers ------
*/

register <bit<6>>(MAX_FLOWS)               register_count;
register<bit<144>>(MAX_FLOWS * MAX_SEG)    register_data;

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

header eth_payload_t {
    // bit<160> ipv4;
    // bit<64> udp;
    // bit<32> coap;
    // bit<16> payload;
    bit<144> data;
}

header aggmeta_t {
    bit<8> aggId;
    bit<8> segCount;
}

/*
------- Define custom enums --------
*/
enum bit<16> EtherType {
  IPV4      = 0x0800,
  ARP       = 0x0806
}

enum bit<8> Ipv4Protocol {
  UDP       = 0x11,
  ICMP      = 0x01,
  L4AGG     = 0x96
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
    aggmeta_t    aggmeta;
    eth_payload_t[MAX_SEG - 1] payload;
}

struct metadata {
    bit<8> aggId;
    bit<16> aggSize_bit;
    bit<8> segOutRemaining;
}