const int MAX_SEGMENTS_PER_BATCH = 13; // (51 + 512 - 14 - 1) div 41 = 13 (số dư là 15).
// 51 byte là kích thước tối thiểu của mỗi ethernet frame L2 (không tính preamble, SFD và FCS)
// được gửi trong kịch bản thủ nghiệm. Mỗi frame bao gồm:
// 14 byte (Eth header) + 20 byte (IPv4 header) + 8 byte (UDP header) + 9 byte (kích thước tối thiểu của payload) = 51 byte

// Theo thiết kế vốn có của BMv2, phần buffer đc cấp phát cho gói tin đi vào thiết bị có kích thước bằng:
// kích thước Ethernet Frame + 512 bytes => 51 + 512 = 563

// Do có 14 byte cho Ethernet header, 1 byte để lưu số lượng segment, phần payload tổng hợp sẽ có kích thước tối đa:
// 563 - 14 - 1 = 548 bytes.

// Thông tin cho mỗi segment bao gồm:
/// 1 byte độ dài thực tế + 40 byte lưu dữ liệu (nếu dữ liệu nhỏ hơn 40 byte, phần còn lại sẽ được điền bằng các bit 0).

// Do đó, số segment tối đa có thể được tổng hợp trong một batch là:
// 548 div 41 = 13

/* 
------- Định nghĩa một số kiểu dữ liệu hay dùng --------
*/
typedef bit<9>  egressSpec_t; // Định nghĩa kiểu dữ liệu cổng egress của switch P4.
// Sẽ được dùng để gán cho metadata tiêu chuẩn egress_spec.
typedef bit<48> macAddr_t; // Định nghĩa kiểu dữ liệu địa chỉ MAC (48 bit hoặc 6 byte).
typedef bit<32> ip4Addr_t; // Định nghĩa kiểu dữ liệu địa chỉ IPv4 (32 bit hoặc 4 byte).
// Pipeline này không parse IPv4 nhưng sẽ parse ARP (có chứa địa chỉ IPv4)
typedef bit<320> data_t; // Kiểu dữ liệu lưu payload của segment. Kích thước tối đa của dữ liệu này là 40 byte (320 bit).
// Tác giả không dùng varbit vì kiểu dữ liệu này bị hạn chế rất nhiều về khả năng thao tác (sẽ giải thích chi tiết ở dưới).

/*
------ Registers ------
Register là một extern (cấu trúc dữ liệu hoặc method được định nghĩa bởi kiến trúc của target) cho phép lưu trữ trạng thái
xuyến suốt các gói tin. Thông tin lưu trong register không mất đi khi gói tin được xử lý xong. Do đó pipeline của gói tin sau
có thể sử dụng thông tin được ghi vào register trong pipeline của gói tin trước.
*/


/*
Tác giả tổng hợp gói tin theo 2 batch luân phiên. Khi một batch đạt giới hạn và chuẩn bị được tạo thành gói tin tổng hợp,
batch còn lại sẽ được sử dụng để lưu dữ liệu của các gói tin tiếp theo.
Điều này giúp tránh tình huống gói tin mới đi vào khi batch chưa được tổng hợp xong thành gói tin tổng hợp.
*/

// số lượng segment đã được lưu trong mỗi batch (hiện tại tối đa là 13)
// Register này có 2 phần tử, mỗi phần tử có độ dài 6 bit (chứa 64 giá trị, dư thừa so với 13, sẽ cân nhắc điều chỉnh sau)
register<bit<6>>(2) current_batch_count;      

// Lưu chỉ số batch đang được sử dụng. Do chỉ có 2 batch nên 1 bit là đủ.
register<bit<1>>(1) active_batch;

// Register được dùng chung để lưu dữ liệu payload của các segment cho cả 2 batch. Số phần tử của register bằng:
// số segment tối đa cho mỗi batch * số batch (13 * 2 = 26).
// Chỉ số phần tử đầu tiên trong số các phần tử dành cho batch thứ n là n * MAX_SEGMENTS_PER_BATCH (n = 0 hoặc 1).
register<data_t>(MAX_SEGMENTS_PER_BATCH * 2) data_queues;

// Lưu địa chỉ MAC đích của gói tin được xử lý liền trước, sẽ được dùng để kiểm tra xem
// Có tiếp tục tổng hợp hay không.
// Do chỉ cần lưu giá trị của gói tin liền trước, 1 phần tử là đủ.
register<macAddr_t>(1) last_dst_addr;

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

// P4 không cho tác động trực tiếp vào payload nếu không parse vào kiểu cấu trúc header nào đó.
// Vì vậy, cần parse payload như một header nếu muốn tác động (ghép payload).

header bytechunk_payload_t {
    // Đc sử dụng để tạo một header stack với tối đa 40 phần tử dạng bytechunk_payload_t.
    
    bit<8> chunk;
}

header segment_payload_t {
    // độ dài thực tế của segment
    bit<8> length;
    // dữ liệu thật của segment
    data_t data;
    // bit<160> ipv4;
    // bit<64> udp;
    // bit<96> udp_payload; kích thước tối đa của udp payload
    // (các gói tin sẽ có kích thước udp payload)
    // Tổng sức chứa của biến: 320 bits (40 bytes)
    // kích thước thật của segment có thể nhỏ hơn 40 byte.
    // Lúc này các bit 0 sẽ được để trước hoặc sau dữ liệu thật
}

header aggmeta_t {
    // Số segment thực tế trong batch (tối đa 13)
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
    bytechunk_payload_t[40] original_payload; // Header stack với tối đa 40 phần tử, tương ứng 40 byte.
    // Parser có thể parse đủ 40 phần tử này hoặc ít hơn.
    // Được sử dụng trong parser để parse payload gốc vào header stack này,
    // mỗi phần tử chứa 1 byte của payload gốc.
    // Cách này được sử dụng bởi nếu payload có kích thước nhỏ hơn 40 byte và được parse thẳng vào segment_payload_t,
    // sẽ xảy ra lỗi PacketTooShort.

    // Tác giả đã thử cách sử dụng varbit, song varbit bị hạn chế quá nhiều về khả năng thao tác
    // (chỉ tính toán với các varbit khác, không thể lưu trong register, không thể shift)
    
    segment_payload_t[MAX_SEGMENTS_PER_BATCH] parsed_payload; // Header stack này chứa tối đa 13 phần tử, nhằm lưu các segment
    // cũng như các thông tin liên quan đến segment (độ dài thực tế).
    // Header này sẽ được sử dụng ở giai đoạn egress. Dữ liệu của batch sẽ được sao chép từ register sang các phần tử của header này.
    // Để kích hoạt các phần tử của header stack này, cần phải gọi phương thức .setValid() cho từng phần tử,
    // đồng thời gán dữ liệu tương ứng cho từng phần tử.
}

struct metadata {
    bit<6> aggCount;
    bit<1> toggleSendAgg;
    bool dstMacChanged;
    bit<16> segLen; // độ dài thực tế của payload gốc, được parser lưu vào metadata để sử dụng trong quá trình tổng hợp.
    data_t payload_data; // Được sử dụng trong parser như vùng đệm
    // để ghép các byte của payload được parse vào stack bytechunk_payload_t[]
    // thành một khối dữ liệu dạng data_t trước khi đẩy vào register
    // Tác giả không lưu trực tiếp vào register vì không thể thao tác với register trong parser.
}