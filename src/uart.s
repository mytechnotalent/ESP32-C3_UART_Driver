/*
 * FILE: uart.s
 *
 * DESCRIPTION:
 * UART library for ESP32-C3. Supports both USB CDC and hardware UART0 (GPIO20/21).
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 16, 2025
 * UPDATE DATE: November 16, 2025
 */

.include "inc/registers.inc"

/**
 * Initialize the .text.init section.
 * The .text.init section contains executable code.
 */
.section .text

/**
 * @brief   Initialize UART hardware.
 *
 * @details Enables UART clock and configures GPIO20/21 for UART0.
 *
 * @param   None
 * @retval  None
 */
.global uart_init
.type uart_init, %function
uart_init:
  addi  sp, sp, -16                              # allocate stack frame
  sw    ra, 12(sp)                               # save return address
  li    t0, 0x600C2010                           # load SYSTEM_PERIP_CLK_EN0_REG
  lw    t1, 0(t0)                                # read current clock enable
  li    t2, 1 << 3                               # load SYSTEM_UART_CLK_EN bit
  or    t1, t1, t2                               # enable UART clock
  sw    t1, 0(t0)                                # write back to register
  li    t0, 0x60009050                           # load IO_MUX_GPIO20_REG
  lw    t1, 0(t0)                                # read current config
  li    t2, (1<<9)|(1<<8)                        # load FUN_IE | MCU_SEL[0]
  or    t1, t1, t2                               # configure GPIO20 as UART0 RX
  sw    t1, 0(t0)                                # write back to register
  li    t0, 0x60009054                           # load IO_MUX_GPIO21_REG
  lw    t1, 0(t0)                                # read current config
  li    t2, (1<<9)|(1<<8)                        # load FUN_IE | MCU_SEL[0]
  or    t1, t1, t2                               # configure GPIO21 as UART0 TX
  sw    t1, 0(t0)                                # write back to register
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.size uart_init, .-uart_init

/**
 * @brief   Read one character (blocking).
 *
 * @details Checks USB CDC first, then UART0 hardware.
 *
 * @param   None
 * @retval  a0 - Character read
 */
.global uart_getchar
.type uart_getchar, %function
uart_getchar:
  addi  sp, sp, -16                              # allocate stack frame
  sw    ra, 12(sp)                               # save return address
.uart_getchar_poll:
  jal   usb_cdc_is_read_ready                    # check USB CDC first
  bnez  a0, .uart_getchar_usb                    # branch if USB has data
  lui   t2, %hi(UART_CONTROLLER_0)               # load high part of UART base
  addi  t2, t2, %lo(UART_CONTROLLER_0)           # add low part
  lw    t3, 0x1c(t2)                             # read UART_STATUS_REG
  andi  t3, t3, 0xff                             # mask RXFIFO_CNT
  bnez  t3, .uart_getchar_uart                   # branch if UART has data
  j     .uart_getchar_poll                       # keep polling
.uart_getchar_usb:
  jal   usb_cdc_read                             # read from USB CDC
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.uart_getchar_uart:
  lw    a0, 0x0(t2)                              # read from UART_FIFO_REG
  andi  a0, a0, 0xFF                             # mask to byte
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.size uart_getchar, .-uart_getchar

/**
 * @brief   Write one character.
 *
 * @details Writes to both USB CDC and UART0.
 *
 * @param   a0 - Character to write
 * @retval  None
 */
.global uart_putchar
.type uart_putchar, %function
uart_putchar:
  addi  sp, sp, -16                              # allocate stack frame
  sw    ra, 12(sp)                               # save return address
  sw    s0, 8(sp)                                # save s0
  mv    s0, a0                                   # save character
  li    t4, 0                                    # reset USB wait counter
.uart_putchar_usb_wait_ready:
  jal   usb_cdc_is_write_ready                   # check if USB ready
  bnez  a0, .uart_putchar_usb_send               # send immediately if ready
  addi  t4, t4, 1                                # increment wait counter
  li    t5, 1000                                 # max spins before giving up
  blt   t4, t5, .uart_putchar_usb_wait_ready     # keep waiting while under limit
  j     .uart_putchar_usb_done                   # host not connected; skip USB write

.uart_putchar_usb_send:
  mv    a0, s0                                   # load character for USB
  jal   usb_cdc_write                            # write to USB CDC
  jal   usb_cdc_write_flush                      # flush USB CDC
  li    t0, 100                                  # delay counter
.uart_putchar_usb_settle:
  addi  t0, t0, -1                               # decrement
  bnez  t0, .uart_putchar_usb_settle             # loop
