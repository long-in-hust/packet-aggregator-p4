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
            EtherType.IPV4: check_ipv4; // Kiểm tra một số thông tin cho gói tin  IPv4
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

    state check_ipv4{
        // Gói tin IPv4 về cơ bản tương đương 1 segment
        mta.segCountRemaining = 1;
        // Nếu đây không phải gói tin được recirculate từ egress,
        // nó chỉ là gói IPv4 bình thường.
        // Ngược lại, gói tin IPv4 được recirculate là để tái sử dụng phần header
        // và gắn vào segment tiếp theo trước khi gửi ra
        transition select (mta.resubmitted) {
            true: parse_payloads;
            default: accept;
        }
    }

    // Kết hợp header_stack.next và transition vào chính trạng thái hiện hành
    // để triển khai vòng lặp mà không cần ghi cụ thể số lần.
    state parse_payloads {
        pkt.extract(hdr.payload.next);
        mta.segCountRemaining = mta.segCountRemaining - 1;
        transition select(mta.segCountRemaining) {
            0: accept;
            default: parse_payloads;
        }
    }
}

control checksum_verifier(inout headers hdr, inout metadata mta) {
    apply {
        // Will leave it empty for now
    }
}

control sw_ingress(inout headers hdr, inout metadata mta,
                inout standard_metadata_t std_meta) {
    // Hành động drop() phải được định nghĩa vì mark_to_drop() là một hàm extern, không thể được gọi từ trong bảng.
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
                arp_learning.apply();
            }
            else {
                if (hdr.ethernet.etherType == EtherType.L3AGG && hdr.aggmeta.isValid()) {
                    save_buffer();
                }
                eth_forward.apply();
            }
        }
        else {
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

    #include "egress/sendSplitPkt.p4"

    apply {
        if (hdr.ethernet.isValid())
        {
            if ((hdr.ethernet.etherType == EtherType.L3AGG && hdr.aggmeta.isValid()) || mta.resubmitted) {
                formSegPacket();
            }
        }
        else {
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
        pkt.emit(hdr.payload);
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