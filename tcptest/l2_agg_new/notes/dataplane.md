# Giải thích mã nguồn lớp dữ liệu

## Switch tổng hợp:

### Luồng của gói tin:

1. Gói tin vào switch.

2. Switch cấp một khoảng buffer dành cho gói tin.

Khoảng buffer này được cấp riêng cho gói. Kích thước bằng kích thước gói + 512 byte. (Gói tin 51 byte, không gian được cấp cho buffer sẽ có kích thước 51 + 512 = 563).

```
Constructor: Initializing packet buffer...
Pushing 51 bytes to packet buffer (data size before push: 0) - Buffer size before push is 563
Data size after push: 51
Constructor: Initialized packet buffer with 51 bytes of data
```

3. 