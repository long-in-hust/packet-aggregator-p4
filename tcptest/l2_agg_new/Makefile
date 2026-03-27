BUILD_DIR = build
SRC_DIR = src
LOG_DIR = logs
LOGS_DEVICES_DIR = $(LOG_DIR)/devices
PCAP_DIR = pcap

P4C = p4c-bm2-ss
MININET = /home/p4/src/p4dev-python-venv/bin/mn
PYTHON = /home/p4/src/p4dev-python-venv/bin/python
P4C_ARGS_AGG = --p4runtime-files $(BUILD_DIR)/l2_aggregate.p4info.txtpb --p4runtime-format text
P4C_ARGS_SPL = --p4runtime-files $(BUILD_DIR)/l2_split.p4info.txtpb --p4runtime-format text
source := $(wildcard $(SRC_DIR)/*.p4)
P4_FILES := $(notdir $(source))

compiled_json := $(P4_FILES:%.p4=$(BUILD_DIR)/%.json)

all: build load_ctrl_plane

run_grpc:
	@echo "Running L2 Aggregator..."
	cd mininet ; sudo ./run_emu.py -b simple_switch_grpc

run:
	@echo "Running L2 Aggregator..."
	cd mininet ; sudo ./run_emu.py -j ../$(BUILD_DIR)/l2_aggregate.json,../$(BUILD_DIR)/l2_split.json -b simple_switch

build_aggregator:	dirs $(compiled_json)
	@echo "---------------------------------"
	@echo "Building L2 Aggregator..."
	$(P4C) --p4v 16 $(P4C_ARGS_AGG) -o $(BUILD_DIR)/l2_aggregate.json \
		src/aggregator/main.p4
	@echo "Building Succeeded..."

build_splitter:	dirs $(compiled_json)
	@echo "---------------------------------"
	@echo "Building L2 Splitter..."
	$(P4C) --p4v 16 $(P4C_ARGS_SPL) -o $(BUILD_DIR)/l2_split.json \
		src/splitter/main.p4
	@echo "Building Succeeded..."

build: build_aggregator build_splitter

load_ctrl_plane:
	@echo "Loading ctrl_plane..."
	$(PYTHON) ctrl_plane/ctrl_plane_agg.py --p4info $(BUILD_DIR)/l2_aggregate.p4info.txtpb \
		--bmv2-json $(BUILD_DIR)/l2_aggregate.json ; \
	$(PYTHON) ctrl_plane/ctrl_plane_split.py --p4info $(BUILD_DIR)/l2_split.p4info.txtpb \
		--bmv2-json $(BUILD_DIR)/l2_split.json

dirs:
	mkdir -p $(BUILD_DIR) $(LOG_DIR) $(LOGS_DEVICES_DIR) $(PCAP_DIR)

stop:
	sudo $(MININET) -c

cleanbuild:
	rm -rf $(BUILD_DIR)

clean: stop
	rm -rf $(BUILD_DIR)

cleanall: stop
	rm -rf $(BUILD_DIR) $(LOG_DIR) $(LOGS_DEVICES_DIR) $(PCAP_DIR)