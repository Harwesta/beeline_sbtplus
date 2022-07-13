#
# MT7621 Profiles
#

include ./common-tp-link.mk

DEFAULT_SOC := mt7621

KERNEL_DTB += -d21
DEVICE_VARS += ELECOM_HWNAME LINKSYS_HWNAME

define Build/elecom-wrc-gs-factory
	$(eval product=$(word 1,$(1)))
	$(eval version=$(word 2,$(1)))
	$(eval hash_opt=$(word 3,$(1)))
	$(STAGING_DIR_HOST)/bin/mkhash md5 $(hash_opt) $@ >> $@
	( \
		echo -n "ELECOM $(product) v$(version)" | \
			dd bs=32 count=1 conv=sync; \
		dd if=$@; \
	) > $@.new
	mv $@.new $@
endef

define Build/gemtek-trailer
	printf "%s%08X" ".GEMTEK." "$$(cksum $@ | cut -d ' ' -f1)" >> $@
endef

define Build/iodata-factory
	$(eval fw_size=$(word 1,$(1)))
	$(eval fw_type=$(word 2,$(1)))
	$(eval product=$(word 3,$(1)))
	$(eval factory_bin=$(word 4,$(1)))
	if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(fw_size)" ]; then \
		$(CP) $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) $(factory_bin); \
		$(STAGING_DIR_HOST)/bin/mksenaofw \
			-r 0x30a -p $(product) -t $(fw_type) \
			-e $(factory_bin) -o $(factory_bin).new; \
		mv $(factory_bin).new $(factory_bin); \
		$(CP) $(factory_bin) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

define Build/iodata-mstc-header
	( \
		data_size_crc="$$(dd if=$@ ibs=64 skip=1 2>/dev/null | gzip -c | \
			tail -c 8 | od -An -tx8 --endian little | tr -d ' \n')"; \
		echo -ne "$$(echo $$data_size_crc | sed 's/../\\x&/g')" | \
			dd of=$@ bs=8 count=1 seek=7 conv=notrunc 2>/dev/null; \
	)
	dd if=/dev/zero of=$@ bs=4 count=1 seek=1 conv=notrunc 2>/dev/null
	( \
		header_crc="$$(dd if=$@ bs=64 count=1 2>/dev/null | gzip -c | \
			tail -c 8 | od -An -N4 -tx4 --endian little | tr -d ' \n')"; \
		echo -ne "$$(echo $$header_crc | sed 's/../\\x&/g')" | \
			dd of=$@ bs=4 count=1 seek=1 conv=notrunc 2>/dev/null; \
	)
endef

define Build/ubnt-erx-factory-image
	if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(KERNEL_SIZE)" ]; then \
		echo '21001:7' > $(1).compat; \
		$(TAR) -cf $(1) --transform='s/^.*/compat/' $(1).compat; \
		\
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp/' $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE); \
		mkhash md5 $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp.md5/' $(1).md5; \
		\
		echo "dummy" > $(1).rootfs; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp/' $(1).rootfs; \
		\
		mkhash md5 $(1).rootfs > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp.md5/' $(1).md5; \
		\
		echo '$(BOARD) $(VERSION_CODE) $(VERSION_NUMBER)' > $(1).version; \
		$(TAR) -rf $(1) --transform='s/^.*/version.tmp/' $(1).version; \
		\
		$(CP) $(1) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

define Build/zytrx-header
	$(eval board=$(word 1,$(1)))
	$(eval version=$(word 2,$(1)))
	$(STAGING_DIR_HOST)/bin/zytrx -B '$(board)' -v '$(version)' -i $@ -o $@.new
	mv $@.new $@
endef

define Device/dsa-migration
  DEVICE_COMPAT_VERSION := 1.1
  DEVICE_COMPAT_MESSAGE := Config cannot be migrated from swconfig to DSA
endef

define Device/asus_rt-ac57u
  $(Device/dsa-migration)
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := RT-AC57U
  IMAGE_SIZE := 16064k
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += asus_rt-ac57u

define Device/asus_rt-ac65p
  $(Device/dsa-migration)
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := RT-AC65P
  IMAGE_SIZE := 51200k
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGES += factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | \
	check-size
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7615e kmod-mt7615-firmware uboot-envtools
endef
TARGET_DEVICES += asus_rt-ac65p

