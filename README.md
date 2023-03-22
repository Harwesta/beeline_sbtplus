# Beeline Smart Box Turbo+
Configuration files &amp; patches for Beeline Smart Box Turbo+ Openwrt firmware

This patches:
- add a new device profile "Beeline Smart Box Turbo+" router to Openwrt buil folder (tested on version 19.07.05, but can works early|later)
- activate UART3 on mt7621a - based devices
- activate UART3 as /dev/ttyS1 for interoperate with onboard EFR32MG12 Zigbee module
- activate HSDMA mode


# How to compile
For advanced users
1. Place a two files .patch and .config.sbt to your /Openwrt folder
2. Run patch
$ patch -p1 < beeline_sbtpluslus_uart3_hsdma_2021-01-25.patch
3. Open configuration tool (make menuconfig)
4. Load '.config.sbt' configuration file
5. Save a .config file
6. Reconfigure config and compile firmware as you taste.

# How to flash over stock firmware
1. Compile or download appropriate -factory.zip or -sysupgrade.bin firmware ("factory" - to switch to this firmware from any other, "sysupgrade" - to change versions of this firmware).
2. Logon to the web interface of the router using the "SuperUser" username, serial number as password (see sticker on the router).
Go "Other" - "Access Control" - "Connection Management" tab, activate "SSH Admin" and "Telnet Admin". Save the settings and click "Apply" in the top menu.
Write to USB flash drive (FAT32) alternative bootloader https://breed.hackpascal.net/r1338%20%5b2021-12-16%5d/breed-mt7621-r6220.bin and insert it into the router.
3. Logon to router with any terminal program, address 192.168.1.1, port 22 (SSH) or 23 (Telnet).
Backup you factory partition:
cat /dev/mtdblock2 > /tmp/mnt/shares/A/mtd2.bin
Write alternative bootloader
dd if=/tmp/mnt/shares/A/breed-mt7621-r6220.bin of=/dev/mtdblock0
4. Flash new firmware.
Power off router, hold on reset button and power on, release button after 5 sec. 
Logon to the bootloader web interface address 192.168.1.1 and select flash menu:
![breed](https://user-images.githubusercontent.com/65107625/226821787-6c4810f8-7868-4a75-9c87-6b333301f4e4.jpg)
Select factory firmware (do not need to unpack zip - this is done by the loader).
5. Recovery factory partition
After flashing and rebooting the router (approximately 3-4 minutes), connect to the router again, address 192.168.1.1, port 22 (SSH).
Mount USB flash drive
mount /dev/sda1 /tmp
insmod mtd-rw i_want_a_brick=1
mtd unlock factory
cd /tmp
mtd write mtd2.bin factory
6. Restart router, go to the web interface and in the menu "System" - "Backup" reset it to the factory.


Openwrt 22.03.2
---------------
1. Add support for QMI, NCM, MBIM modems with complete modeminfo, modem settings.
2. Add Adblock, Atinout, Openvpn Wireguard client, OBFS-proxy etc.

Enjoy :) 
