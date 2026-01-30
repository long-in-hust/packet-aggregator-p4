#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2

const bit<10> MAX_SEG_BUF   = 512; // maximum aggregation segments in buffer
// const int MAX_FLOWS   = 3; // maximum aggregation flows
const int MAX_SEG   = 256; // maximum segments per aggregation flow
// const int MAX_AGG_SIZE_BYTE = 1024; // maximum aggregation size in bytes

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/*
------ Registers ------
*/

register<bit<512>>((bit<32>)MAX_SEG_BUF)    register_data;
register<bit<10>>(1)               count_variable;
register<bit<10>>(2)               head_tail_index;

register<bit<32>>(1) stdmeta_logger; // debug only

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

header eth_payload_t {
    // bit<160> ipv4;
    // bit<64> udp;
    // bit<32> coap;
    // bit<16> payload;
    bit<512> data;
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
  ARP       = 0x0806,
  L3AGG     = 0x1216
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
    aggmeta_t    aggmeta;
    eth_payload_t[MAX_SEG - 1] payload;
}

struct metadata {
    bit<16> aggSize_bit;
    bit<8> segCountRemaining;
    // bool usedInSplit;
    @field_list(1)
    bool resubmitted;
}