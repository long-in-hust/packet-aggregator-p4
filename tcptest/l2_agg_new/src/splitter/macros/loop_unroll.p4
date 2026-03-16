/*
    Why did I unroll the loop and write POP_SEGMENT almost 30 times instead of just doing a for loop from 0 to MAX_SEG-1 and calling APPEND_PAYLOAD(i) in the loop body ?
    Well, P4 never allow loops ! The APPEND_PAYLOAD macro is to make it look shorter, else it would look 8 times longer than what you see.

    Also, the else part with return is to avoid unnecessary iterations once all segments have been appended. Since we are decrementing mta.aggCount with each appended segment, once it reaches 0, we can stop appending and just set the EtherType and return the packet.
*/

/**
        if (current_count > 0) {    \
            mta.resubmitted = true;     \
            resubmit_preserving_field_list(1);     \
            clone(CloneType.I2E, 1);     \
        }     \
**/

#define POP_SEGMENT                     \
    if (mta.aggCount > 0) {                           \
        if (std_meta.instance_type == 0) {     \
            data_queue.write((bit<32>)current_tail, hdr.payload[0].data);     \
            current_count = current_count + 1;     \
            count_variable.write(0, current_count);     \
            current_tail = (current_tail + 1) % MAX_SEG_BUF;     \
            head_tail_index.write(1, current_tail);       \
        }     \
        hdr.payload[0].setInvalid();     \
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
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT \
    POP_SEGMENT