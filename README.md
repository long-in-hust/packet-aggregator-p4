# P4 Switch program - Packet aggregation simulation
---
The folder structure of this program is as follows:\
|\
\_ l2_aggregator - code for Datalink-Layer-Based packet aggregation and splitting code\
|  |_ controller: control plane code\
|  |_ mininet: code for emulated network topology deployment\
|  |_ src: P4 source code that will be compiled for BMv2\
|  |  |_ aggregator: source code for the aggregator switch\
|  |  |_ splitter: source code for the splitter switch\
|  |\
|  |_ test: unused\
|  |_ Makefile\
|\
|_ l3_aggregator\
   |\
   ... Same structure as l2_aggregator - code for Network-Layer-Based packet aggregation and splitting code\