define Device/asus_rt-ac85p
  $(Device/dsa-migration)
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := RT-AC85P
  IMAGE_SIZE := 51200k
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGES += factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | \
	check-size
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7615e kmod-mt7615-firmware uboot-envtools
endef
TARGET_DEVICES += asus_rt-ac85p

define Device/asus_rt-n56u-b1
  $(Device/dsa-migration)
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := RT-N56U
  DEVICE_VARIANT := B1
  IMAGE_SIZE := 16064k
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += asus_rt-n56u-b1

define Device/mediatek_ap-mt7621a-v60
  $(Device/dsa-migration)
  IMAGE_SIZE := 7872k
  DEVICE_VENDOR := Mediatek
  DEVICE_MODEL := AP-MT7621A-V60 EVB
  DEVICE_PACKAGES := kmod-usb3 kmod-sdhci-mt7620 kmod-sound-mt7620 -wpad-basic-wolfssl
endef
TARGET_DEVICES += mediatek_ap-mt7621a-v60

define Device/mediatek_mt7621-eval-board
  $(Device/dsa-migration)
  BLOCKSIZE := 64k
  IMAGE_SIZE := 15104k
  DEVICE_VENDOR := MediaTek
  DEVICE_MODEL := MT7621 EVB
  DEVICE_PACKAGES := -wpad-basic-wolfssl
  SUPPORTED_DEVICES += mt7621
endef
TARGET_DEVICES += mediatek_mt7621-eval-board

define Device/MikroTik
  $(Device/dsa-migration)
  DEVICE_VENDOR := MikroTik
  BLOCKSIZE := 64k
  IMAGE_SIZE := 16128k
  DEVICE_PACKAGES := kmod-usb3
  KERNEL_NAME := vmlinuz
  KERNEL := kernel-bin | append-dtb-elf
  IMAGE/sysupgrade.bin := append-kernel | kernel2minor -s 1024 | \
	pad-to $$$$(BLOCKSIZE) | append-rootfs | pad-rootfs | append-metadata | \
	check-size
endef

define Device/mikrotik_routerboard-750gr3
  $(Device/MikroTik)
  DEVICE_MODEL := RouterBOARD 750Gr3
  DEVICE_PACKAGES += -wpad-basic-wolfssl
  SUPPORTED_DEVICES += mikrotik,rb750gr3
endef
TARGET_DEVICES += mikrotik_routerboard-750gr3

define Device/mikrotik_routerboard-760igs
  $(Device/MikroTik)
  DEVICE_MODEL := RouterBOARD 760iGS
  DEVICE_PACKAGES += kmod-sfp -wpad-basic-wolfssl
endef
TARGET_DEVICES += mikrotik_routerboard-760igs

define Device/mikrotik_routerboard-m11g
  $(Device/MikroTik)
  DEVICE_MODEL := RouterBOARD M11G
  DEVICE_PACKAGES := -wpad-basic-wolfssl
  SUPPORTED_DEVICES += mikrotik,rbm11g
endef
TARGET_DEVICES += mikrotik_routerboard-m11g

define Device/mikrotik_routerboard-m33g
  $(Device/MikroTik)
  DEVICE_MODEL := RouterBOARD M33G
  DEVICE_PACKAGES := -wpad-basic-wolfssl
  SUPPORTED_DEVICES += mikrotik,rbm33g
endef
TARGET_DEVICES += mikrotik_routerboard-m33g

define Device/beeline_sbtplus
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  DEVICE_MODEL := Beeline Smart Box Turbo+
  UBINIZE_OPTS := -E 5
  SERCOMM_HWID := CHJ
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0052
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 40960k
  IMAGES += kernel.bin rootfs.bin factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := pad-extra 2048k | append-kernel | pad-to 6144k | \
	append-ubi | pad-to $$$$(BLOCKSIZE) | sercom-footer | pad-to 128 | \
	zip $$$$(SERCOMM_HWNAME).bin | sercom-seal
  IMAGE/kernel.bin := append-kernel
  IMAGE/rootfs.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e kmod-usb3 \
	kmod-usb-ledtrig-usbport kmod-mt7615-firmware
endef
TARGET_DEVICES += beeline_sbtplus

