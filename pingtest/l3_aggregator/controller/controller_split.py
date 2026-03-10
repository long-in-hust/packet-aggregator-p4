#!/home/p4/src/p4dev-python-venv/bin/python

import argparse
import os
from time import sleep
import p4runtime_lib.bmv2
import p4runtime_lib.helper
# For clone session
import grpc
from p4.v1 import p4runtime_pb2, p4runtime_pb2_grpc
from p4.config.v1 import p4info_pb2
from google.protobuf import text_format


# Splitter switch
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

# def writeSplitBufferRules(p4info_helper, sw, dst_mac, agg_flow_id):
#     table_entry = p4info_helper.buildTableEntry(
#             table_name="sw_ingress.aggr_buffer",
#             match_fields={
#                 "hdr.ethernet.dstAddr":dst_mac
#             },
#             action_name="sw_ingress.save_buffer",
#             action_params={
#                 "aggId":agg_flow_id,
#             })
#     sw.WriteTableEntry(table_entry)
#     print("Install Buffer rule into switch %s" % sw.name)

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

def createCloneSession(sw, session_id, replicas):
    sw.insertCloneSession(session_id, replicas)

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
    
    # Write rules into switch 2 (Splitter):
    s2 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s2',
            address='127.0.0.1:50052',
            device_id=1
    )
    s2.SetForwardingPipelineConfig(
            p4info=p4info_helper.p4info,
            bmv2_json_file_path=bmv2_file_path
        )
    
    print("Installed P4 Program using SetForwardingPipelineConfig on s2")

    # ARP rules
    for ip in hosts_mac:
        writeArpRules(p4info_helper, sw=s2, arp_request_ip=ip, arp_reply_mac=hosts_mac[ip])
    
    # Forwarding rules
    for mac in switch_port['s2']:
        writeForwardingRules(p4info_helper, sw=s2, dst_mac=mac, out_port=switch_port['s2'][mac])
    
    # Create clone session on s2
    replicas = [
        {'egress_port':switch_port['s2']['00:00:00:00:00:03'], 'instance':1}
    ]
    createCloneSession(s2, session_id=1, replicas=replicas)

    # Read table entries to check changes
    readTableRules(p4info_helper, s2)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
                        type=str, action="store", required=False,
                        default='./build/l3_switch.p4info')
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
                        type=str, action="store", required=False,
                        default='./build/l3_switch.json')
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