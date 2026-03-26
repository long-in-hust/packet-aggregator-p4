/*
    Sử dụng Macro để tránh phải viết nhiều lần đoạn code giống nhau.
    Đoạn code dưới đây làm các việc sau:
        1. Kiểm tra metadata mta.aggCount để biết còn bao nhiêu segment, nếu bằng 0 thì dừng lại và return (thoát action).
        2. Nếu còn segment, làm các việc tiếp theo:
        3. Ghi payload vào register data_queue tại vị trí current_tail (phần tử liền sau cuối cùng chứa dữ liệu)
        4. Tăng số lượng segment đã lưu trong register (current_count) lên 1 và ghi lại vào count_variable
        5. Tăng current tail lên 1 vị trí, thực hiện phép modulo để quay lại đầu register nếu vượt quá kích thước, ghi lại
            vị trí đuôi mới vào head_tail_index(1).
        6. Loại bỏ 1 segment đầu tiên trong header stack (hdr.payload) bằng pop_front(1) để chuẩn bị cho segment tiếp theo.
        7. Giảm mta.aggCount đi 1 và chuẩn bị lặp lại đoạn code.
        8. Vòng lặp sẽ tiếp tục đến khi mta.aggCount bằng 0, lúc đó sẽ dừng lại và thoát action.
*/

#define POP_SEGMENT                     \
    if (mta.aggCount > 0) {                           \
        data_queue.write((bit<32>)current_tail, hdr.payload[0].data);     \
        current_count = current_count + 1;     \
        count_variable.write(0, current_count);     \
        current_tail = (current_tail + 1) % MAX_SEGMENT_NUMBER;     \
        head_tail_index.write(1, current_tail);       \
        hdr.payload.pop_front(1);   \
        mta.aggCount = mta.aggCount - 1;   \
    }   \
    else {  \
        return;    \
    }

#define RETRIEVE_PAYLOAD \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT 