define Device/beeline_sbtplusspi
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_MODEL := Beeline Smart Box Turbo+ SPI
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e kmod-usb3 \
	kmod-usb-ledtrig-usbport kmod-mt7615-firmware
endef
TARGET_DEVICES += beeline_sbtplusspi

define Device/beeline_sbgiga
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  DEVICE_MODEL := Beeline Smart Box Giga
  UBINIZE_OPTS := -E 5
  SERCOMM_HWID := CHJ
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0052
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 40960k
  IMAGES += kernel.bin rootfs.bin factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := pad-extra 2048k | append-kernel | pad-to 6144k | \
	append-ubi | pad-to $$$$(BLOCKSIZE) | sercom-footer | pad-to 128 | \
	zip $$$$(SERCOMM_HWNAME).bin | sercom-seal
  IMAGE/kernel.bin := append-kernel
  IMAGE/rootfs.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e kmod-usb3 \
	kmod-usb-ledtrig-usbport kmod-mt7663-firmware-ap
endef
TARGET_DEVICES += beeline_sbgiga

define Device/beeline_sbgigaspi
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_MODEL := Beeline Smart Box Giga SPI
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e kmod-usb3 \
	kmod-usb-ledtrig-usbport kmod-mt7663-firmware-ap
endef
TARGET_DEVICES += beeline_sbgigaspi

define Device/netgear_ex6150
  $(Device/dsa-migration)
  DEVICE_VENDOR := NETGEAR
  DEVICE_MODEL := EX6150
  DEVICE_PACKAGES := kmod-mt76x2
  NETGEAR_BOARD_ID := U12H318T00_NETGEAR
  IMAGE_SIZE := 14848k
  IMAGES += factory.chk
  IMAGE/factory.chk := $$(sysupgrade_bin) | check-size | netgear-chk
endef
TARGET_DEVICES += netgear_ex6150

define Device/netgear_sercomm_nand
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  UBINIZE_OPTS := -E 5
  IMAGES += factory.img kernel.bin rootfs.bin
  IMAGE/factory.img := pad-extra 2048k | append-kernel | pad-to 6144k | \
	append-ubi | pad-to $$$$(BLOCKSIZE) | sercom-footer | pad-to 128 | \
	zip $$$$(SERCOMM_HWNAME).bin | sercom-seal
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/kernel.bin := append-kernel
  IMAGE/rootfs.bin := append-ubi | check-size
  DEVICE_VENDOR := NETGEAR
  DEVICE_PACKAGES := kmod-mt7603 kmod-usb3 kmod-usb-ledtrig-usbport
endef

define Device/netgear_r6220
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6220
  SERCOMM_HWNAME := R6220
  SERCOMM_HWID := AYA
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0086
  IMAGE_SIZE := 28672k
  DEVICE_PACKAGES += kmod-mt76x2
  SUPPORTED_DEVICES += r6220
endef
TARGET_DEVICES += netgear_r6220

define Device/netgear_r6260
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6260
  SERCOMM_HWNAME := R6260
  SERCOMM_HWID := CHJ
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0052
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_r6260

define Device/netgear_r6350
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6350
  SERCOMM_HWNAME := R6350
  SERCOMM_HWID := CHJ
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0052
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_r6350

define Device/netgear_r6700-v2
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6700
  DEVICE_VARIANT := v2
  DEVICE_ALT0_VENDOR := NETGEAR
  DEVICE_ALT0_MODEL := Nighthawk AC2400
  DEVICE_ALT0_VARIANT := v1
  DEVICE_ALT1_VENDOR := NETGEAR
  DEVICE_ALT1_MODEL := R7200
  DEVICE_ALT1_VARIANT := v1
  SERCOMM_HWNAME := R6950
  SERCOMM_HWID := BZV
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x1032
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_r6700-v2

define Device/netgear_r6800
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6800
  SERCOMM_HWNAME := R6950
  SERCOMM_HWID := BZV
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0062
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_r6800

define Device/netgear_r6850
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := R6850
  SERCOMM_HWNAME := R6850
  SERCOMM_HWID := CHJ
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0052
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_r6850

define Device/netgear_wac104
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := WAC104
  SERCOMM_HWNAME := WAC104
  SERCOMM_HWID := CAY
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x0006
  IMAGE_SIZE := 28672k
  DEVICE_PACKAGES += kmod-mt76x2
