# Dự án: Tổng hợp và tách gói tin sử dụng ngôn ngữ P4 trên switch SDN Behavioral Model v2

## Tiến độ hiện tại:

- [x] Đã có thể tổng hợp các gói tin có cùng nguồn và đích đến
- [x] Có thể tách và khôi phục các gói tin gốc các gói tin đã tổng hợp nếu chúng có cùng địa chỉ đích.

- [x] Tổng hợp các gói tin khác nguồn, cùng đích đến (cần lưu địa chỉ nguồn).
- [x] Đảm bảo header có đích đến A không bị gắn nhầm vào payload được dự định gửi cho đích đến B. (Cần dựng flow theo địa chỉ đích)

- [o] Cân nhắc viết lại chương trình control plane hoặc chuyển sang sử dụng thrift server (cần tìm hiểu)
- [x] Viết lại mininet sử dụng simple switch không tích hợp GRPC

- [x] Thêm giới hạn thời gian cho việc tổng hợp (tạm thời xác định là 0.2 giây)

### Một số lỗi:
- **(2026/03/27 11:17)** Lỗi khi tổng hợp gói tin tới địa chỉ đích 00:00:00:00:00:02 -> Lỗi từ s1 (switch tổng hợp)
    - Nguyên nhân: lỗi nằm ở việc kể cả khi chỉ có 1 segment, thử được gửi đi là frame ethernet với ethertype là IPv4, nhưng payload của frame đấy lại chứa thêm 6 bit đầu cho địa chỉ nguồn, gây sai lệch thông tin gói IPv4 khi switch tách đọc được (do cũng không phải EtherType cho gói tổng hợp với aggmeta tổng hợp để trích xuất segment và lấy dữ liệu).
    - Trạng thái: đã khắc phục.
    - Cách xử lý: Thêm một cấu trúc header gọi là parsed_payload để lưu phần dữ liệu của segment nếu chỉ có 1 segment duy nhất, cấu trúc này không chứa thông tin về nguồn gốc mà chỉ chứa dữ liệu đúng như khi được parse và lưu trong register. Gói tin gốc đã được khôi phục khi gắn vào và deparse.

## Hướng phát triển cho giai đoạn sau:
- [ ] Tích hợp source routing để tách-nhập giữa đường.
- [ ] Chuyển kiến trúc sang PSA hoặc XDP (đang cân nhắc)

## Công việc cần làm hiện tại:

- [x] Tổng hợp các gói tin khác nguồn:
    - [x] Agg switch:
        - [x] Thêm cấu trúc dữ liệu payload chứa srcMAC của từng segment
        - [x] Tạo thêm một register chứa srcMAC
        - [x] Thêm các dòng mã để thực hiện việc ghi srcMAC vào register
        - [x] Thêm các dòng mã để thực hiện việc lấy srcMAC từ register và ghi vào cấu trúc payload mới -> sẽ ktra
        - [x] Thay địa chỉ nguồn của gói tin tổng hợp bằng một địa chỉ được gán bên trong switch -> sẽ ktra
    - [x] Split switch:
        - [x] Thêm cấu trúc dữ liệu payload chứa srcMAC của từng segment khi parse
        - [x] Tách kiểu dữ liệu chỉ chứa payload khi deparse
        - [x] Tạo một register chứa srcMAC
        - [x] Thêm các dòng mã để thực hiện việc ghi srcMAC vào register -> sẽ ktra
        - [x] Thêm các dòng mã để thay srcMAC trong gói tin được phục hồi -> sẽ ktra

- [x] Tổng hợp các gói tin khác đích (nhiều flow):
    - [x] Agg switch:
        - [x] Gắn flow ID vào aggmeta cho cấu trúc payload của gói tin tương ứng với địa chỉ MAC đích
        - [x] Tạo register với 2 phần tử chứa FlowID cho 2 batch
        - [x] Tạo một bảng đối chiếu giữa MAC đích và FlowID
        - [x] Chỉnh lại chương trình control plane để nạp tham số FlowID
    - [x] Split switch:
        - [x] Gắn flow ID vào aggmeta cho cấu trúc payload của gói tin tương ứng với địa chỉ MAC đích
        - [x] Tạo thêm một register đóng vai trò như bảng đối chiếu giữa FlowID (chỉ số) và MAC đích (giá trị)
            - [x] Dựng đoạn mã ghi vào register
        - [x] Recirculate lại gói tin clone để forward lại

- [x] Thêm giới hạn thời gian cho việc tổng hợp
    - [x] Tạo 2 register, một cho thời gian gói đầu tiên của flow sau reset đi vào, 1 cho gói hiện tại.
    - [x] Tìm hiểu đơn vị của standard_metadata.ingress_global_timestamp.
    - [x] Viết điều kiện trong action.

- [ ] Viết lại các lệnh gọi control plane bằng lệnh simple_switch_cli và giải thích được ý nghĩa