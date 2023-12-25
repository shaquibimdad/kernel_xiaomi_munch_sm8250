#!/bin/bash

# Set configurable variables
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="Snapdragon Clang 10.0.9"

# Path variables
export COMPILER_PATH="/media/shaquib/kernel-dev/compiler"
export KERNEL_PATH="/media/shaquib/kernel-dev/daemon_kernel"
export OUTPUT_PATH="/media/shaquib/kernel-dev/outputimg"

# Compiler variables
export CROSS_COMPILE="$COMPILER_PATH/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export CLANG_PATH="$COMPILER_PATH/Snapdragon-LLVM-10.0.9/bin/clang"
export CLANG_TRIPLE="aarch64-linux-gnu-"

# Build configuration files
export VENDOR_PERF_DEFCONFIG="vendor/kona-perf_defconfig"
export VENDOR_SM8250_COMMON_CONFIG="vendor/xiaomi/sm8250-common.config"
export VENDOR_MUNCH_CONFIG="vendor/xiaomi/munch.config"

# KernelSU variables
INSTALL_KERNEL_SU=false
REMOVE_KSU=false

# Process command-line options
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 [--ksu|--noksu]"
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
  --ksu)
    echo "Installing KernelSU..."
    INSTALL_KERNEL_SU=true
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
    shift
    ;;
  --noksu)
    echo "Compiling without KSU"
    rm -rf drivers/kernelsu
    sed -i '/source "drivers\/kernelsu\/Kconfig"/d' drivers/Kconfig
    git revert --no-commit ff3f503a0439298e85208fb0b63ffc3b4f03bb5e
    remove_ksu=true
    shift
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: $0 [--ksu|--noksu]"
    exit 1
    ;;
  esac
done

echo "Sleeping for 5 seconds"
sleep 5

# Build the kernel
make O=out CC="$CLANG_PATH" CLANG_TRIPLE="$CLANG_TRIPLE" \
  "$VENDOR_PERF_DEFCONFIG" "$VENDOR_SM8250_COMMON_CONFIG" "$VENDOR_MUNCH_CONFIG"

make -j8 O=out CC="$CLANG_PATH" CLANG_TRIPLE="$CLANG_TRIPLE"

echo "Sleeping for 5 seconds"
sleep 5

# Post-build actions
if [ "$REMOVE_KSU" = true ]; then
  cp -fr "$KERNEL_PATH/out/arch/$ARCH/boot/Image" "$OUTPUT_PATH/noksu"
  git reset --hard
fi

if [ "$INSTALL_KERNEL_SU" = true ]; then
  cp -fr "$KERNEL_PATH/out/arch/$ARCH/boot/Image" "$OUTPUT_PATH/ksu"
  rm -rf drivers/kernelsu
  sed -i '/source "drivers\/kernelsu\/Kconfig"/d' drivers/Kconfig
fi