endef
TARGET_DEVICES += netgear_wac104

define Device/netgear_wac124
  $(Device/netgear_sercomm_nand)
  DEVICE_MODEL := WAC124
  SERCOMM_HWNAME := WAC124
  SERCOMM_HWID := CTL
  SERCOMM_HWVER := A003
  SERCOMM_SWVER := 0x0402
  IMAGE_SIZE := 40960k
  DEVICE_PACKAGES += kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += netgear_wac124

define Device/netgear_wndr3700-v5
  $(Device/dsa-migration)
  $(Device/netgear_sercomm_nor)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 15232k
  DEVICE_MODEL := WNDR3700
  DEVICE_VARIANT := v5
  SERCOMM_HWNAME := WNDR3700v5
  SERCOMM_HWID := AYB
  SERCOMM_HWVER := A001
  SERCOMM_SWVER := 0x1054
  SERCOMM_PAD := 320k
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += wndr3700v5
endef
TARGET_DEVICES += netgear_wndr3700-v5

define Device/netis_wf2881
  $(Device/dsa-migration)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  FILESYSTEMS := squashfs
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 129280k
  UBINIZE_OPTS := -E 5
  UIMAGE_NAME := WF2881_0.0.00
  KERNEL_INITRAMFS := $(KERNEL_DTB) | netis-tail WF2881 | uImage lzma
  IMAGES += factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := append-kernel | pad-to $$$$(KERNEL_SIZE) | append-ubi | \
	check-size
  DEVICE_VENDOR := NETIS
  DEVICE_MODEL := WF2881
  DEVICE_PACKAGES := kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += netis_wf2881

define Device/sercomm_na502
  $(Device/uimage-lzma-loader)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 20480k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  UBINIZE_OPTS := -E 5
  KERNEL_SIZE := 4096k
  DEVICE_VENDOR := SERCOMM
  DEVICE_MODEL := NA502
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603 kmod-usb3
endef
TARGET_DEVICES += sercomm_na502

define Device/totolink_a7000r
  $(Device/dsa-migration)
  IMAGE_SIZE := 16064k
  UIMAGE_NAME := C8340R1C-9999
  DEVICE_VENDOR := TOTOLINK
  DEVICE_MODEL := A7000R
  DEVICE_PACKAGES := kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += totolink_a7000r

define Device/totolink_x5000r
  $(Device/dsa-migration)
  IMAGE_SIZE := 16064k
  UIMAGE_NAME := C8343R-9999
  DEVICE_VENDOR := TOTOLINK
  DEVICE_MODEL := X5000R
  DEVICE_PACKAGES := kmod-mt7915e
endef
TARGET_DEVICES += totolink_x5000r

define Device/tplink_archer-a6-v3
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := Archer A6
  DEVICE_VARIANT := V3
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e \
	kmod-mt7663-firmware-ap kmod-mt7663-firmware-sta
  TPLINK_BOARD_ID := ARCHER-A6-V3
  KERNEL := $(KERNEL_DTB) | uImage lzma
  IMAGE_SIZE := 15744k
endef
TARGET_DEVICES += tplink_archer-a6-v3

define Device/tplink_archer-c6u-v1
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := Archer C6U
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-mt7603 \
	kmod-mt7615e kmod-mt7663-firmware-ap \
	kmod-usb3 kmod-usb-ledtrig-usbport
  KERNEL := $(KERNEL_DTB) | uImage lzma
  TPLINK_BOARD_ID := ARCHER-C6U-V1
  IMAGE_SIZE := 15744k
endef
TARGET_DEVICES += tplink_archer-c6u-v1

define Device/tplink_eap235-wall-v1
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := EAP235-Wall
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e kmod-mt7663-firmware-ap
  TPLINK_BOARD_ID := EAP235-WALL-V1
  IMAGE_SIZE := 13440k
  IMAGE/factory.bin := append-rootfs | tplink-safeloader factory | \
	pad-extra 128
endef
TARGET_DEVICES += tplink_eap235-wall-v1

define Device/tplink_re350-v1
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := RE350
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2
  TPLINK_BOARD_ID := RE350-V1
  IMAGE_SIZE := 6016k
  SUPPORTED_DEVICES += re350-v1
endef
TARGET_DEVICES += tplink_re350-v1

