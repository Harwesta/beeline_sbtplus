# Beeline Smart Box Turbo+
Configuration files &amp; patches for Beeline Smart Box Turbo+ Openwrt firmware

This patches:
- add a new device profile "Beeline Smart Box Turbo+" router to Openwrt buil folder (tested on version 19.07.05, but can works early|later)
- activate UART3 on mt7621a - based devices
- activate UART3 as /dev/ttyS1 for interoperate with onboard EFR32MG12 Zigbee module
- activate HSDMA mode


# How to use
- Place a two files .patch and .config.sbt to your /Openwrt folder
- Run patch
$ patch -p1 < beeline_sbtpluslus_uart3_hsdma_2021-01-25.patch
- Open configuration tool (make menuconfig)
- Load '.config.sbt' configuration file
- Save a default .config file

Enjoy :) 