.uart_putchar_usb_done:
  lui   t2, %hi(UART_CONTROLLER_0)               # load high part of UART base
  addi  t2, t2, %lo(UART_CONTROLLER_0)           # add low part
.uart_putchar_wait:
  lw    t3, 0x1c(t2)                             # read UART_STATUS_REG
  li    t5, 1<<17                                # load TXFIFO_FULL bit
  and   t3, t3, t5                               # check if FIFO full
  bnez  t3, .uart_putchar_wait                   # wait if full
  sw    s0, 0(t2)                                # write to UART_FIFO_REG
  lw    s0, 8(sp)                                # restore s0
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.size uart_putchar, .-uart_putchar

/**
 * @brief   Echo loop with backspace support.
 *
 * @details Reads characters and echoes them back. Handles backspace (0x08 and 0x7F) properly.
 *
 * @param   None
 * @retval  None (never returns)
 */
.global uart_echo
.type uart_echo, %function
uart_echo:
  addi  sp, sp, -16                              # allocate stack frame
  sw    ra, 12(sp)                               # save return address
.uart_echo_loop:
  jal   uart_getchar                             # read character
  mv    s0, a0                                   # save character
  li    t0, 0x7F                                 # load DEL character
  beq   s0, t0, .uart_echo_backspace             # branch if backspace
  li    t0, 0x08                                 # load BS character
  beq   s0, t0, .uart_echo_backspace             # branch if backspace
  mv    a0, s0                                   # load character
  jal   uart_putchar                             # echo normal character
  j     .uart_echo_loop                          # continue loop
.uart_echo_backspace:
  li    a0, 0x08                                 # load backspace
  jal   usb_cdc_write                            # write to USB CDC
  li    a0, ' '                                  # load space
  jal   usb_cdc_write                            # write to USB CDC
  li    a0, 0x08                                 # load backspace
  jal   usb_cdc_write                            # write to USB CDC
  jal   usb_cdc_write_flush                      # flush all three together
  lui   t2, %hi(UART_CONTROLLER_0)               # load high part of UART base
  addi  t2, t2, %lo(UART_CONTROLLER_0)           # add low part
  li    s1, 0x08                                 # load backspace
.uart_echo_bs_wait_1:
  lw    t3, 0x1c(t2)                             # read UART_STATUS_REG
  li    t5, 1<<17                                # load TXFIFO_FULL bit
  and   t3, t3, t5                               # check if FIFO full
  bnez  t3, .uart_echo_bs_wait_1                 # wait if full
  sw    s1, 0(t2)                                # write backspace to UART
  li    s1, ' '                                  # load space
.uart_echo_bs_wait_2:
  lw    t3, 0x1c(t2)                             # read UART_STATUS_REG
  li    t5, 1<<17                                # load TXFIFO_FULL bit
  and   t3, t3, t5                               # check if FIFO full
  bnez  t3, .uart_echo_bs_wait_2                 # wait if full
  sw    s1, 0(t2)                                # write space to UART
  li    s1, 0x08                                 # load backspace
.uart_echo_bs_wait_3:
  lw    t3, 0x1c(t2)                             # read UART_STATUS_REG
  li    t5, 1<<17                                # load TXFIFO_FULL bit
  and   t3, t3, t5                               # check if FIFO full
  bnez  t3, .uart_echo_bs_wait_3                 # wait if full
  sw    s1, 0(t2)                                # write backspace to UART
  j     .uart_echo_loop                          # continue loop
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.size uart_echo, .-uart_echo

/**
 * @brief   Print null-terminated string.
 *
 * @param   a0 - Pointer to null-terminated string
 * @retval  None
 */
.global uart_print_string
.type uart_print_string, %function
uart_print_string:
  addi  sp, sp, -16                              # allocate stack frame
  sw    ra, 12(sp)                               # save return address
  sw    s0, 8(sp)                                # save s0
  mv    s0, a0                                   # save string pointer
.uart_print_loop:
  lbu   a0, 0(s0)                                # load character
  beqz  a0, .uart_print_done                     # if null, done
  jal   uart_putchar                             # send character
  addi  s0, s0, 1                                # increment pointer
  j     .uart_print_loop                         # continue
.uart_print_done:
  lw    s0, 8(sp)                                # restore s0
  lw    ra, 12(sp)                               # restore return address
  addi  sp, sp, 16                               # deallocate stack frame
  ret                                            # return to caller
.size uart_print_string, .-uart_print_string