define Device/tplink_re500-v1
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := RE500
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-mt7615e kmod-mt7615-firmware
  TPLINK_BOARD_ID := RE500-V1
  IMAGE_SIZE := 14208k
endef
TARGET_DEVICES += tplink_re500-v1

define Device/tplink_re650-v1
  $(Device/dsa-migration)
  $(Device/tplink-safeloader)
  DEVICE_MODEL := RE650
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := kmod-mt7615e kmod-mt7615-firmware
  TPLINK_BOARD_ID := RE650-V1
  IMAGE_SIZE := 14208k
endef
TARGET_DEVICES += tplink_re650-v1

define Device/ubnt_edgerouter_common
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  DEVICE_VENDOR := Ubiquiti
  IMAGE_SIZE := 256768k
  FILESYSTEMS := squashfs
  KERNEL_SIZE := 3145728
  KERNEL_INITRAMFS := $$(KERNEL) | \
	ubnt-erx-factory-image $(KDIR)/tmp/$$(KERNEL_INITRAMFS_PREFIX)-factory.tar
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES += -wpad-basic-wolfssl
endef

define Device/ubnt_edgerouter-x
  $(Device/ubnt_edgerouter_common)
  DEVICE_MODEL := EdgeRouter X
  SUPPORTED_DEVICES += ubnt-erx ubiquiti,edgerouterx
endef
TARGET_DEVICES += ubnt_edgerouter-x

define Device/ubnt_edgerouter-x-sfp
  $(Device/ubnt_edgerouter_common)
  DEVICE_MODEL := EdgeRouter X SFP
  DEVICE_PACKAGES += kmod-i2c-algo-pca kmod-gpio-pca953x kmod-sfp
  SUPPORTED_DEVICES += ubnt-erx-sfp ubiquiti,edgerouterx-sfp
endef
TARGET_DEVICES += ubnt_edgerouter-x-sfp

define Device/ubnt_unifi-6-lite
  $(Device/dsa-migration)
  DEVICE_VENDOR := Ubiquiti
  DEVICE_MODEL := UniFi 6 Lite
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt7915e
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  IMAGE_SIZE := 15424k
endef
TARGET_DEVICES += ubnt_unifi-6-lite

define Device/ubnt_unifi-nanohd
  $(Device/dsa-migration)
  DEVICE_VENDOR := Ubiquiti
  DEVICE_MODEL := UniFi nanoHD
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt7615e kmod-mt7615-firmware
  IMAGE_SIZE := 15552k
endef
TARGET_DEVICES += ubnt_unifi-nanohd

define Device/unielec_u7621-01-16m
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := UniElec
  DEVICE_MODEL := U7621-01
  DEVICE_VARIANT := 16M
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3
endef
TARGET_DEVICES += unielec_u7621-01-16m

define Device/unielec_u7621-06-16m
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := UniElec
  DEVICE_MODEL := U7621-06
  DEVICE_VARIANT := 16M
  DEVICE_PACKAGES := kmod-ata-ahci kmod-sdhci-mt7620 kmod-usb3 -wpad-basic-wolfssl
  SUPPORTED_DEVICES += u7621-06-256M-16M unielec,u7621-06-256m-16m
endef
TARGET_DEVICES += unielec_u7621-06-16m

define Device/xiaomi_nand_separate
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  DEVICE_VENDOR := Xiaomi
  DEVICE_PACKAGES := uboot-envtools
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  UBINIZE_OPTS := -E 5
  IMAGES += kernel1.bin rootfs0.bin
  IMAGE/kernel1.bin := append-kernel
  IMAGE/rootfs0.bin := append-ubi | check-size
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/xiaomi_mi-router-3g
  $(Device/xiaomi_nand_separate)
  DEVICE_MODEL := Mi Router 3G
  IMAGE_SIZE := 124416k
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += R3G mir3g xiaomi,mir3g
endef
TARGET_DEVICES += xiaomi_mi-router-3g

define Device/xiaomi_mi-router-3g-v2
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 14848k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 3G
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2
  SUPPORTED_DEVICES += xiaomi,mir3g-v2
endef
TARGET_DEVICES += xiaomi_mi-router-3g-v2

