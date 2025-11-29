<img src="https://github.com/mytechnotalent/ESP32-C3_UART_Driver/blob/main/ESP32-C3_UART_Driver.png?raw=true">

## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)
### VIDEO PROMO [HERE](https://www.youtube.com/watch?v=aD7X9sXirF8)

<br>

# ESP32-C3 UART Driver
An ESP32-C3 UART driver written entirely in RISC-V Assembler.

<br>

# Install ESP Toolchain
## Windows Installer [HERE](https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/windows-setup.html)
## Linux and macOS Installer [HERE](https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/linux-macos-setup.html)

<br>

# Hardware
## ESP32-C3 Super Mini [BUY](https://www.amazon.com/Teyleten-Robot-Development-Supermini-Bluetooth/dp/B0D47G24W3)
## USB-C to USB Cable [BUY](https://www.amazon.com/USB-Cable-10Gbps-Transfer-Controller/dp/B09WKCT26M)
## Complete Component Kit for Raspberry Pi [BUY](https://www.pishop.us/product/complete-component-kit-for-raspberry-pi)
## 10pc 25v 1000uF Capacitor [BUY](https://www.amazon.com/Cionyce-Capacitor-Electrolytic-CapacitorsMicrowave/dp/B0B63CCQ2N?th=1)
### 10% PiShop DISCOUNT CODE - KVPE_HS320548_10PC

<br>

# startup Code
```
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
```

# systimer Code 
```
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
```

# wdt Code
```
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
```

# gpio Code
```
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
```

# uart Code
```
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
```

# usb Code
```
/*
 * FILE: usb.s
 *
 * DESCRIPTION:
 * USB Serial/JTAG Controller CDC-ACM driver for ESP32-C3.
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
 * @brief   Read a byte from the USB CDC interface.
 *
 * @param   None
 * @retval  a0 - Byte read from USB
 */
.global usb_cdc_read
.type usb_cdc_read, %function
usb_cdc_read:
  li    t0, USB_SERIAL_JTAG_EP1_REG              # load USB EP1 register address
  lw    a0, 0(t0)                                # read byte from USB
  ret                                            # return to caller
.size usb_cdc_read, .-usb_cdc_read

/**
 * @brief   Check if USB CDC has data ready to read.
 *
 * @param   None
 * @retval  a0 - 0: not ready, 1: ready
 */
.global usb_cdc_is_read_ready
.type usb_cdc_is_read_ready, %function
usb_cdc_is_read_ready:
  li    t0, USB_SERIAL_JTAG_EP1_CONF_REG         # load USB EP1 config register address
  lw    a0, 0(t0)                                # read config register
  andi  a0, a0, (1<<2)                           # mask read ready bit
  srli  a0, a0, 2                                # shift to bit 0
  ret                                            # return to caller
.size usb_cdc_is_read_ready, .-usb_cdc_is_read_ready

/**
 * @brief   Write a byte to the USB CDC interface.
 *
 * @param   a0 - Byte to send
 * @retval  None
 */
.global usb_cdc_write
.type usb_cdc_write, %function
usb_cdc_write:
  li    t0, USB_SERIAL_JTAG_EP1_REG              # load USB EP1 register address
  sw    a0, 0(t0)                                # write byte to USB
  ret                                            # return to caller
.size usb_cdc_write, .-usb_cdc_write

/**
 * @brief   Check if USB CDC is ready to accept writes.
 *
 * @param   None
 * @retval  a0 - 0: not ready, 1: ready
 */
.global usb_cdc_is_write_ready
.type usb_cdc_is_write_ready, %function
usb_cdc_is_write_ready:
  li    t0, USB_SERIAL_JTAG_EP1_CONF_REG         # load USB EP1 config register address
  lw    a0, 0(t0)                                # read config register
  andi  a0, a0, (1<<1)                           # mask write ready bit
  srli  a0, a0, 1                                # shift to bit 0
  ret                                            # return to caller
.size usb_cdc_is_write_ready, .-usb_cdc_is_write_ready

/**
 * @brief   Flush the USB CDC write buffer.
 *
 * @param   None
 * @retval  None
 */
.global usb_cdc_write_flush
.type usb_cdc_write_flush, %function
usb_cdc_write_flush:
  li    t0, USB_SERIAL_JTAG_EP1_CONF_REG         # load USB EP1 config register address
  li    t1, 1                                    # load flush command
  sw    t1, 0(t0)                                # write flush command
  ret                                            # return to caller
.size usb_cdc_write_flush, .-usb_cdc_write_flush
```

# main Code 
```
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
```

<br>

# License
[Apache License 2.0](https://github.com/mytechnotalent/ESP32-C3_UART_Driver/blob/main/LICENSE)
