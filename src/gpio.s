/*
 * FILE: gpio.s
 *
 * DESCRIPTION:
 * ESP32-C3 Bare-Metal GPIO Utilities.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 14, 2025
 */

.include "inc/registers.inc"

/**
 * Initialize the .text.init section.
 * The .text.init section contains executable code.
 */
.section .text

/**
 * @brief   Enable GPIO pin input by configuring IO_MUX.
 *
 * @param   a0: pin number
 * @retval  None
 */
.global gpio_input_enable
.type gpio_input_enable, %function
gpio_input_enable:
  li    t0, IO_MUX_GPIO0_REG                     # load IO_MUX base address
  slli  t1, a0, 2                                # compute pin offset
  add   t0, t0, t1                               # addr = base + offset
  li    t1, (1 << 8 | 1 << 9)                    # pull-up/pull-down mask
  sw    t1, 0(t0)                                # write to IO_MUX register
  ret                                            # return
.size gpio_input_enable, .-gpio_input_enable

/**
 * @brief   Enable GPIO pin output in GPIO_ENABLE_REG.
 *
 * @param   a0: pin number
 * @retval  None
 */
.global gpio_output_enable
.type gpio_output_enable, %function
gpio_output_enable:
  li    t0, GPIO_ENABLE_REG                      # load GPIO_ENABLE register addr
  lw    t1, 0(t0)                                # read current enable bits
  li    t2, 1                                    # constant 1
  sll   t2, t2, a0                               # shift to pin bit
  or    t1, t1, t2                               # set the pin bit
  sw    t1, 0(t0)                                # write back enable register
  ret                                            # return
.size gpio_output_enable, .-gpio_output_enable

/**
 * @brief   Select output function for a GPIO pin.
 *
 * @param   a0: pin number
 * @param   a1: function value
 * @retval  None
 */
.global gpio_output_func_select
.type gpio_output_func_select, %function
gpio_output_func_select:
  li    t0, GPIO_FUNC0_OUT_SEL_CFG_REG           # load function select base
  slli  t1, a0, 2                                # compute pin offset
  add   t0, t0, t1                               # addr = base + offset
  sw    a1, 0(t0)                                # write function selection
  ret                                            # return
.size gpio_output_func_select, .-gpio_output_func_select

/**
 * @brief   Read GPIO pin level.
 *
 * @param   a0: pin number
 * @retval  a0: 0 or 1
 */
.global gpio_read
.type gpio_read, %function
gpio_read:
  li    t0, GPIO_IN_REG                          # load GPIO input register addr
  lw    t1, 0(t0)                                # read input register
  li    t2, 1                                    # constant 1
  sll   t2, t2, a0                               # mask = 1 << pin
  and   t3, t2, t1                               # masked input bit
  li    a0, 1                                    # assume high
  beq   t3, t2, .gpio_read_ret                   # if bit set -> return 1
  li    a0, 0                                    # else set return 0
.gpio_read_ret:
  ret                                            # return
.size gpio_read, .-gpio_read

/**
 * @brief   Write GPIO pin (set or clear).
 *
 * @param   a0: pin number
 * @param   a1: value (0 clear, non-zero set)
 * @retval  None
 */
.global gpio_write
.type gpio_write, %function
gpio_write:
  li    t0, GPIO_OUT_W1TC_REG                    # default -> clear register addr
  beq   zero, a1, .gpio_write_clear              # if a1 == 0 use clear reg
  li    t0, GPIO_OUT_W1TS_REG                    # else use set register addr
.gpio_write_clear:
  li    t1, 1                                    # bitmask 1
  sll   t1, t1, a0                               # shift bit to pin
  sw    t1, 0(t0)                                # write to selected reg
  ret                                            # return
.size gpio_write, .-gpio_write

/**
 * @brief   Toggle GPIO pin (read, then write inverted).
 *
 * @param   a0: pin number
 * @retval  None
 */
.global gpio_toggle
.type gpio_toggle, %function
gpio_toggle:
  addi  sp, sp, -16                              # allocate stack space
  sw    ra, 0(sp)                                # save return address
  li    t0, GPIO_OUT_REG                         # load GPIO output register addr
  lw    t1, 0(t0)                                # read current output bits
  li    t2, 1                                    # constant 1
  sll   t2, t2, a0                               # mask = 1 << pin
  and   t3, t1, t2                               # test bit
  li    a1, 0                                    # default write value
  bne   zero, t3, .gpio_toggle_write             # if bit set branch
  li    a1, 1                                    # set write value to 1
.gpio_toggle_write:
  call  gpio_write                               # call gpio_write to update pin
  lw    ra, 0(sp)                                # restore return address
  addi  sp, sp, 16                               # deallocate stack space
  ret                                            # return
.size gpio_toggle, .-gpio_toggle
