BUILD_DIR = build
SRC_DIR = src
LOG_DIR = logs
LOGS_DEVICES_DIR = $(LOG_DIR)/devices
PCAP_DIR = pcap

P4C = p4c-bm2-ss
MININET = /home/p4/src/p4dev-python-venv/bin/mn
PYTHON = /home/p4/src/p4dev-python-venv/bin/python
P4C_ARGS_AGG = --p4runtime-files $(BUILD_DIR)/l3_aggregate.p4info.txtpb --p4runtime-format text
P4C_ARGS_SPL = --p4runtime-files $(BUILD_DIR)/l3_split.p4info.txtpb --p4runtime-format text
source := $(wildcard $(SRC_DIR)/*.p4)
P4_FILES := $(notdir $(source))

compiled_json := $(P4_FILES:%.p4=$(BUILD_DIR)/%.json)

all: build run

run:
	@echo "Running L3 Aggregator..."
	cd mininet ; sudo ./run_emu.py

build_aggregator:	dirs $(compiled_json)
	@echo "Building L3 Aggregator..."
	$(P4C) --p4v 16 $(P4C_ARGS_AGG) -o $(BUILD_DIR)/l3_aggregate.json \
		src/aggregator/main.p4
	@echo "Building Succeeded..."

build_splitter:	dirs $(compiled_json)
	@echo "Building L3 Splitter..."
	$(P4C) --p4v 16 $(P4C_ARGS_SPL) -o $(BUILD_DIR)/l3_split.json \
		src/splitter/main.p4
	@echo "Building Succeeded..."\

build: build_aggregator build_splitter

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