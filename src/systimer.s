/*
 * FILE: systimer.s
 *
 * DESCRIPTION:
 * ESP32-C3 Systimer Delay Functions.
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
 * @brief   Get the current systimer systick value.
 *
 * @details Reads the systimer unit 0 value register after updating.
 *
 * @param   None
 * @retval  a0: current systick value
 */
.type systimer_systick_get, %function
systimer_systick_get:
  li    t0, SYSTIMER_UNIT0_OP_REG                # read UNIT0 value to registers 
  li    t1, (1<<30)                              # SYSTIMER_TIMER_UNIT0_UPDATE
  sw    t1, 0(t0)                                # write update to SYSTIMER_UNIT0_OP_REG
  li    t0, SYSTIMER_UNIT0_VALUE_LO_REG          # UNIT0 value, low 32 bits 
  lw    a0, 0(t0)                                # load systick value
  ret                                            # return
.size systimer_systick_get, .-systimer_systick_get

/**
 * @brief   Delay for a specified number of systicks.
 *
 * @details Implements a busy-wait delay using systimer.
 *
 * @param   a0: delay in systicks
 * @retval  None
 */
.type delay_systicks, %function
delay_systicks:
  addi  sp, sp, -16                              # allocate stack space
  sw    ra, 0(sp)                                # save return address
  sw    s0, 8(sp)                                # save s0 (callee-saved)
  sw    a0, 4(sp)                                # save delay value
  jal   systimer_systick_get                     # get current systick
  mv    s0, a0                                   # store time #1 in s0
  lw    t1, 4(sp)                                # load delay value
  add   s0, s0, t1                               # compute expiry = time#1 + delay
.delay_systicks_delay_loop:
  jal   systimer_systick_get                     # get current systick
  blt   a0, s0, .delay_systicks_delay_loop       # loop if not elapsed
  lw    s0, 8(sp)                                # restore s0
  lw    ra, 0(sp)                                # restore return address
  addi  sp, sp, 16                               # deallocate stack space
  ret                                            # return
.size delay_systicks, .-delay_systicks

/**
 * @brief   Delay for a specified number of microseconds.
 *
 * @details Converts microseconds to systicks and calls delay_systicks.
 *
 * @param   a0: delay in µs
 * @retval  None
 */
.global delay_us
.type delay_us, %function
delay_us:
  addi  sp, sp, -16                              # allocate stack space
  sw    ra, 0(sp)                                # save return address
  li    t0, 16                                   # 16MHz clock, 16 ticks per µs
  mul   a0, a0, t0                               # convert µs to systicks
  jal   delay_systicks                           # call delay function
  lw    ra, 0(sp)                                # restore return address
  addi  sp, sp, 16                               # deallocate stack space
  ret                                            # return
.size delay_us, .-delay_us

/**
 * @brief   Delay for a specified number of milliseconds.
 *
 * @details Converts milliseconds to systicks and calls delay_systicks.
 *
 * @param   a0: delay in ms
 * @retval  None
 */
.global delay_ms
.type delay_ms, %function
delay_ms:
  addi  sp, sp, -16                              # allocate stack space
  sw    ra, 0(sp)                                # save return address
  li    t0, 16000                                # 16MHz clock, 16000 ticks per ms
  mul   a0, a0, t0                               # convert µs to systicks
  jal   delay_systicks                           # call delay function
  lw    ra, 0(sp)                                # restore return address
  addi  sp, sp, 16                               # deallocate stack space
  ret                                            # return
.size delay_ms, .-delay_ms
