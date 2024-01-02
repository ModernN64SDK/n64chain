#! /bin/bash
# N64 MIPS GCC toolchain build/install script for Unix distributions
# originally based off libdragon's toolchain script,
# which was licensed under the Unlicense.
# (c) 2012-2021 DragonMinded and libDragon Contributors.

# Exit on error
set -e

# Set INSTALL_PATH before calling the script to change the default installation directory path
INSTALL_PATH="/opt/crashsdk"
# Set PATH for newlib to compile using GCC for MIPS N64 (pass 1)
export PATH="$PATH:$INSTALL_PATH/bin"

# Determine how many parallel Make jobs to run based on CPU count
JOBS="${JOBS:-`getconf _NPROCESSORS_ONLN`}"
JOBS="${JOBS:-1}" # If getconf returned nothing, default to 1
echo $JOBS

# Dependency source libs (Versions)
BINUTILS_V=2.41
GCC_V=13.2.0
NEWLIB_V=4.3.0.20230120

# Check if a command-line tool is available: status 0 means "yes"; status 1 means "no"
command_exists () {
  (command -v "$1" >/dev/null 2>&1)
  return $?
}

# Download the file URL using wget or curl (depending on which is installed)
download () {
  if   command_exists aria2c ; then aria2c -c -s 16 -x 16 "$1"
  elif command_exists wget ; then wget -c  "$1"
  elif command_exists curl ; then curl -LO "$1"
  else
    echo "Install `wget` or `curl` or `aria2c` to download toolchain sources" 1>&2
    return 1
  fi
}

unzip_and_patch () {
  tar -xJf "$1.tar.xz"
  pushd $1
  patch -p1 < ../$2
  popd
}

# Dependency source: Download stage
test -f "binutils-$BINUTILS_V.tar.xz" || download "https://ftpmirror.gnu.org/gnu/binutils/binutils-$BINUTILS_V.tar.xz"
test -f "gcc-$GCC_V.tar.xz"           || download "https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCC_V/gcc-$GCC_V.tar.xz"
test -f "newlib-$NEWLIB_V.tar.gz"     || download "https://sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz"

# Dependency source: Extract stage
test -d "binutils-$BINUTILS_V" || unzip_and_patch "binutils-$BINUTILS_V" "gas-vr4300.patch" 
test -d "gcc-$GCC_V" || unzip_and_patch "gcc-$GCC_V" "gcc-vr4300.patch"
test -d "newlib-$NEWLIB_V"     || tar -xzf "newlib-4.3.0.20230120.tar.gz"

# Download prereqs
cd "gcc-$GCC_V"
./contrib/download_prerequisites
cd ..

# Compile binutils
cd "binutils-$BINUTILS_V"
CFLAGS="-O2" CXXFLAGS="-O2" ./configure \
	--disable-debug \
    --enable-checking=release \
    --prefix="$INSTALL_PATH" \
    --target=mips64-elf \
    --with-cpu=mips64vr4300 \
    --program-prefix=mips-n64- \
    --disable-werror
make -j "$JOBS"
# make install || sudo make install || su -c "make install"
cp ../binutils-description.pak description.pak
sudo checkinstall --default --pkgversion $BINUTILS_V-1 --pkgname binutils-mips-n64 --exclude=/opt/crashsdk/share/info --install=no make install-strip
cp *.deb ../


# Compile GCC for MIPS N64 (pass 1) outside of the source tree
cd ..
rm -rf gcc_compile
mkdir gcc_compile
cd gcc_compile
../"gcc-$GCC_V"/configure \
    --prefix="$INSTALL_PATH" \
    --target=mips64-elf \
    --program-prefix=mips-n64- \
    --with-arch=vr4300 \
    --with-tune=vr4300 \
    --enable-languages=c \
    --without-headers \
    --with-newlib \
    --disable-libssp \
    --disable-multilib \
    --disable-shared \
    --with-gcc \
    --disable-threads \
    --disable-win32-registry \
    --disable-nls \
    --disable-werror \
    --with-system-zlib
make all-gcc -j "$JOBS"
make all-target-libgcc -j "$JOBS" CFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-stack-protector -mno-check-zero-division -fwrapv -Os"
make install-gcc || sudo make install-gcc || su -c "make install-gcc"
make install-target-libgcc || sudo make install-target-libgcc || su -c "make install-target-libgcc"

# Compile newlib
cd ../"newlib-$NEWLIB_V"
RANLIB_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ranlib CC_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-gcc CXX_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-g++ AR_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ar CFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-stack-protector -mno-check-zero-division -fno-PIC -fwrapv -Os" CXXFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-stack-protector -mno-check-zero-division -fno-PIC -fwrapv -Os" ./configure \
    --target=mips64-elf \
    --prefix="$INSTALL_PATH" \
    --with-cpu=mips64vr4300 \
    --disable-threads \
    --disable-libssp \
    --disable-werror
make -j "$JOBS"
cp ../newlib-description.pak description.pak
sudo checkinstall --default --pkgversion $NEWLIB_V-6 --pkgname newlib-mips-n64 --install=no
cp *.deb ../

# Compile GCC for MIPS N64 (pass 2) outside of the source tree
cd ..
rm -rf gcc_compile
mkdir gcc_compile
cd gcc_compile
CFLAGS="-O2" CXXFLAGS="-O2" ../"gcc-$GCC_V"/configure \
    --prefix="$INSTALL_PATH" \
    --with-gnu-as=${INSTALL_PATH}/bin/mips-n64-as \
    --with-gnu-ld=${INSTALL_PATH}/bin/mips-n64-ld \
    --enable-checking=release \
    --program-prefix=mips-n64- \
    --target=mips64-elf \
    --with-arch=vr4300 \
    --with-tune=vr4300 \
    --enable-languages=c,c++ \
    --with-newlib \
    --disable-libssp \
    --disable-multilib \
    --disable-shared \
    --with-gcc \
    --disable-threads \
    --disable-win32-registry \
    --disable-nls \
    --with-system-zlib
make -j "$JOBS" CFLAGS_FOR_TARGET="-mabi=32 -mfix4300 -G 0 -fno-PIC -fwrapv -fno-stack-protector -mno-check-zero-division -Os" CXXFLAGS_FOR_TARGET="-mabi=32 -mfix4300 -G 0 -fno-stack-protector -mno-check-zero-division -fno-PIC -fno-rtti -Os -fno-exceptions"
cp ../gcc-description.pak description.pak
sudo checkinstall --default --pkgversion $GCC_V-1 --pkgname gcc-mips-n64 --exclude=/opt/crashsdk/share/info --install=no make install-strip
cp *.deb ../
