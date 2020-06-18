#!/bin/sh

BUILD_DIR=build

set -e

echo Compiling Linux...
cp gneiss.config linux/.config
make -C linux -j$(nproc) bzImage
cp -u linux/arch/x86/boot/bzImage bzImage

echo Setting up rootfs...
mkdir -vp $BUILD_DIR/lib/x86_64-linux-gnu
cp -vL /lib/x86_64-linux-gnu/libc.so.6 $BUILD_DIR/lib/x86_64-linux-gnu
cp -vL /lib/x86_64-linux-gnu/libdl.so.2 $BUILD_DIR/lib/x86_64-linux-gnu
cp -vL /lib/x86_64-linux-gnu/libpthread.so.0 $BUILD_DIR/lib/x86_64-linux-gnu
cp -vL /lib/x86_64-linux-gnu/librt.so.1 $BUILD_DIR/lib/x86_64-linux-gnu
mkdir -p $BUILD_DIR/lib64
cp -vL /lib64/ld-linux-x86-64.so.2 $BUILD_DIR/lib64
mkdir -p $BUILD_DIR/bin
mkdir -p $BUILD_DIR/etc/gneiss
cp -vL $1 $BUILD_DIR/etc/gneiss/config.xml

echo Compiling Gneiss system from $1...
echo ./gneiss/cement build -r $BUILD_DIR $1 gneiss gneiss gneiss/test gneiss/lib
./gneiss/cement build -r $BUILD_DIR -b gneiss/build $1 gneiss gneiss/test gneiss/lib

echo Creating initramfs...
cd $BUILD_DIR/bin
ln -s core init
cd -
cd $BUILD_DIR && find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
cd -

echo Starting system...
qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz -nographic -append "console=ttyS0 debug"

