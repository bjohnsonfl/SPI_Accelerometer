# SPI Accelerometer

This repository contains a Master SPI (Serial Peripheral Interface) entity and an ADXL345 driver entity which work in tandem to configure, calibrate, read, and display accelerometer data.

## Background on this repository

Recently I have been interested in IMU's and the history of GNC systems in aerospace which led me to experiment with sensors. I have a [DE10-Lite Board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=234&No=1021&PartNo=1) that has an Altera MAX10 FPGA and an ADXL345 Accelerometer. The sensor has an I2C and a SPI bus to communiate with, but the FPGA has neither which means I had to pick one to develop a master component for. I chose SPI due to its higher speed and general interest in the protocol. The ADXL345 driver configures and calibrates the sensor after reset. All the code for these two entities were written in VHDL, simulated with test benches, and is synthesizable. 

## How to use this repository

This project is divided into a SPI Master and ADXL345 driver, where the SPI entity is completely independent of the driver. The two communicate via the top_level entity, which means the SPI Master can be used in any other project. The ADXL345 driver listens for byte signals from the SPI Master which are unique to my implementation. This means that using the driver with other SPI implementations will require modifications.  

### File List

Files      | Descriptions 
---|---
[accel_driver](./accel_driver.vhd) | Configures sensor functionality, calibrates sensor, reads and writes to sensor on command and external interrupts
[clock_div](./clock_div.vhd) | Generates spi clock signal on command for x amount of bytes and raises flag per byte transaction
[clock_div_tb](./clock_div_tb.vhd) | Test bench for clock_div.vhd
[decoder7seg](./decoder7seg.vhd) | Converts nibbles to active low 7 segment displays on the board
[spi_master](./spi_master.vhd) | Initiate transactions, controls data and cs lines, takes in transmit data, returns receive data
[spi_master_tb](./spi_master_tb.vhd) | Test bench for spi_master.vhd
[top_level](./top_level.vhd) | Top level entity used for accel_driver and spi_master to interact as well as external signals to the ADXL345 sensor, switches, and 7 segment display
[top_level_tb](./top_level_tb.vhd) | Test bench for top_level.vhd