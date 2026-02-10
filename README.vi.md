# Chương trình P4 Switch - Mô phỏng tổng hợp gói tin
---
Cấu trúc thư mục của chương trình này giống như dưới đây:

```
|
|___ l2_aggregator - code tổng hợp và phân tách gói tin dựa trên tầng liên kết dữ liệu
|    |_ controller: code tầng điều khiển
|    |_ mininet: code triển khai topo mạng mô phỏng
|    |_ src: code P4 sẽ được biên dịch cho BMv2
|    |  |_ aggregator: code riêng cho switch tổng hợp
|    |  |_ splitter: code riêng cho switch phân tách
|    |
|    |_ test: không sử dụng
|    |_ Makefile
|
|___ l3_aggregator
     |
     ... Code tổng hợp và phân tách gói tin dựa trên tầng mạng - Cấu trúc thư mụctương tự như l2_aggregator
```
