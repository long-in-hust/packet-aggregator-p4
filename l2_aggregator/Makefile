BUILD_DIR = build

P4C = p4c-bm2-ss
P4C_ARGS = --p4runtime-file $(basename $@).p4info --p4runtime-format text
source := $(wildcard *.p4)

outfile := $(source:.p4=.json)

compiled_json := $(BUILD_DIR)/$(outfile)

all: build run

run:
	@echo "Running L2 Aggregator..."
	# Add commands to run the L2 Aggregator here

build:	dirs $(compiled_json)
	
$(BUILD_DIR)/%.json: %.p4
	$(P4C) --p4v 16 $(P4C_ARGS) -o $@ $<

dirs:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)