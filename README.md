# sbtplus
Configuration files &amp; patches for Beeline Smart Box Turbo+ Openwrt firmware

This is patches add a new device: "Beeline Smart Box Turbo+" router to Openwrt source code (tested version is 19.07.05, but can works early|later)

How to use:
- Place a two files .patch and .config.sbt to your Openwrt folder
- Run patch
   $ patch -p1 < beeline_sbtpluslus_uart3_hsdma_2021-01-25.patch
- Open configuration tool
   $ make menuconfig
- Load '.config.sbt' configuration file
- Save a default .config file

Enjoy :) 