define Device/xiaomi_mi-router-3-pro
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE:= 4096k
  UBINIZE_OPTS := -E 5
  IMAGE_SIZE := 255488k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 3 Pro
  IMAGES += factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | \
	check-size
  DEVICE_PACKAGES := kmod-mt7615e kmod-mt7615-firmware kmod-usb3 \
	kmod-usb-ledtrig-usbport uboot-envtools
  SUPPORTED_DEVICES += xiaomi,mir3p
endef
TARGET_DEVICES += xiaomi_mi-router-3-pro

define Device/xiaomi_mi-router-4
  $(Device/xiaomi_nand_separate)
  DEVICE_MODEL := Mi Router 4
  IMAGE_SIZE := 124416k
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt76x2
endef
TARGET_DEVICES += xiaomi_mi-router-4

define Device/xiaomi_mi-router-4a-gigabit
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 14848k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 4A
  DEVICE_VARIANT := Gigabit Edition
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2
endef
TARGET_DEVICES += xiaomi_mi-router-4a-gigabit

define Device/xiaomi_mi-router-ac2100
  $(Device/xiaomi_nand_separate)
  DEVICE_MODEL := Mi Router AC2100
  IMAGE_SIZE := 120320k
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += xiaomi_mi-router-ac2100

define Device/xiaomi_redmi-router-ac2100
  $(Device/xiaomi_nand_separate)
  DEVICE_MODEL := Redmi Router AC2100
  IMAGE_SIZE := 120320k
  DEVICE_PACKAGES += kmod-mt7603 kmod-mt7615e kmod-mt7615-firmware
endef
TARGET_DEVICES += xiaomi_redmi-router-ac2100

define Device/zbtlink_zbt-we1326
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-WE1326
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-sdhci-mt7620
  SUPPORTED_DEVICES += zbt-we1326
endef
TARGET_DEVICES += zbtlink_zbt-we1326

define Device/zbtlink_zbt-we3526
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-WE3526
  DEVICE_PACKAGES := kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += zbtlink_zbt-we3526

define Device/zbtlink_zbt-wg2626
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-WG2626
  DEVICE_PACKAGES := kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt76x2 kmod-usb3 \
	kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += zbt-wg2626
endef
TARGET_DEVICES += zbtlink_zbt-wg2626

define Device/zbtlink_zbt-wg3526-16m
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-WG3526
  DEVICE_VARIANT := 16M
  DEVICE_PACKAGES := kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 \
	kmod-usb3 kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += zbt-wg3526 zbt-wg3526-16M
endef
TARGET_DEVICES += zbtlink_zbt-wg3526-16m

define Device/zbtlink_zbt-wg3526-32m
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 32448k
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-WG3526
  DEVICE_VARIANT := 32M
  DEVICE_PACKAGES := kmod-ata-ahci kmod-sdhci-mt7620 kmod-mt7603 kmod-mt76x2 \
	kmod-usb3 kmod-usb-ledtrig-usbport
  SUPPORTED_DEVICES += ac1200pro zbt-wg3526-32M
endef
TARGET_DEVICES += zbtlink_zbt-wg3526-32m

define Device/zyxel_nr7101
  $(Device/dsa-migration)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  UBINIZE_OPTS := -E 5
  DEVICE_VENDOR := ZyXEL
  DEVICE_MODEL := NR7101
  DEVICE_PACKAGES := kmod-mt7603 kmod-usb3 uboot-envtools kmod-usb-net-qmi-wwan kmod-usb-serial-option uqmi
  KERNEL := $(KERNEL_DTB) | uImage lzma | zytrx-header $$(DEVICE_MODEL) $$(VERSION_DIST)-$$(REVISION)
  KERNEL_INITRAMFS := $(KERNEL_DTB) | uImage lzma | zytrx-header $$(DEVICE_MODEL) 9.99(ABUV.9)$$(VERSION_DIST)-recovery
  KERNEL_INITRAMFS_SUFFIX := -recovery.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += zyxel_nr7101

define Device/zyxel_wap6805
  $(Device/dsa-migration)
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  UBINIZE_OPTS := -E 5
  IMAGE_SIZE := 32448k
  DEVICE_VENDOR := ZyXEL
  DEVICE_MODEL := WAP6805
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7621-qtn-rgmii
  KERNEL := $(KERNEL_DTB) | uImage lzma | uimage-padhdr 160
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += zyxel_wap6805
