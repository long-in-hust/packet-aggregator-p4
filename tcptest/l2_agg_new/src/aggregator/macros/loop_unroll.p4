/*
    Why did I unroll the loop and write APPEND_SEGMENT almost 30 times instead of just doing a for loop from 0 to MAX_SEG-1 and calling APPEND_PAYLOAD(i) in the loop body ?
    Well, P4 never allow loops ! The APPEND_PAYLOAD macro is to make it look shorter, else it would look 8 times longer than what you see.

    Also, the else part with return is to avoid unnecessary iterations once all segments have been appended. Since we are decrementing mta.aggCount with each appended segment, once it reaches 0, we can stop appending and just set the EtherType and return the packet.
*/

/* 
Skip the problem with huge variation in size
*/

#define APPEND_SEGMENT                     \
    if (mta.aggCount > 0) {                           \
        index = (bit<32>)inactive_q * MAX_SEG + (bit<32>)mta.aggCount - 1;  \
        data_queues.read(segment_data, index);  \
        length_queues.read(segment_length, index);  \
        hdr.aggSegments.push_front(1);   \
        hdr.aggSegments[0].setValid();    \
        hdr.aggSegments[0].data = segment_data;   \
        hdr.aggSegments[0].segLen = segment_length;   \
        mta.aggCount = mta.aggCount - 1;   \
    }   \
    else {  \
         \
        return; \
    }

// // Unecessary !
// #define APPEND_SEGMENT_V2                  \
//     if (mta.aggCount > 0) {                           \
//         index = (bit<32>)inactive_q * MAX_SEG + (bit<32>)mta.aggCount - 1;  \
//         data_queues.read(segment_data, index);  \
//         length_queues.read(segment_length, index); \
//         hdr.longPayload.data = (hdr.longPayload.data << 16) | (longData_t)segment_length;   \
//         hdr.longPayload.data = (hdr.longPayload.data << segment_length * 8) | (longData_t)segment_data;   \
//         mta.aggCount = mta.aggCount - 1;   \
//     }   \
//     else {  \
//          \
//         return; \
//     }

#define APPEND_PAYLOAD \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT \
    APPEND_SEGMENT