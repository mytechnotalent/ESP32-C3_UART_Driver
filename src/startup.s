/*
 * FILE: startup.s
 *
 * DESCRIPTION:
 * Minimal reset/startup stub for ESP32-C3.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 14, 2025
 */

.include "inc/registers.inc"

/**
 * Initialize the .text.init section.
 * The .text.init section contains init executable code.
 */
.section .text.init

/**
 * @brief   Reset / startup entry point.
 *
 * @details Minimal reset/startup handler used after 2nd stage
 *          bootloader. This stub sets up the stack, disables the
 *          watchdogs, and transfers control to the `main` application. 
 *          It intentionally remains small to minimize boot-time overhead.
 *
 * @param   None
 * @retval  None
 */
.global _start
.type _start, %function
_start:
  jal   wdt_disable                              # call wtd_disable
  jal   main                                     # call main
  j     .                                        # jump infinite loop if main returns
.size _start, .-_start
