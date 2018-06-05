#!/bin/bash

# exit this script if any commmand fails
set -e
#  

host_os=`uname -s | tr "[:upper:]" "[:lower:]"`
host_arch=`uname -m`

ANDROID_NDK_ROOT=/Users/james/bin/android-ndk
GCC_VERSION=4.9

DIST_DIR="dist-android"

rm -rf $DIST_DIR
mkdir $DIST_DIR

build_v8()
{
    rm -rf $OUT_DIR

    ARM_VERSION_CONFIG=""
    if [ $ARM_VERSION ];then
        ARM_VERSION_CONFIG="arm_version=$ARM_VERSION"
        echo "arm version: $ARM_VERSION"
    else
        echo "can't find arm version!"
    fi

    # release version should make is_debug=false, symbol_level=0
    ARGS="is_debug=false \
          symbol_level=0 \
          target_os=\"android\" \
          target_cpu=\"$TARGET_CPU\" \
          v8_target_cpu=\"$TARGET_CPU\" \
          $ARM_VERSION_CONFIG \
          v8_use_snapshot=false \
          v8_enable_i18n_support=false \
          v8_use_external_startup_data=false \
          is_component_build=false \
          v8_static_library=true \
          android_ndk_root=\"$ANDROID_NDK_ROOT\" \
          "

    gn gen $OUT_DIR --args="${ARGS}"
    gn args $OUT_DIR --list
    ninja -C $OUT_DIR d8 -v #-j1

    BIN_DIR=$ANDROID_NDK_ROOT/toolchains/${TOOLS_ARCH}-${GCC_VERSION}/prebuilt/${host_os}-${host_arch}/bin
    AR=$BIN_DIR/${TOOLNAME_PREFIX}-ar
    STRIP=$BIN_DIR/${TOOLNAME_PREFIX}-strip

    mkdir -p $OUT_DIR/libs
    pushd $OUT_DIR/libs
    # $AR -rcsD libv8_base.a ../obj/v8_base/*.o
    $AR -rcsD libv8_libbase.a ../obj/v8_libbase/*.o
    # $AR -rcsD libv8_libsampler.a ../obj/v8_libsampler/*.o
    $AR -rcsD libv8_libplatform.a ../obj/v8_libplatform/*.o
    # $AR -rcsD libv8_nosnapshot.a ../obj/v8_nosnapshot/*.o
    cp ../obj/*.a .
    cp ../obj/src/inspector/libinspector.a .
    $STRIP --strip-unneeded libv8_base.a
    $STRIP --strip-unneeded libv8_libbase.a
    $STRIP --strip-unneeded libv8_libsampler.a
    $STRIP --strip-unneeded libv8_libplatform.a
    $STRIP --strip-unneeded libv8_nosnapshot.a
    # $STRIP --strip-unneeded libv8_builtins_generators.a
    # $STRIP --strip-unneeded libv8_builtins_setup.a
    $STRIP --strip-unneeded libinspector.a
    popd

    mkdir -p $DIST_DIR/$ANDROID_ARCH/include
    mkdir -p $DIST_DIR/$ANDROID_ARCH/libs
    cp -r include/* $DIST_DIR/$ANDROID_ARCH/include
    cp $OUT_DIR/libs/lib*.a $DIST_DIR/$ANDROID_ARCH/libs
}

# ANDROID_ARCH=armeabi
# OUT_DIR=out.gn/$ANDROID_ARCH
# TARGET_CPU=arm
# ARM_VERSION=6
# TOOLS_ARCH=arm-linux-androideabi
# TOOLNAME_PREFIX=$TOOLS_ARCH
# build_v8

ANDROID_ARCH=armeabi-v7a
OUT_DIR=out.gn/${ANDROID_ARCH}
TARGET_CPU=arm
ARM_VERSION=7
TOOLS_ARCH=arm-linux-androideabi
TOOLNAME_PREFIX=$TOOLS_ARCH
build_v8

# ANDROID_ARCH=arm64-v8a
# OUT_DIR=out.gn/$ANDROID_ARCH
# TARGET_CPU=arm64
# ARM_VERSION=8
# TOOLS_ARCH=aarch64-linux-android
# TOOLNAME_PREFIX=$TOOLS_ARCH
# build_v8

# ANDROID_ARCH=x86
# OUT_DIR=out.gn/$ANDROID_ARCH
# TARGET_CPU=x86
# ARM_VERSION=
# TOOLS_ARCH=x86
# TOOLNAME_PREFIX=i686-linux-android
# build_v8
