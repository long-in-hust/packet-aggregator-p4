#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2

/*
    Số segment tối đa được chứa trong register
    Mặc dù một gói tin tổng hợp chỉ chứa tối đa 11 segment, để chuẩn bị không gian cho trường hợp
    các gói tin tổng hợp được gửi đến nhanh và nhiều hơn so với tốc độ xử lý của thiết bị,
    số phần tử của register data_queue phải lớn hơn nhiều so với mức 11.
*/
const bit<10> MAX_SEGMENT_NUMBER   = 256;

/* 
------- Define custom types --------
*/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<320> data_t;

/*
------ Registers ------
Register là một extern (cấu trúc dữ liệu hoặc method được định nghĩa bởi kiến trúc của target) cho phép lưu trữ trạng thái
xuyến suốt các gói tin. Thông tin lưu trong register không mất đi khi gói tin được xử lý xong. Do đó pipeline của gói tin sau
có thể sử dụng thông tin được ghi vào register trong pipeline của gói tin trước.
*/

// Register được dùng chung để lưu dữ liệu payload của các segment.
// Các segment vào đây để chờ được lấy ra và ghép theo 1 header - 1 payload segment,
// nhằm khôi phục lại gói tin bình thường.
// Không cần chia nhỏ các chỉ số register này theo batch hay flow,
// vì từng segment một sẽ được lấy ra, không theo nhóm nào cả.
register<data_t>((bit<32>)MAX_SEGMENT_NUMBER)    data_queue;

// Register này lưu địa chỉ nguồn của từng segment tương ứng được lưu trong data_queues
// Chỉ số phần tử cũng tương tự register data_queues
register<macAddr_t>((bit<32>)MAX_SEGMENT_NUMBER) segment_src_macs;

// Lưu trữ số lượng segment đã được lưu trong register data_queue.
// Vì chỉ có một register, một không gian lưu trữ chung cho tất cả các segment,
// biến đếm này chỉ cần một phần tử duy nhất.
// Kiểu dữ liệu 10 bit được chọn vì có thể đếm tới 1024, nhiều hơn mức tối đa 256.
register<bit<10>>(1)               count_variable;

// Lưu chỉ số đầu và đuôi để mô phỏng cấu trúc hàng đợi trong register data_queue.
// Register này có 2 phần từ, phần tử ở vị trí 0 lưu chỉ số đầu, phần tử ở vị trí 1 lưu chỉ số đuôi.
// Segment mới thêm vào cuối "hàng đợi" (mô phỏng) chỉ số đuôi tăng lên.
// Segment được lấy ra từ đầu "hàng đợi", chỉ số đầu tăng lên.
// Khi chỉ số chạm tới giới hạn MAX_SEGMENT_NUMBER, nó sẽ quay lại 0, tạo thành một hàng đợi vòng.
register<bit<10>>(2)               head_tail_index;

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

// Đây là cấu trúc payload gói tin tổng hợp đi vào switch
header agg_segment_t {
    macAddr_t src_mac; // Địa chỉ MAC nguồn của segment, sẽ được dùng khi khôi phục lại gói tin gốc.
    
    data_t data;
    // bit<160> ipv4;
    // bit<64> udp;
    // bit<96> payload;
}

// Đây là cấu trúc payload sẽ được gửi ra ngoài sau khi khôi phục
header recovered_payload_t {
    data_t data;
}

header aggmeta_t {
    bit<8> flow_id; // Chỉ số flow tổng hợp, một flow tương ứng với 1 địa chỉ đích.
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
    agg_segment_t[13] segments;
    recovered_payload_t recovered_payload;
}

struct metadata {
    bit<8> segCountRemaining;
    bit<8> aggCount;

    // Đánh dấu trường để giữ lại khi recirculate.
    // Annotation @field_list(1) chỉ hiệu lực với một trường ở hàng liền dưới nó.
    // Nếu có nhiều hơn một trường cần được đưa vào cùng một field list thứ n,
    // cần đánh dấu @field_list(n) cho tất cả các trường đó.
    @field_list(1)
    bool recirculated;
}