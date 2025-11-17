/**
 * FILE: registers.inc
 *
 * DESCRIPTION:
 * ESP32-C3 Register Definitions for bare‑metal development.
 *
 * AUTHOR: Kevin Thomas
 * CREATION DATE: November 14, 2025
 * UPDATE DATE: November 14, 2025
 */

# System Control and Timer Registers
.equ RTC_CNTL_WDTCONFIG0_REG,        0x60008090
.equ RTC_CNTL_WDTWPROTECT_REG,       0x600080A8
.equ RTC_CNTL_SWD_CONF_REG,          0x600080AC
.equ RTC_CNTL_SWD_WPROTECT_REG,      0x600080B0

# System Timer Registers
.equ SYSTIMER_CONF_REG,              0x60023000
.equ SYSTIMER_UNIT0_OP_REG,          0x60023004
.equ SYSTIMER_UNIT0_VALUE_LO_REG,    0x60023044

# Timer Group 0 and 1 Registers
.equ TIMG0_WDTFEED_REG,              0x6001F060
.equ TIMG0_WDTWPROTECT_REG,          0x6001F064
.equ TIMG0_WDTCONFIG0_REG,           0x6001F048
.equ TIMG1_WDTCONFIG0_REG,           0x60020048
.equ TIMG1_WDTWPROTECT_REG,          0x60020064

# UART Controller 0 Register
.equ UART_CONTROLLER_0,              0x60000000

# USB Serial JTAG Registers
.equ USB_SERIAL_JTAG_EP1_REG,        0x60043000
.equ USB_SERIAL_JTAG_EP1_CONF_REG,   0x60043004

# GPIO Registers
.equ GPIO_OUT_REG,                   0x60004004
.equ GPIO_OUT_W1TS_REG,              0x60004008
.equ GPIO_OUT_W1TC_REG,              0x6000400C
.equ GPIO_ENABLE_REG,                0x60004020
.equ GPIO_ENABLE_W1TS_REG,           0x60004024
.equ GPIO_ENABLE_W1TC_REG,           0x60004028
.equ GPIO_IN_REG,                    0x6000403C
.equ GPIO_FUNC0_OUT_SEL_CFG_REG,     0x60004554

# IO MUX Registers
.equ IO_MUX_GPIO0_REG,               0x60009004
.equ IO_MUX_GPIO1_REG,               0x60009008
