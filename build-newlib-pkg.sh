#!/bin/bash
set -eu

getnumproc() {
which getconf >/dev/null 2>/dev/null && {
	getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1;
} || echo 1;
};

numproc=`getnumproc`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_DIR}

export NEWLIB_V=3.1.0

# EDIT THIS LINE TO CHANGE YOUR INSTALL PATH!
export INSTALL_PATH=${N64_CMP:-/opt/crashsdk}

mkdir -p $INSTALL_PATH || sudo mkdir -p $INSTALL_PATH || su -c "mkdir -p ${INSTALL_PATH}"

export PATH=$PATH:$INSTALL_PATH/bin
test -f newlib-$NEWLIB_V.tar.gz || wget -c ftp://sourceware.org/pub/newlib/newlib-$NEWLIB_V.tar.gz

test -d newlib-$NEWLIB_V || tar -xzf newlib-$NEWLIB_V.tar.gz
# Compile newlib
cd newlib-$NEWLIB_V
RANLIB_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ranlib CC_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-gcc CXX_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-g++ AR_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ar CFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-PIC -O2" CXXFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-PIC -O2" ./configure --target=mips64-elf --prefix=${INSTALL_PATH} --with-cpu=mips64vr4300 --disable-threads --disable-libssp --disable-werror
make -j${numproc}

sudo checkinstall --pkgname newlib-mips-n64 --install=no
cp *.deb ../
cd ..
sudo rm -rf "${SCRIPT_DIR}"/newlib-3.1.0

rm -rf "${SCRIPT_DIR}"/newlib-3.1.0.tar.gz