# Switch P4 xử lý tổng hợp gói tin

## Giới thiệu
Đây là switch SDN (trong bài viết này sẽ gọi tắt là "switch") với lớp dữ liệu lập trình được. Ngôn ngữ P4 được sử dụng để viết chương trình. Chương trình sẽ được biên dịch thành Data plane configuration (dạng file JSON) trước khi đuọc nạp vào switch.

Data plane configuration (còn gọi là Data plane runtime) là một tệp JSON miêu tả các logic chuyển tiếp cho lớp dữ liệu của switch.
