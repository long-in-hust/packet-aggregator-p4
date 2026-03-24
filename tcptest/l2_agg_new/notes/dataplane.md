# Giải thích mã nguồn lớp dữ liệu

## Switch tổng hợp:

### Luồng của gói tin:

1. Gói tin vào switch.

2. Switch cấp một buffer dành cho gói tin (PacketBuffer).

Khoảng buffer này được cấp riêng cho gói. Kích thước bằng kích thước gói + 512 byte. (Gói tin 51 byte, không gian được cấp cho buffer sẽ có kích thước 51 + 512 = 563).

```log
[13:32:39.961390] [bmv2] [T] [thread 56325] Constructor: Initializing packet buffer...
[13:32:39.961410] [bmv2] [T] [thread 56325] Pushing 51 bytes to packet buffer (data size before push: 0) - Buffer size before push is 563
[13:32:39.961414] [bmv2] [T] [thread 56325] Data size after push: 51
```
Các PacketBuffer là một phần của InputBuffer. Hiện chưa tìm ra cách để pipeline gói tin này trực tiếp can thiệp buffer của gói tin khác.

3. Gói tin được xử lý và đi qua parser.

```log
[13:32:39.961500] [bmv2] [D] [thread 56326] [58.0] [cxt 0] Processing packet received on port 1
[13:32:39.961515] [bmv2] [D] [thread 56326] [58.0] [cxt 0] Parser 'parser': start
[...]
```
Khi parse: 
- Các bit được parse sẽ được sao chép vào cấu trúc được định nghĩa trong chương trình.
- Con trỏ đầu buffer của gói sẽ lùi lại một khoảng tương ứng với các số đã parse.

4. Các byte đã parse được bỏ khỏi phần buffer được cấp phát cho gói tin -> Kết thúc parser:

```log
[...]
[13:32:39.949925] [bmv2] [T] [thread 56326] Popping 51 bytes from packet buffer (data size before pop: 51) - Buffer size before pop is 563
[13:32:39.949929] [bmv2] [T] [thread 56326] Data size after pop: 0
[13:32:39.949933] [bmv2] [D] [thread 56326] [57.0] [cxt 0] Parser 'parser': end
```

5. Các thông tin đã parse vào cấu trúc sẽ được chuyển vào ingress, trong khi phần chưa parse ở lại trong buffer:

```log
[13:32:39.949938] [bmv2] [D] [thread 56326] [57.0] [cxt 0] Pipeline 'ingress': start
```

6. Theo kiến trúc V1Model, gói tin sẽ đi thẳng từ ingress sang egress mà không trải qua bước buffer.

```log
[13:32:40.129346] [bmv2] [D] [thread 56326] [69.0] [cxt 0] Pipeline 'ingress': end
[13:32:40.129350] [bmv2] [D] [thread 56326] [69.0] [cxt 0] Egress port is 2
[13:32:40.131152] [bmv2] [D] [thread 56329] [69.0] [cxt 0] Pipeline 'egress': start
[...]
[13:32:40.132662] [bmv2] [D] [thread 56329] [69.0] [cxt 0] Pipeline 'egress': end
```

7. Deparser sẽ khởi động ngay sau khi egress kết thúc, các byte đã parse ở parser sẽ được đẩy về lại buffer
```log
[13:32:40.132668] [bmv2] [D] [thread 56329] [69.0] [cxt 0] Deparser 'deparser': start
[13:32:40.132674] [bmv2] [T] [thread 56329] Pushing 495 bytes to packet buffer (data size before push: 0) - Buffer size before push is 564
```

8. Gói tin được truyền ra ngoài theo lệnh emit.