BUILD_DIR = build
SRC_DIR = src
LOG_DIR = logs
LOGS_DEVICES_DIR = $(LOG_DIR)/devices
PCAP_DIR = pcap

P4C = p4c-bm2-ss
MININET = /home/p4/src/p4dev-python-venv/bin/mn
PYTHON = /home/p4/src/p4dev-python-venv/bin/python
P4C_ARGS = --p4runtime-file $(basename $@).p4info --p4runtime-format text
source := $(wildcard $(SRC_DIR)/*.p4)
P4_FILES := $(notdir $(source))

compiled_json := $(P4_FILES:%.p4=$(BUILD_DIR)/%.json)

all: build run

run:
	@echo "Running L2 Aggregator..."
	cd mininet ; sudo ./run_emu.py

build:	dirs $(compiled_json)
	@echo "Building L2 Aggregator..."
	$(P4C) --p4v 16 $(P4C_ARGS) -o $(BUILD_DIR)/l2_aggregate.json \
		--p4runtime-file $(BUILD_DIR)/l2_aggregate.p4info \
		src/aggregator/main.p4

dirs:
	mkdir -p $(BUILD_DIR) $(LOG_DIR) $(LOGS_DEVICES_DIR) $(PCAP_DIR)

stop:
	sudo $(MININET) -c

clean: stop
	rm -rf $(BUILD_DIR)

cleanall: stop
	rm -rf $(BUILD_DIR) $(LOG_DIR) $(LOGS_DEVICES_DIR) $(PCAP_DIR)