#!/bin/bash

# Copyright (c) 2025 Kevin Thomas
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# OpenOCD Wrapper Script
# Sources ESP-IDF environment before running OpenOCD for ESP32-C3 debugging

. "$HOME/esp/esp-idf/export.sh" > /dev/null 2>&1
exec openocd -f board/esp32c3-builtin.cfg "$@"