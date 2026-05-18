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
    
    #include "ingress.p4"

}

control sw_egress(inout headers hdr, inout metadata mta,
               inout standard_metadata_t std_meta) {

    #include "egress.p4"
    
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