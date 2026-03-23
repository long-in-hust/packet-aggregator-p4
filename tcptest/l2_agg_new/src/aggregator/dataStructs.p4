const int LOG_QUEUE_MAX_ALLOC_ELEMENTS = 32;
const int MAX_BATCH_SIZE_BYTES = 512; // maximum batch size to trigger aggregation

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<320> data_t; // payload data type

/*
------ Registers ------
*/

register<bit<6>>(2) current_batch_count;      
register<macAddr_t>(1) last_dst_addr;

register<bit<1>>(1) active_queue; // 0 or 1 to indicate which queue is currently active for aggregation

register<data_t>(LOG_QUEUE_MAX_ALLOC_ELEMENTS * 2) data_queues; // queue to store incoming segments for aggregation
// divided into two halves for two aggregation batches

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

header bytechunk_payload_t {
    // bit<160> ipv4;
    // bit<64> udp;
    // bit<96> udp_payload;
    bit<8> chunk;
}

header full_payload_t {
    data_t data;
}

header aggmeta_t {
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
    bytechunk_payload_t[40] original_payload;
    full_payload_t[LOG_QUEUE_MAX_ALLOC_ELEMENTS] parsed_payload;
}

struct metadata {
    bit<6> aggCount;
    bit<1> toggleSendAgg;
    bool dstMacChanged;
    bit<16> segLen;
    data_t payload_data;
}