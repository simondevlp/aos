BUILD_DIR = build
ESP_DIR_NAME = fos
BOOT_DIR_NAME = $(ESP_DIR_NAME)/efi/boot
BOOTLOADER_IMAGE_PATH = target/x86_64-unknown-uefi/debug/aos-bootloader.efi
IMG_NAME = fos.img
OVMF_FD_PATH = /usr/share/ovmf/OVMF.fd

build:
	cargo +nightly build -p aos-bootloader --target x86_64-unknown-uefi;

clean-dir:
	rm -rf ${ESP_DIR_NAME};

dir: build;
	mkdir -p ${BOOT_DIR_NAME};
	cp ${BOOTLOADER_IMAGE_PATH} ${BOOT_DIR_NAME}/bootx64.efi;

run-dir: dir;
	qemu-system-x86_64 -drive format=raw,file=fat:rw:${ESP_DIR_NAME} \
		-bios ${OVMF_FD_PATH};
	make clean-dir;

image: build;
	dd if=/dev/zero of=${IMG_NAME} bs=1M count=64;
	mkfs.vfat -F32 ${IMG_NAME};
	sudo mkdir -p ${ESP_DIR_NAME};
	sudo mount -o loop ${IMG_NAME} ${ESP_DIR_NAME};
	sudo mkdir -p $(BOOT_DIR_NAME);
	sudo cp target/x86_64-unknown-uefi/debug/aos-bootloader.efi \
		${BOOT_DIR_NAME}/bootx64.efi;
	sudo umount ${ESP_DIR_NAME};

clean-image:
	rm -f ${IMG_NAME};
	rm -rf ${ESP_DIR_NAME};

run-image: image;
	qemu-system-x86_64 -drive format=raw,file=${IMG_NAME} -bios \
		${OVMF_FD_PATH};
	make clean-image;