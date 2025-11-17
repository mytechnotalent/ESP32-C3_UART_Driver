# 
# FILE: Makefile
# 
# DESCRIPTION:
# ESP32-C3 Minimal Makefile for bare‑metal development.
# 
# AUTHOR: Kevin Thomas
# CREATION DATE: November 14, 2025
# UPDATE DATE: November 14, 2025
# 

CROSS ?= riscv32-esp-elf-
AS := $(CROSS)as
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy

ASFLAGS ?= -g -march=rv32imc -mabi=ilp32

SRCDIR := src
BUILDDIR := build

LDFLAGS ?= -g -T linker/linker.ld -Map $(BUILDDIR)/main.map

SRCS := $(wildcard $(SRCDIR)/*.s)
OBJS := $(patsubst $(SRCDIR)/%.s,$(BUILDDIR)/%.o,$(SRCS))

ESPTOOL ?= esptool.py
CHIP ?= esp32c3
PORT ?= /dev/tty.usbmodem3101
CHIP_DIR ?= .
MAIN_BIN := $(BUILDDIR)/main.bin
MAIN_E2I := $(BUILDDIR)/main.e2i

OPENOCD ?= openocd
OPENOCD_ARGS ?= -f board/esp32c3-builtin.cfg

GDB := ~/.espressif/tools/riscv32-esp-elf-gdb/16.2_20250324/riscv32-esp-elf-gdb/bin/riscv32-esp-elf-gdb-no-python

.PHONY: all clean flash flash_partboot flash_raw gdb openocd

all: $(BUILDDIR)/main.elf

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/%.o: $(SRCDIR)/%.s | $(BUILDDIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILDDIR)/main.elf: $(OBJS) | $(BUILDDIR)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(BUILDDIR)/main.bin: $(BUILDDIR)/main.elf
	$(OBJCOPY) -O binary $< $@

$(BUILDDIR)/main.e2i: $(BUILDDIR)/main.elf
	@echo "Generating ELF2IMAGE -> $@"
	# Pass explicit --chip to avoid esptool mis-detection (esp8266 vs esp32)
	$(ESPTOOL) --chip $(CHIP) elf2image $< -o $@ --flash_mode dio --flash_freq 80m --flash_size 4MB

clean:
	rm -rf $(BUILDDIR)/*

flash: all $(BUILDDIR)/main.e2i
	@echo "Flashing bootloader, partitions and app to $(PORT)"
	$(MAKE) flash_partboot

flash_partboot: all $(BUILDDIR)/main.e2i
	@test -f $(CHIP_DIR)/bootloader/bootloader.bin || (echo "ERROR: missing bootloader.bin in $(CHIP_DIR)/bootloader"; exit 1)
	@test -f $(CHIP_DIR)/partition/partitions.bin || (echo "ERROR: missing partitions.bin in $(CHIP_DIR)/partition"; exit 1)
	$(ESPTOOL) --chip $(CHIP) --port $(PORT) write_flash 0x0 $(CHIP_DIR)/bootloader/bootloader.bin 0x8000 $(CHIP_DIR)/partition/partitions.bin 0x10000 $(MAIN_E2I)

flash_raw: all $(BUILDDIR)/main.e2i
ifeq ($(DANGEROUS),1)
	@echo "DANGEROUS: flashing $(MAIN_E2I) to 0x0"
	$(ESPTOOL) --chip $(CHIP) --port $(PORT) write_flash 0x0 $(MAIN_E2I)
else
	$(error To use raw flash set DANGEROUS=1: make flash_raw DANGEROUS=1)
endif

gdb: all $(BUILDDIR)/main.elf
	@echo "Starting GDB (no-python) and connecting to :3333"
	$(GDB) -q $(BUILDDIR)/main.elf \
		-ex "target extended-remote :3333" \
		-ex "set remote hardware-watchpoint-limit 2" \
		-ex "monitor reset halt" \
		-ex "maintenance flush register-cache" \
		-ex "set confirm off" \
		-ex "hb main"

openocd:
	@echo "Starting OpenOCD: $(OPENOCD) $(OPENOCD_ARGS)"
	$(OPENOCD) $(OPENOCD_ARGS)
