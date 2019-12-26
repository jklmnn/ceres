
BUILD_DIR ?= build
CC ?= gcc

initramfs.cpio.gz: $(BUILD_DIR)/bin/init
	cd $(BUILD_DIR) && find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz

$(BUILD_DIR)/bin: $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/bin

$(BUILD_DIR)/bin/init: $(BUILD_DIR)/bin src/*.c
	$(CC) $(filter-out $<,$^) -std=gnu99 -Isrc -o $</init -ldl -Wl,-O3 -Wl,--as-needed -static

.PHONY: bzImage
bzImage:
	make -C linux -j4 bzImage
	cp -u linux/arch/x86/boot/bzImage bzImage

.PHONY: run
run: initramfs.cpio.gz bzImage
	qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 debug init=/bin/init"

.PHONY: clean
clean:
	rm -rf initramfs.cpio.gz $(BUILD_DIR)
