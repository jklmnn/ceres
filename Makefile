
BUILD_DIR ?= build
CC ?= gcc

initramfs.cpio.gz: $(BUILD_DIR)/bin/init
	cd $(BUILD_DIR) && find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz

$(BUILD_DIR)/bin:
	mkdir -p $(BUILD_DIR)/bin

$(BUILD_DIR)/bin/init: runtime $(BUILD_DIR)/bin
	cd gneiss && gprbuild -P gneiss.gpr -XPLATFORM=linux -XKIND=static -XTEST=init; cd ..
	cp -u gneiss/build/init/init $(BUILD_DIR)/bin/init

.PHONY: runtime
runtime:
	make -C gneiss/ada-runtime

.PHONY: bzImage
bzImage:
	make -C linux -j4 bzImage
	cp -u linux/arch/x86/boot/bzImage bzImage

.PHONY: run
run: initramfs.cpio.gz bzImage
	qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 debug init=/bin/init"

.PHONY: clean
clean:
	rm -rfv initramfs.cpio.gz $(BUILD_DIR) gneiss/build
	make -C linux clean
	make -C gneiss/ada-runtime clean
