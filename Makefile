
BUILD_DIR ?= build
CC ?= gcc

initramfs.cpio.gz: $(BUILD_DIR)/bin/init
	mkdir -p $(BUILD_DIR)/lib/x86_64-linux-gnu
	cp -vL /lib/x86_64-linux-gnu/libc.so.6 $(BUILD_DIR)/lib/x86_64-linux-gnu
	cp -vL /lib/x86_64-linux-gnu/libdl.so.2 $(BUILD_DIR)/lib/x86_64-linux-gnu
	cp -vL /lib/x86_64-linux-gnu/libpthread.so.0 $(BUILD_DIR)/lib/x86_64-linux-gnu
	cp -vL /lib/x86_64-linux-gnu/librt.so.1 $(BUILD_DIR)/lib/x86_64-linux-gnu
	mkdir -p $(BUILD_DIR)/lib64
	cp -vL /lib64/ld-linux-x86-64.so.2 $(BUILD_DIR)/lib64
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
	qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 debug"

.PHONY: clean
clean:
	rm -rfv initramfs.cpio.gz $(BUILD_DIR) gneiss/build
	make -C linux clean
	make -C gneiss/ada-runtime clean
