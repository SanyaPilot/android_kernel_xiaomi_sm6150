#!/bin/bash
#
# Compile script for Kernel
# Copyright (C)

SECONDS=0 # builtin bash timer
CLANG_DIR="$HOME/clang"
AK3_DIR="$HOME/AnyKernel3"
DEFCONFIG="tucana_defconfig"

ZIPNAME="Kernel-tucana-$(date '+%Y%m%d-%H%M').zip"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

MAKE_PARAMS="O=out ARCH=arm64 CC=clang LLVM=1 LLVM_IAS=1 \
	AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump STRIP=llvm-strip \
	CROSS_COMPILE=aarch64-linux-gnu-"

export PATH="$CLANG_DIR/bin:$PATH"

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	make $MAKE_PARAMS clean
	make $MAKE_PARAMS mrproper
	echo "Cleaned output folder"
fi

mkdir -p out
make $MAKE_PARAMS $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc) $MAKE_PARAMS || exit $?

kernel="out/arch/arm64/boot/Image.gz-dtb"

if [ ! -f "$kernel" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
	cp -r $AK3_DIR AnyKernel3
	git -C AnyKernel3 checkout tucana &> /dev/null
elif ! git clone -q https://github.com/ghostrider-reborn/AnyKernel3 -b lisa; then
	echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
	exit 1
fi
cp $kernel AnyKernel3
cd AnyKernel3
zip -r9 "../../../Output/$ZIPNAME" * -x .git README.md
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) dakika ve $((SECONDS % 60)) saniye."
echo "Zip: $ZIPNAME"
