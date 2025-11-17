/*
 * FILE: wdt.s
 *
 * DESCRIPTION:
 * ESP32-C3 Bare-Metal Watchdog Timer Utilities.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 15, 2025
 * UPDATE DATE: November 15, 2025
 */

.include "inc/registers.inc"

.equ WDT_WRITE_PROTECT, 0x50D83AA1
.equ SWD_WRITE_PROTECT, 0x8F1D312A

/**
 * Initialize the .text.init section.
 * The .text.init section contains executable code.
 */
.section .text

/**
 * @brief   Feed the watchdog timer.
 *
 * @param   None
 * @retval  None
 */
.type wdt_feed, %function
wdt_feed:
  li    t0, TIMG0_WDTFEED_REG                    # load wdt feed register address
  addi  t1, t1, 1                                # increment feed counter
  sw    t1, 0(t0)                                # write feed value
  ret                                            # return
.size wdt_feed, .-wdt_feed

/**
 * @brief   Disable all watchdog timers.
 *
 * @param   None
 * @retval  None
 */
.global wdt_disable
.type wdt_disable, %function
wdt_disable:
  li    t0, TIMG0_WDTWPROTECT_REG                # timg0 write protect register
  li    t1, WDT_WRITE_PROTECT                    # load write protect key
  sw    t1, (t0)                                 # unlock write protection
  li    t0, TIMG0_WDTCONFIG0_REG                 # timg0 config register
  li    t1, 0                                    # load disable value
  sw    t1, (t0)                                 # disable timg0 watchdog
  li    t0, TIMG1_WDTWPROTECT_REG                # timg1 write protect register
  li    t1, WDT_WRITE_PROTECT                    # load write protect key
  sw    t1, (t0)                                 # unlock write protection
  li    t0, TIMG1_WDTCONFIG0_REG                 # timg1 config register
  li    t1, 0                                    # load disable value
  sw    t1, (t0)                                 # disable timg1 watchdog
  li    t0, RTC_CNTL_WDTWPROTECT_REG             # rtc write protect register
  li    t1, WDT_WRITE_PROTECT                    # load write protect key
  sw    t1, (t0)                                 # unlock write protection
  li    t0, RTC_CNTL_WDTCONFIG0_REG              # rtc config register
  li    t1, 0                                    # load disable value
  sw    t1, (t0)                                 # disable rtc watchdog
  li    t0, RTC_CNTL_SWD_WPROTECT_REG            # swd write protect register
  li    t1, SWD_WRITE_PROTECT                    # load write protect key
  sw    t1, (t0)                                 # unlock write protection
  li    t0, RTC_CNTL_SWD_CONF_REG                # swd config register
  li    t1, ((1<<31) | 0x4B00000)                # enable with auto feed
  sw    t1, (t0)                                 # write swd config
  ret                                            # return
.size wdt_disable, .-wdt_disable
