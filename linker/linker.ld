/**
 * FILE: linker.ld
 *
 * DESCRIPTION:
 * ESP32-C3 Minimal Linker Script for bare‑metal development.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 14, 2025
 */

MEMORY {
    iram0   (rwx)   : ORIGIN = 0x4037c000, LENGTH = 16k
    dram1    (rw)   : ORIGIN = 0x3fc80000, LENGTH = 384k
    iucache   (x)   : ORIGIN = 0x42000000, LENGTH = 8M
    ducache   (r)   : ORIGIN = 0x3C000000, LENGTH = 8M
}

ENTRY(_start)

SECTIONS {
    .text : {
        _text_start = .;
        *(.text.init)
        *(.text)
        *(.text*)
    } > iucache AT > ducache
    . = ALIGN(4);

    _text_end = .;
    _text_size = _text_end - _text_start;

    .data : {
        . = ALIGN(16);
        _data_start = .;
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        *(.rodata)
        *(.rodata*)
        . = ALIGN(16);
        _data_end = .;
    } > dram1

    _data_size = _data_end - _data_start;
    _data_loadaddr = LOADADDR(.data);

    .bss : {
        . = ALIGN(16);
        _bss_start = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        . = ALIGN(16);
        _bss_end = .;
    } > dram1

    _bss_size = _bss_end - _bss_start;
}

