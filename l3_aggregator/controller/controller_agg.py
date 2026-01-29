#!/home/p4/src/p4dev-python-venv/bin/python

import argparse
import os
from time import sleep
import p4runtime_lib.bmv2
import p4runtime_lib.helper

# Aggregator switch
# Read table entries
def readTableRules(p4info_helper, sw):
    print('\n----- Reading tables rules for %s -----' % sw.name)
    for response in sw.ReadTableEntries():
        for entity in response.entities:
            entry = entity.table_entry
            print(entry)
            print('-----')


# ARP rules to resolve IP to MAC address
def writeArpRules(p4info_helper, sw, arp_request_ip, arp_reply_mac):
    table_entry = p4info_helper.buildTableEntry(
            table_name="sw_ingress.arp_learning",
            match_fields={
                "hdr.arp.dst_ip":arp_request_ip
            },
            action_name="sw_ingress.mac_resolve",
            action_params={
                "dst_mac":arp_reply_mac,
            })
    sw.WriteTableEntry(table_entry)
    print("Install ARP rule into switch %s" % sw.name)

def writeAggBufferRules(p4info_helper, sw, dst_mac, agg_flow_id):
    table_entry = p4info_helper.buildTableEntry(
            table_name="sw_ingress.aggr_buffer",
            match_fields={
                "hdr.ethernet.dstAddr":dst_mac
            },
            action_name="sw_ingress.save_buffer",
            action_params={
                "aggId":agg_flow_id,
            })
    sw.WriteTableEntry(table_entry)
    print("Install Buffer rule into switch %s" % sw.name)

def writeForwardingRules(p4info_helper, sw, dst_mac, out_port):
    table_entry = p4info_helper.buildTableEntry(
            table_name="sw_ingress.eth_forward",
            match_fields={
                "hdr.ethernet.dstAddr":dst_mac
            },
            action_name="sw_ingress.forward",
            action_params={
                "port":out_port,
            })
    sw.WriteTableEntry(table_entry)
    print("Install Forwarding rule into switch %s" % sw.name)

# egress rule
def writeEgressAggPktRules(p4info_helper, sw, dst_mac):
    table_entry = p4info_helper.buildTableEntry(
            table_name="sw_egress.eth_forward",
            match_fields={
                "hdr.ethernet.dstAddr":dst_mac
            },
            action_name="sw_egress.formAggPacket"
    )
    sw.WriteTableEntry(table_entry)
    print("Install Egress AggPkt rule into switch %s" % sw.name)

def main(p4info_file_path, bmv2_file_path):
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    hosts_mac = {'10.0.0.1':'00:00:00:00:00:01',
                 '10.0.0.2':'00:00:00:00:00:02',
                 '10.0.0.3':'00:00:00:00:00:03',
                 '10.0.0.4':'00:00:00:00:00:04'
                }
    # Forwarding rules for the switches, i.e., which dst_mac can be reached via which port
    switch_port = {
                    's1': {'00:00:00:00:00:01':1,
                           '00:00:00:00:00:02':2,
                           '00:00:00:00:00:03':2,
                           '00:00:00:00:00:04':3},
                    's2': {'00:00:00:00:00:01':3,
                           '00:00:00:00:00:02':1,
                           '00:00:00:00:00:03':2}
                    }
    
    # Write rules into switch 1 (Aggregator):
    s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50051',
            device_id=0
    )
    s1.SetForwardingPipelineConfig(
            p4info=p4info_helper.p4info,
            bmv2_json_file_path=bmv2_file_path
        )
    
    print("Installed P4 Program using SetForwardingPipelineConfig on s1")

    # ARP rules
    for ip in hosts_mac:
        writeArpRules(p4info_helper, sw=s1, arp_request_ip=ip, arp_reply_mac=hosts_mac[ip])
    
    # Forwarding rules
    writeForwardingRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:01', out_port=switch_port['s1']['00:00:00:00:00:01'])
    writeForwardingRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:04', out_port=switch_port['s1']['00:00:00:00:00:04'])
    
    # Aggregation buffer rules
    writeAggBufferRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:03', agg_flow_id=0)
    writeAggBufferRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:04', agg_flow_id=1)

    # Egress rules
    # For aggregated packets
    writeEgressAggPktRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:03')
    writeEgressAggPktRules(p4info_helper, sw=s1, dst_mac='00:00:00:00:00:04')  

    # Read table entries to check changes
    readTableRules(p4info_helper, s1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
                        type=str, action="store", required=False,
                        default='./build/l2_switch.p4info')
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
                        type=str, action="store", required=False,
                        default='./build/l2_switch.json')
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print("\np4info file not found: %s\nHave you run 'make'?" % args.p4info)
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print("\nBMv2 JSON file not found: %s\nHave you run 'make'?" % args.bmv2_json)
        parser.exit(1)

    main(args.p4info, args.bmv2_json)