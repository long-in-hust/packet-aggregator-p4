# Giải thích mã nguồn lớp dữ liệu

## Switch tổng hợp:

### Luồng của gói tin:

1. Gói tin vào switch.

2. Switch cấp một khoảng buffer dành cho gói tin.

Khoảng buffer này được cấp riêng cho gói. Kích thước bằng kích thước gói + 512 byte. (Gói tin 51 byte, không gian được cấp cho buffer sẽ có kích thước 51 + 512 = 563).

```log
[13:32:39.961390] [bmv2] [T] [thread 56325] Constructor: Initializing packet buffer...
[13:32:39.961410] [bmv2] [T] [thread 56325] Pushing 51 bytes to packet buffer (data size before push: 0) - Buffer size before push is 563
[13:32:39.961414] [bmv2] [T] [thread 56325] Data size after push: 51
```

3. Gói tin được xử lý và đi qua parser

```log
[13:32:39.961500] [bmv2] [D] [thread 56326] [58.0] [cxt 0] Processing packet received on port 1
[13:32:39.961515] [bmv2] [D] [thread 56326] [58.0] [cxt 0] Parser 'parser': start
[...]
```

4. Các byte đã parse được bỏ khỏi phần buffer được cấp phát cho gói tin -> Kết thúc parser:

```log
[...]
[13:32:39.949925] [bmv2] [T] [thread 56326] Popping 51 bytes from packet buffer (data size before pop: 51) - Buffer size before pop is 563
[13:32:39.949929] [bmv2] [T] [thread 56326] Data size after pop: 0
[13:32:39.949933] [bmv2] [D] [thread 56326] [57.0] [cxt 0] Parser 'parser': end
```