# Dự án: Tổng hợp và tách gói tin sử dụng ngôn ngữ P4 trên switch SDN Behavioral Model v2

## Tiến độ hiện tại:

- [x] Đã có thể tổng hợp các gói tin có cùng nguồn và đích đến
- [x] Có thể tách và khôi phục các gói tin gốc các gói tin đã tổng hợp nếu chúng có cùng địa chỉ đích.

- [ ] Tổng hợp các gói tin khác nguồn, cùng đích đến (cần lưu địa chỉ nguồn).
- [ ] Đảm bảo header có đích đến A không bị gắn nhầm vào payload được dự định gửi cho đích đến B. (Cần dựng flow theo địa chỉ đích)

## Hướng phát triển cho giai đoạn sau:
- [ ] Tích hợp source routing để tách-nhập giữa đường.
- [ ] Chuyển kiến trúc sang PSA