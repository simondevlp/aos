BUILD_DIR = build
ESP_DIR_NAME = aos-esp
BOOT_DIR_NAME = $(ESP_DIR_NAME)/efi/boot
BOOTLOADER_IMAGE_PATH = target/x86_64-unknown-uefi/debug/aos-bootloader.efi
IMG_NAME = aos-uefi.img
OVMF_FD_PATH = /usr/share/ovmf/OVMF.fd

build:
	cargo build -p aos-bootloader

clean-dir:
	rm -rf ${ESP_DIR_NAME}

dir: build
	mkdir -p ${BOOT_DIR_NAME}
	cp ${BOOTLOADER_IMAGE_PATH} ${BOOT_DIR_NAME}/bootx64.efi

run-dir: dir
	qemu-system-x86_64 -drive format=raw,file=fat:rw:${ESP_DIR_NAME} \
		-bios ${OVMF_FD_PATH}
	$(MAKE) clean-dir

image: build
	dd if=/dev/zero of=${IMG_NAME} bs=1M count=64
	mkfs.vfat -F32 ${IMG_NAME}
	mkdir -p /tmp/${ESP_DIR_NAME}
	sudo mount -o loop ${IMG_NAME} /tmp/${ESP_DIR_NAME}
	sudo mkdir -p /tmp/${BOOT_DIR_NAME}
	sudo cp ${BOOTLOADER_IMAGE_PATH} /tmp/${BOOT_DIR_NAME}/bootx64.efi
	sudo umount /tmp/${ESP_DIR_NAME}
	rmdir /tmp/${ESP_DIR_NAME}

clean-image:
	rm -f ${IMG_NAME}

run-image: image
	qemu-system-x86_64 -drive format=raw,file=${IMG_NAME} -bios ${OVMF_FD_PATH}
	$(MAKE) clean-image

.PHONY: build clean-dir dir run-dir image clean-image run-image run

ifeq ($(EMU), dir)
run: run-dir
else
run: run-image
endif