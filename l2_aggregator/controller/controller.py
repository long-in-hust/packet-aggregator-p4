import argparse
import os
from time import sleep
import p4runtime_lib.bmv2
import p4runtime_lib.helper

# Aggregator switch
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

def main(p4info_file_path, bmv2_file_path):
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    hosts_mac = {'10.0.0.1':'00:00:00:00:00:01',
                 '10.0.0.2':'00:00:00:00:00:02',
                 '10.0.0.3':'00:00:00:00:00:03'
                }
    # Forwarding rules for the switches, i.e., which dst_mac can be reached via which port
    switch_port = {
                    's1': {'00:00:00:00:00:01':1,
                           '00:00:00:00:00:02':2,
                           '00:00:00:00:00:03':2},
                    's2': {'00:00:00:00:00:01':3,
                           '00:00:00:00:00:02':1,
                           '00:00:00:00:00:03':2}
                    }