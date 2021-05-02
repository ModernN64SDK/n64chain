#!/bin/bash
set -eu

#
# tools/build-linux64-toolchain.sh: Linux toolchain build script.
#
# n64chain: A (free) open-source N64 development toolchain.
# Copyright 2014-16 Tyler J. Stachecki <stachecki.tyler@gmail.com>
#
# This file is subject to the terms and conditions defined in
# 'LICENSE', which is part of this source code package.
#

getnumproc() {
which getconf >/dev/null 2>/dev/null && {
	getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1;
} || echo 1;
};

numproc=`getnumproc`


# EDIT THIS LINE TO CHANGE YOUR INSTALL PATH!
export INSTALL_PATH=${N64_CMP:-/opt/crashsdk}

mkdir -p $INSTALL_PATH || sudo mkdir -p $INSTALL_PATH || su -c "mkdir -p ${INSTALL_PATH}"

export PATH=$PATH:$INSTALL_PATH/bin

BINUTILS="ftp://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.bz2"
GCC="ftp://ftp.gnu.org/gnu/gcc/gcc-10.3.0/gcc-10.3.0.tar.gz"


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_DIR} && mkdir -p {stamps,tarballs}


if [ ! -f stamps/binutils-download ]; then
  wget "${BINUTILS}" -O "tarballs/$(basename ${BINUTILS})"
  touch stamps/binutils-download
fi

if [ ! -f stamps/binutils-extract ]; then
  mkdir -p binutils-{build,source}
  tar -xf tarballs/$(basename ${BINUTILS}) -C binutils-source --strip 1
  touch stamps/binutils-extract
fi

if [ ! -f stamps/binutils-configure ]; then
  pushd binutils-build
  ../binutils-source/configure \
    --prefix="${INSTALL_PATH}" \
    --with-lib-path="${INSTALL_PATH}/lib" \
    --target=mips64-elf --with-arch=vr4300 \
    --program-prefix=mips-n64- \
    --enable-64-bit-bfd \
    --enable-plugins \
    --enable-shared \
    --disable-gold \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-static \
    --disable-werror
  popd

  touch stamps/binutils-configure
fi

if [ ! -f stamps/binutils-build ]; then
  pushd binutils-build
  make -j${numproc}
  popd

  touch stamps/binutils-build
fi

if [ ! -f stamps/binutils-install ]; then
  pushd binutils-build
  sudo checkinstall --pkgversion 2.30 --pkgname binutils-mips-n64 --install=no make install-strip
  cp *.deb ../
  popd

  touch stamps/binutils-install
fi

if [ ! -f stamps/gcc-download ]; then
  wget "${GCC}" -O "tarballs/$(basename ${GCC})"
  touch stamps/gcc-download
fi

if [ ! -f stamps/gcc-extract ]; then
  mkdir -p gcc-{build,source}
  tar -xf tarballs/$(basename ${GCC}) -C gcc-source --strip 1
  touch stamps/gcc-extract
fi

if [ ! -f stamps/gcc-configure ]; then
  pushd gcc-build
  ../gcc-source/configure \
    --prefix="${INSTALL_PATH}" \
    --target=mips64-elf --with-arch=vr4300 \
    --program-prefix=mips-n64- \
    --enable-languages=c,c++ --without-headers --with-newlib \
    --with-gnu-as=${INSTALL_PATH}/bin/mips-n64-as \
    --with-gnu-ld=${INSTALL_PATH}/bin/mips-n64-ld \
    --enable-checking=release \
    --enable-shared \
    --enable-shared-libgcc \
    --disable-decimal-float \
    --disable-gold \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libitm \
    --disable-libquadmath \
    --disable-libquadmath-support \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libunwind-exceptions \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-static \
    --disable-threads \
    --disable-win32-registry \
    --enable-lto \
    --enable-plugin \
    --enable-static \
    --without-included-gettext
  popd

  touch stamps/gcc-configure
fi

if [ ! -f stamps/gcc-build ]; then
  pushd gcc-build
  make all-gcc -j${numproc}
  popd

  touch stamps/gcc-build
fi

if [ ! -f stamps/gcc-install ]; then
  pushd gcc-build
  sudo checkinstall --pkgversion 10.3.0 --pkgname gcc-mips-n64 --install=no make install-strip-gcc
  cp *.deb ../
  popd

  touch stamps/gcc-install
fi

rm -rf "${SCRIPT_DIR}"/tarballs
rm -rf "${SCRIPT_DIR}"/*-source
rm -rf "${SCRIPT_DIR}"/*-build
rm -rf "${SCRIPT_DIR}"/stamps
exit 0

