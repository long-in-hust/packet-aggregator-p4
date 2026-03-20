const int MAX_SEG = 32; // maximum number of segments to aggregate (including the first one)
const int MAX_BATCH_SIZE_BYTES = 512; // maximum batch size to trigger aggregation

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<272> data_t; // payload data type
// typedef bit<4096> longData_t; // type for the aggregated payload in the egress pipeline

/*
------ Registers ------
*/

register<bit<6>>(2) current_batch_count;      
register<macAddr_t>(1) last_dst_addr;

register<bit<1>>(1) consecutive_match;
register<bit<1>>(1) active_queue; // 0 or 1 to indicate which queue is currently active for aggregation

register<data_t>(MAX_SEG * 2) data_queues; // queue to store incoming segments for aggregation
register<bit<16>>(MAX_SEG * 2) length_queues; // this register stores the length of each segment in the corresponding position in the data queue

// register<bit<4096>>(1) agg_packet_buffer; // buffer to assemble the aggregated packet

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
    // bit<48> udp_payload;
    data_t data;
}

header aggmeta_t {
    bit<8> segCount;
    bit<16> totalLen;
}

header seg_data_t {
    bit<16> segLen;
    data_t data;
}

// header longPayload_t {
//     longData_t data;
// }

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
    eth_payload_t payload;
    seg_data_t[MAX_SEG - 1] aggSegments;

    // longPayload_t longPayload;
}

struct metadata {
    bool dstMacChanged;
    bit<16> segLen; // length of the current segment
    bit<16> totalPayloadLen;
    
    @field_list(1)
    bool resubmitted;
    @field_list(1)
    bit<6> aggCount;
    @field_list(1)
    bit<1> toggleSendAgg;
}