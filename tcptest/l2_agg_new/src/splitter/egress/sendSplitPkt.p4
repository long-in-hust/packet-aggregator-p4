// Đoạn mã dưới đây sẽ được chèn vào control sw_egress qua lệnh include.

action formSegPacket() {
    // Đọc số segment đang chờ trong register
    bit<10> current_count;
    count_variable.read(current_count, 0);

    // Đổi etherTyoe thành IPv4 (0800) để gửi đi như gói tin bình thường
    hdr.ethernet.etherType = EtherType.IPV4;

    // Gỡ header aggmeta vì đây không còn là gói tin tổng hợp
    hdr.aggmeta.setInvalid();

    if (current_count > 0) {
        if (std_meta.instance_type == PKT_INSTANCE_TYPE_EGRESS_CLONE){
            // Đánh dấu payload không hợp lệ để lấy header làm phôi để gắn segment tiếp theo vào.
            hdr.recovered_payload.setInvalid();

            // Tạo gói tin clone để gửi lại về đầu control egress.
            // Lý do tạo clone là bởi gói tin tổng hợp chứa nhiều đoạn payload sau cùng một header.
            // Để khôi phục thành các gói tin lẻ ban đầu, cần tạo ra nhiều header để gắn vào các segment tương ứng trong register.
            // Hàm clone có hai tham số, loại hình clone (Ingress2Egress hoặc Egress2Egress) và số hiệu clone session (để phân biệt
            // với các trường hợp clone khác nhau, nếu có). Clone session phải được tạo bằng cách gọi từ lớp điều khiển.

            // Với kiểu clone E2E gói tin clone sẽ được tạo ra ngay sau khi gói tin gốc ra khỏi egress,
            // và được gửi lại vào đầu control egress (có thể được chứng thực bằng dòng log "Cloning packet at egress"
            // ngay sau dòng "Pipeline 'egress': end")
            // Do không thể trực tiếp clone từ egress ngược về ingress để gửi gói tin gốc ra ngoài,
            // giải pháp sẽ là clone E2E, rồi để gói tin bản sao được nhận diện và kết thúc sớm control egress
            // gói tin bản sao (vốn được sao chép từ gói được gắn payload cần thiết từ trước khi clone) sẽ được gửi ra ngoài.
            clone(CloneType.E2E, 1);

            // Gói tin gốc sẽ được đánh dấu để chuẩn bị cho việc lưu thông lại trong switch
            // Trước khi được đánh dấu chuẩn bị cho tái lưu thông, cần đánh metadata recirculated để nhận diện điều này.
            // Gói tin gốc được tái lưu hành sẽ được gỡ payload cũ đi, gắn segment tiếp theo vào payload, sao chép và gửi đi, lặp lại đến khi không còn segment nào trong register.
            mta.recirculated = true;

            // Hàm extern recirculate_preserving_field_list(n) cho phép tái lưu thông gói tin trong switch
            // và giữ lại môt số trường metadata, các trường này được đánh dấu bằng annotation @field_list(n)
            // trong phần định nghĩa metadata.
            recirculate_preserving_field_list(1);
            return;
        }

        // Giảm số segment đang chờ đi 1
        current_count = current_count - 1;
        count_variable.write(0, current_count);

        // Lấy chỉ số đầu của "hàng đợi" được mô phỏng trong register data_queue
        // Chỉ số này được lưu trong head_tail_index ở phần tử 0
        bit<10> current_head;
        head_tail_index.read(current_head, 0); // use head index for reading

        // Kích hoạt header payload (mặc dù bước này không thực sự cần thiết nếu đây là
        // gói tin được recirculate từ egress, vì hdr.recovered_payload đã được xác định hợp lệ trước đó,
        // nhưng việc kiểm tra điều kiện và chia trường hợp sẽ khiến mã nguồn phức tạp hơn 
        // cũng như chưa chắc đã tiết kiệm được thời gian.)
        hdr.recovered_payload.setValid();
        // Lấy một segment từ vị trí đầu của "hàng đợi" và gắn vào payload của gói để chuẩn bị gửi đi.
        data_queue.read(hdr.recovered_payload.data, (bit<32>)current_head);
        // Tại vị trí tương tự trong register segment_src_macs cũng lưu địa chỉ MAC nguồn của segment,
        // đọc và gắn vào trường srcAddr của header ethernet để khôi phục lại gói tin gốc.
        segment_src_macs.read(hdr.ethernet.srcAddr, (bit<32>)current_head);
        // Đọc flow_id của segment từ register segment_flow_ids
        bit<8> curr_seg_flow_id;
        segment_flow_ids.read(curr_seg_flow_id, (bit<32>)current_head);
        // Dùng flow của id hiện tại làm chỉ số để tra địa chỉ MAC đích tương ứng từ register flow_dst_macs
        flow_dst_macs.read(hdr.ethernet.dstAddr, (bit<32>)curr_seg_flow_id);
        // Nâng chỉ số đầu của "hàng đợi" lên 1, cập nhật lại vào register head_tail_index để lấy ở segment tiếp theo trong lần sau.
        current_head = (current_head + 1) % MAX_SEGMENT_NUMBER;
        head_tail_index.write(0, current_head);

        // Nếu đây không phải clone, chỉ clone nếu gói tin đang ở trong switch lần đầu tiên
        if (!mta.recirculated) {
            clone(CloneType.E2E, 1);
            return;
        }
    } else {
        // Nếu không còn segment nào trong register để khôi phục thành gói tin,
        // drop header này đi để tránh gửi đi gói tin không hợp lệ.
        drop();
    }
}