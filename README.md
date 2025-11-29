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

# main.s Code
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
