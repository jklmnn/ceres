
BUILD_DIR ?= build
CC ?= gcc

initramfs.cpio.gz: $(BUILD_DIR)/bin/init
	cd $(BUILD_DIR) && find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz

$(BUILD_DIR)/bin:
	mkdir $(BUILD_DIR)/bin

$(BUILD_DIR)/bin/init: src/init.c $(BUILD_DIR)/bin
	$(CC) src/init.c -std=gnu99 -o $(BUILD_DIR)/bin/init -Wl,-O3 -Wl,--as-needed -static

.PHONY: run
run: initramfs.cpio.gz bzImage
	qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 debug init=/bin/init"
