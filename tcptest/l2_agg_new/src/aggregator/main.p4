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
    
    // Các biến tạm để lưu trữ độ dài còn lại cần parse (tmpLength)
    // và số lần cần dịch trái dữ liệu (leftShiftAmount) để đưa dữ liệu lên đầu (bên trái) của biến mta.payload_data.
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
        // Lookahead<bit<n>>(): xem trước n bit dữ liệu tiếp theo trong phần dữ liêu chưa extract của gói
        // mà không dịch con trỏ đầu gói ra sau hay lấy dữ liệu đó vào đơn vị cấu trúc header.
        // Ở đây 32 bit đầu tiên cũng là 32 bit đầu của header IPv4,
        // [15:0] để lấy các bit từ 15 đến 0 (tính từ bên phải) của 32 bit được lookahead,
        // tương ứng với các bit từ 16 đến 31 tính từ đầu header IPv4, tương ứng với trường Total Length của header IPv4.
        mta.segLen = pkt.lookahead<bit<32>>()[15:0];
        // Lưu độ dài còn lại cần parse vào biến tạm tmpLength để dùng trong state parse_l3.
        // mta.segLen không thay đổi vì giá trị này sẽ được sử dụng ở giai đoạn sau
        tmpLength = mta.segLen;
        // leftShiftAmount được tính để biết cần dịch trái bao nhiêu lần để đưa dữ liệu lên đầu của mta.payload_data
        // sau khi parse xong phần dữ liệu cần thiết.
        // Giá trị này tính theo đơn vị byte
        leftShiftAmount = 40 - (mta.segLen);
        // Nếu độ dài cần parse là 0, nghĩa là gói tin không có payload nào sau header Ethernet để parse hay dịch trái
        transition select(tmpLength) {
            0: accept; // Đúng ra phải là reject (từ chối) vì gói tin này không có payload nào sau header Ethernet,
            // không có giá trị thực tế
            // Tuy nhiên v1model không hỗ trợ khai báo tường minh việc chuyển sang state reject
            // ([--Wwarn=unsupported] warning: Explicit transition to reject not supported on this target)
            default: parse_l3;
        }
    }

    state parse_l3 {
        // Việc kết hợp con trỏ hdr.original_payload.next với phần
        // transition select điều hướng về lại chính state này cho phép
        // tạo luồng hoạt động như vòng lặp mà không cần xác định cụ thể số lần trong code trước khi compile

        // Các phần tử chưa được parse trong header stack này sẽ có giá trị trả về của phương thức .isValid() là false
        // và được xem như không tồn tại.
        pkt.extract(hdr.original_payload.next);
        
        // Dịch trái 8 bit (1 byte) dữ liệu trong mta.payload_data
        // Sau khi dịch, 8 bit cuối sẽ toàn 0 để chuẩn bị dùng phép or để nối với byte tiếp theo
        mta.payload_data = mta.payload_data << 8;

        // Làm phép or - Khi cast dạng bit<8> sang dạng data_t, toàn bộ các bit bên trái sẽ được điền bằng 0
        // Phép or này sẽ lấp 8 bit cuối của mta.payload_data bằng byte vừa được parse vào hdr.original_payload.next.chunk
        mta.payload_data = mta.payload_data | (data_t)hdr.original_payload.last.chunk;

        // Độ dài còn lại cần parse giảm đi 1 byte.
        tmpLength = tmpLength - 1;

        // Sau khi extract, nếu độ dài còn lại bằng 0, nghĩa là đã parse xong phần dữ liệu cần thiết,
        // sẽ chuyển sang state pre_shift_left để kiểm tra xem có cần dịch trái thêm nữa hay không.
        // Ngược lại, tiếp tục quay lại parse đến khi độ dài về bằng 0.
        transition select(tmpLength) {
            0: pre_shift_left;
            default: parse_l3;
        }
    }

    state pre_shift_left {
        // Kiểm tra số byte cần dịch trái (do dữ liệu được ghi vào bên phải, trong khi cần dữ liệu ở bên trái, ngay sau header)
        transition select(leftShiftAmount) {
            0: accept;
            default: shift_left;
        }
    }

    state shift_left {
        // dịch trái 8 bit (1 byte)
        mta.payload_data = mta.payload_data << 8;
        // sau mỗi lần dịch trái, số byte cần dịch giảm đi 1
        leftShiftAmount = leftShiftAmount - 1;
        // Nếu số byte cần dịch về 0, nghĩa là đã dịch xong,
        // sẽ chuyển sang state accept để chấp nhận gói tin đi qua
        // control tiếp theo của pipeline và kết thúc quá trình parse.
        // Ngược lại tiếp tục quay lại state này và dịch trái tiếp.
        transition select(leftShiftAmount) {
            0: accept;
            default: shift_left;
        }
    }
}

control checksum_verifier(inout headers hdr, inout metadata mta) {
    apply {
        // Phần này để trống do chưa xét đến việc kiểm tra checksum.
    }
}

control sw_ingress(inout headers hdr, inout metadata mta,
                inout standard_metadata_t std_meta) {
    
    // Hành động drop() phải được định nghĩa vì mark_to_drop() là một hàm extern, không thể được gọi từ trong bảng.
    // Hành động này là một thủ tục và sẽ được gọi từ trong bảng hoặc trong khối apply(), chứ chưa chạy ngay
    action drop() {
        // Đánh dấu std_meta.egress_spec bằng DROP_PORT,
        // gói tin sẽ được chuyển tới cổng này
        // trước khi vào control tiếp theo và bị bỏ đi.
        mark_to_drop(std_meta);
    }
    
    // Include file p4 khác vì mã nguồn dài và cần được chia nhỏ để dễ đọc và tác động hơn.
    #include "ingress/L2Actions.p4"

    #include "ingress/aggBuffer.p4"

    apply {
        if (hdr.ethernet.isValid()) {
            // Nếu gói tin là ARP request, thực hiện chức năng ARP cơ bản để lấy địa chỉ MAC đích khi được yêu cầu.
            // Tuy không phải vấn đề chính trong đồ án, chức năng này quan trọng vì thiết bị gửi cần biết
            // địa chỉ MAC đích để gửi gói tin đi.
            if (hdr.ethernet.etherType == EtherType.ARP && 
                hdr.arp.isValid() && 
                hdr.arp.op_code == ArpOpCode.REQUEST) 
            {
                arp_learning.apply();
            }
            else {
                if (hdr.ethernet.etherType == EtherType.IPV4) {
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
        pkt.emit(hdr.original_payload);
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