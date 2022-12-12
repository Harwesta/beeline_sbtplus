# Beeline Smart Box Turbo+
Configuration files &amp; patches for Beeline Smart Box Turbo+ Openwrt firmware

This patches:
- add a new device profile "Beeline Smart Box Turbo+" router to Openwrt buil folder (tested on version 19.07.05, but can works early|later)
- activate UART3 on mt7621a - based devices
- activate UART3 as /dev/ttyS1 for interoperate with onboard EFR32MG12 Zigbee module
- activate HSDMA mode


# How to use
For advanced users
1. Place a two files .patch and .config.sbt to your /Openwrt folder
2. Run patch
$ patch -p1 < beeline_sbtpluslus_uart3_hsdma_2021-01-25.patch
3. Open configuration tool (make menuconfig)
4. Load '.config.sbt' configuration file
5. Save a .config file


For others
1. Download appropriate -factory.zip or -sysupgrade.bin firmware.
2. Check partiton table on your router
patrtition start size
u-boot 0x0-0x100000, 
SC PART_MAP 0x100000-0x100000,
kernel 0x200000-0x400000,
ubi 0x600000-0x7800000,
factory 0x7e00000-0x100000

3. Flash firmware.
4. Reset to factory defaults.

Openwrt 22.03.2
---------------
1. Add support for QMI, NCM, MBIM modems with complete modeminfo, modem settings.
2. Add Adblock, Atinout, Openvpn Wireguard client, OBFS-proxy etc.

Enjoy :) 
