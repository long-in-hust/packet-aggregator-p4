#include <core.p4>
#include <v1model.p4>
#include "dataStructs.p4"
#include "macros/loop_unroll.p4"

/* 
------- Switch logic --------
*/
parser pkt_parser(packet_in pkt, out headers hdr,
                      inout metadata mta, inout standard_metadata_t std_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        // Do áp dụng recirculate nên cần kiểm tra thêm cho gói tin IPv4 (sẽ giải thích ở dưới)
        transition select(hdr.ethernet.etherType) {
            EtherType.ARP:  parse_arp;
            EtherType.L3AGG: parse_l3agg; // Parse gói tin tổng hợp được gửi từ agg switch
            // EtherType.IPV4: check_ipv4; // Kiểm tra một số thông tin cho gói tin  IPv4
            default:        accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_l3agg {
        pkt.extract(hdr.aggmeta);
        // Lấy số segment còn lại để chuẩn bị parse payload
        mta.segCountRemaining = hdr.aggmeta.segCount;
        transition select (mta.segCountRemaining) {
            0: accept;
            default: parse_payloads; // Độ dài phải lớn hơn 0 mới có payload để parse
        }
    }

    // state check_ipv4{
    //     // Điều kiện: gói tin được tái lưu hành và không phải clone

    //     // Nếu đây không phải gói tin được recirculate từ egress,
    //     // nó chỉ là gói IPv4 bình thường, không cần parse gì thêm, chỉ cần chuyển tiếp như gói tin bình thường.
    //     // Ngược lại, gói tin IPv4 được recirculate là để tái sử dụng phần header
    //     // và gắn vào segment tiếp theo trước khi gửi ra.
    //     // Do đó cần parse payload của frame ethernet này để thay bằng segment tiếp theo.
    //     transition select (mta.recirculated) {
    //         true: parse_ipv4;
    //         default: accept;
    //     }
    // }

    // state parse_ipv4 {
    //     // Parse payload của frame ethernet để thay bằng segment tiếp theo
    //     pkt.extract(hdr.recovered_payload);
    //     transition accept;
    // }

    // Kết hợp header_stack.next và transition vào chính trạng thái hiện hành
    // để triển khai vòng lặp mà không cần ghi cụ thể số lần.
    state parse_payloads {
        pkt.extract(hdr.segments.next);
        mta.segCountRemaining = mta.segCountRemaining - 1;
        transition select(mta.segCountRemaining) {
            0: accept;
            default: parse_payloads;
        }
    }
}

control checksum_verifier(inout headers hdr, inout metadata mta) {
    apply {
        // Tạm bỏ qua và chưa xét đến bước này
    }
}

control sw_ingress(inout headers hdr, inout metadata mta,
                inout standard_metadata_t std_meta) {
    // Hành động drop() phải được định nghĩa vì mark_to_drop() là một hàm extern, không thể được gọi từ trong bảng.
    // Bảng ARP và bảng forwar sẽ dùng drop như hành động mặc định nếu không khớp với mục nào.
    action drop() {
        mark_to_drop(std_meta);
    }
    
    // Include file p4 khác vì mã nguồn dài và cần được chia nhỏ để dễ đọc và tác động hơn.
    #include "ingress/splitBuffer.p4"
    #include "ingress/L2Actions.p4"

    apply {
        if (hdr.ethernet.isValid())
        {
            if (hdr.ethernet.etherType == EtherType.ARP && hdr.arp.isValid()) {
                // Không áp dụng trích segment cho các gói ARP
                // Áp dụng bảng học ARP để phân giải IPv4 sang MAC và báo về host nguồn.
                arp_learning.apply();
            }
            else {
                if (hdr.ethernet.etherType == EtherType.L3AGG && hdr.aggmeta.isValid()) {
                    // Trích các segment từ payload nếu đó là gói tổng hợp hợp lệ
                    save_buffer();
                }
                if (mta.recirculated) {
                    // Đánh lại instance_type về 0 để
                    // xem như gói tin thường và bỏ qua điều kiện nhận diện clone ở lần sau,
                    // tránh bị lặp lại clone không cần thiết.
                    std_meta.instance_type = 0;
                }
                // Chuyển tiếp Layer 2 như gói tin bình thường nếu header ethernet hợp lệ,
                // và không phải ARP (cần gửi ra đúng cồng đi vào).
                eth_forward.apply();
            }
        }
        else {
            // Bỏ gói tin không có header Ethernet hợp lệ
            drop();
        }
    }
}

control sw_egress(inout headers hdr, inout metadata mta,
               inout standard_metadata_t std_meta) {
    
    // hành động này là một thủ tục, không thực hiện ngay mà sẽ được gọi trong khối apply
    action drop() {
        mark_to_drop(std_meta);
    }

    #include "egress/sendSplitPkt.p4"

    apply {
        if (hdr.ethernet.isValid())
        {
            // Dùng header để dụng thành thành gói tin ban đầu nếu đạt một trong 2 điều kiện:
            // 1: hdr.ethernet.etherType == EtherType.L3AGG -> đây là header của gói tin tổng hợp
            // Vì payload đã được trích ra và lưu ở control ingress, có thể tận dụng header này
            // để gán segment và dựng thành gói tin ban đầu.

            // 2: mta.recirculated == true -> đây là gói tin được tái lưu thông với mục đích
            // chuẩn bị gắn segment tiếp theo vào payload và gửi đi.
            if ((hdr.ethernet.etherType == EtherType.L3AGG) || mta.recirculated) {
                formSegPacket();
            }
        }
        else {
            // loại bỏ gói tin không hợp lệ
            drop();
        }
    }
}

control checksum_recalc(inout headers hdr, inout metadata mta) {
    apply {
    }
}

control sw_deparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.aggmeta);
        pkt.emit(hdr.recovered_payload);
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