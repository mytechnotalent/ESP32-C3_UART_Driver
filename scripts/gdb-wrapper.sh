#!/bin/bash

# Wrapper script to source ESP-IDF environment before running GDB
. "$HOME/esp/esp-idf/export.sh" > /dev/null 2>&1
exec "$HOME/.espressif/tools/riscv32-esp-elf-gdb/16.2_20250324/riscv32-esp-elf-gdb/bin/riscv32-esp-elf-gdb-no-python" -q "$@"
