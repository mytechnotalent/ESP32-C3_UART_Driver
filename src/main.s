/*
 * FILE: main.s
 *
 * DESCRIPTION:
 * Main application entry point for ESP32-C3 bare-metal RISC-V.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 17, 2025
 */

.include "inc/registers.inc"

.extern uart_init
.extern uart_echo

/**
 * @brief   Main application entry point.
 *
 * @details Initializes peripherals and enters the main application loop.
 *          Called from _start after watchdog disable and stack setup.
 *
 * @param   None
 * @retval  None
 */
.global main
.type main, %function
main:
  .p2align 2
  addi  sp, sp, -16                              # allocate stack space
  sw    ra, 12(sp)                               # save return address
  call  uart_init                                # initialize UART (USB CDC and UART0)
  call  uart_echo                                # enter echo loop (does not return)
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack space
  ret                                            # return
.size main, .-main
