# Dự án: Tổng hợp và tách gói tin sử dụng ngôn ngữ P4 trên switch SDN Behavioral Model v2

## Tiến độ hiện tại:

- [x] Đã có thể tổng hợp các gói tin có cùng nguồn và đích đến
- [x] Có thể tách và khôi phục các gói tin gốc các gói tin đã tổng hợp nếu chúng có cùng địa chỉ đích.

- [ ] Tổng hợp các gói tin khác nguồn, cùng đích đến (cần lưu địa chỉ nguồn).
- [ ] Đảm bảo header có đích đến A không bị gắn nhầm vào payload được dự định gửi cho đích đến B. (Cần dựng flow theo địa chỉ đích)

- [ ] Cân nhắc viết lại chương trình control plane hoặc chuyển sang sử dụng thrift server (cần tìm hiểu)
- [ ] Viết lại mininet sử dụng simple switch không tích hợp GRPC

## Hướng phát triển cho giai đoạn sau:
- [ ] Tích hợp source routing để tách-nhập giữa đường.
- [ ] Chuyển kiến trúc sang PSA hoặc XDP (đang cân nhắc)

## Công việc cần làm hiện tại:

- [ ] Tổng hợp các gói tin khác nguồn:
    - [ ] Agg switch:
        - [ ] Thêm cấu trúc dữ liệu payload chứa srcMAC của từng segment
        - [ ] Tạo thêm một register chứa srcMAC
    - [ ] Split switch:
        - [ ] Thêm cấu trúc dữ liệu payload chứa srcMAC của từng segment khi parse
        - [ ] Tách kiểu dữ liệu chỉ chứa payload khi deparse
        - [ ] Tạo một register chứa srcMAC

- [ ] Tổng hợp các gói tin khác đích (nhiều flow):
    - [ ] Agg switch:
        - [ ] Gắn flow ID vào aggmeta cho cấu trúc payload của gói tin tương ứng với địa chỉ MAC đích
    - [ ] Split switch:
        - [ ] Gắn flow ID vào aggmeta cho cấu trúc payload của gói tin tương ứng với địa chỉ MAC đích
        - [ ] Tạo thêm một register chứa flow
        - [ ] Tạo thêm một register đóng vai trò như bảng đối chiếu giữa ID (chỉ số) và MAC đích (giá trị)