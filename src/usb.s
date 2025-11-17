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
