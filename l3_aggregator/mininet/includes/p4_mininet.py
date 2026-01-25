# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from mininet.net import Mininet
from mininet.node import Switch, Host
from mininet.log import setLogLevel, info, error, debug
from mininet.moduledeps import pathCheck
from sys import exit
import os
import tempfile
import socket
from time import sleep
from .netstat import check_listening_on_port

import logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

SWITCH_START_TIMEOUT = 20 # seconds

class P4Host(Host):
    def config(self, **params):
        r = super(Host, self).config(**params)

        self.defaultIntf().rename("eth0")

        for off in ["rx", "tx", "sg"]:
            cmd = "/sbin/ethtool --offload eth0 %s off" % off
            self.cmd(cmd)

        # disable IPv6
        self.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
        self.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
        self.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

        return r

    def describe(self):
        print ("**********")
        print (self.name)
        print ("default interface: %s\t%s\t%s" % (
            self.defaultIntf().name,
            self.defaultIntf().IP(),
            self.defaultIntf().MAC()
        ))
        print ("**********")

class P4Switch(Switch):
    """P4 virtual switch with BMv2 backend and gRPC control plane interface"""
    device_id = 0
    next_grpc_port = 50051
    next_thrift_port = 9091

    def __init__(self, name, sw_path = None, json_path = None,
                 thrift_port = None,
                 grpc_port = None,
                 pcap_dump = False,
                 log_console = False,
                 verbose = False,
                 device_id = None,
                 enable_debugger = False,
                 **kwargs):
        logging.info("Initializing P4Switch: %s", name)
        logging.debug("sw_path: %s, json_path: %s, grpc_port: %s, thrift_port: %s", sw_path, json_path, grpc_port, thrift_port)
        Switch.__init__(self, name, **kwargs)
        assert (sw_path)
        self.sw_path = sw_path
        # make sure that the provided sw_path is valid
        pathCheck(sw_path)

        if json_path is not None:
            # make sure that the provided JSON file exists
            if not os.path.isfile(json_path):
                error("Invalid JSON file.\n")
                exit(1)
            self.json_path = json_path
        else:
            self.json_path = None

        if grpc_port is not None:
            self.grpc_port = grpc_port
        else:
            self.grpc_port = P4Switch.next_grpc_port
            logging.debug("Assigning grpc_port: %d", self.grpc_port)
            P4Switch.next_grpc_port += 1

        if check_listening_on_port(self.grpc_port):
            error('%s cannot bind port %d because it is bound by another process\n' % (self.name, self.grpc_port))
            exit(1)

        if thrift_port is not None:
            self.thrift_port = thrift_port
        else:
            self.thrift_port = P4Switch.next_thrift_port
            logging.debug("Assigning thrift_port: %d", self.thrift_port)
            P4Switch.next_thrift_port += 1

        if check_listening_on_port(self.thrift_port):
            error('%s cannot bind port %d because it is bound by another process\n' % (self.name, self.thrift_port))
            exit(1)

        self.verbose = verbose
        logfile = "/home/p4/other-p4/packet-aggregator-p4/l2_aggregator/logs/devices/p4s.{}.log".format(self.name)
        self.output = open(logfile, 'w')
        self.pcap_dump = pcap_dump
        self.enable_debugger = enable_debugger
        self.log_console = log_console
        if device_id is not None:
            self.device_id = device_id
            P4Switch.device_id = max(P4Switch.device_id, device_id)
        else:
            self.device_id = P4Switch.device_id
            P4Switch.device_id += 1

        self.nanomsg = "ipc:///tmp/bm-{}-log.ipc".format(self.device_id)


    def check_switch_started(self, pid):
        for _ in range(SWITCH_START_TIMEOUT * 2):
            if not os.path.exists(os.path.join("/proc", str(pid))):
                logging.warning("Process %d is either terminated or not running at all.", pid)
                return False
            if check_listening_on_port(self.grpc_port):
                return True
            sleep(0.5)

    def start(self, controllers):
        logging.info("Starting P4 switch {}.\n".format(self.name))
        args = [self.sw_path]
        for port, intf in self.intfs.items():
            if not intf.IP():
                args.extend(['-i', str(port) + "@" + intf.name])
        if self.pcap_dump:
            logging.debug("Enabling pcap dump for switch: %s", self.name)
            args.append("--pcap=/home/p4/other-p4/packet-aggregator-p4/l2_aggregator/pcap")
            logging.debug("Pcap dump enabled.")
        if self.nanomsg:
            logging.debug("Using nanomsg endpoint: %s", self.nanomsg)
            args.extend(['--nanolog', self.nanomsg])
            logging.debug("Nanomsg endpoint set up.")
        args.extend(['--device-id', str(self.device_id)])
        P4Switch.device_id += 1
        logging.debug("Assigned device_id: %d", self.device_id)
        if self.json_path:
            logging.debug("Using JSON file: %s", self.json_path)
            args.append(self.json_path)
        else:
            logging.debug("No JSON file provided. Continuing without it.")
            args.append("--no-p4")
        if self.enable_debugger:
            logging.debug("Enabling debugger for switch: %s", self.name)
            args.append("--debugger")
        if self.log_console:
            logging.debug("Enabling console logging for switch: %s", self.name)
            args.append("--log-console")
        if self.thrift_port:
            logging.debug("Using Thrift port: %d", self.thrift_port)
            args.extend(['--thrift-port', str(self.thrift_port)])
        if self.grpc_port:
            logging.debug("Using gRPC port: %d", self.grpc_port)
            args.append("-- --grpc-server-addr 0.0.0.0:" + str(self.grpc_port))
        
        cmd = ' '.join(args)
        info(cmd + "\n")

        logfile = "/home/p4/other-p4/packet-aggregator-p4/l2_aggregator/logs/devices/p4s.{}.log".format(self.name)
        pid = None
        with tempfile.NamedTemporaryFile() as f:
            self.cmd(cmd + ' >' + logfile + ' 2>&1 & echo $! >> ' + f.name)
            pid = int(f.read())
        logging.debug("P4 switch {} PID is {}.\n".format(self.name, pid))
        if not self.check_switch_started(pid):
            logging.error("P4 switch {} did not start correctly.\n".format(self.name))
            exit(1)
        logging.info("P4 switch {} has been started.\n".format(self.name))

    def stop(self):
        "Terminate P4 switch."
        self.output.flush()
        self.cmd('kill %' + self.sw_path)
        self.cmd('wait')
        self.deleteIntfs()

    def attach(self, intf):
        "Connect a data port"
        assert(0)

    def detach(self, intf):
        "Disconnect a data port"
        assert(0)
