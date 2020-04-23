#!/bin/bash
# export PATH=${HOME}/opt/android-ndk-r20/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}
# XARCH= # "x86" "ia64" "sparc" "power" "mips1" "mips2" "mips3" "mips4" "mips32" "mips32r2" "mips64" "parisc" "arm" "combined" "combined-x86-power"

set -eu

# 修改以下值为合适的值
export AR=arm-linux-androideabi-ar
export AS=arm-linux-androideabi-as
export CC=armv7a-linux-androideabi19-clang
export CXX=armv7a-linux-androideabi19-clang++
export LD=arm-linux-androideabi-ld
export RANLIB=arm-linux-androideabi-ranlib
export STRIP=arm-linux-androideabi-strip

# 以下两个值可以随意命名, toolset 按此名的组合到user-config.jam中查找
XCOMPILER=clang
XPLATFORM=android
XARCH=

version=1.61.0
version2=$(sed 's#\.#_#g' <<< $version)
echo "Building boost $version..."

prefix=`pwd`/sysroot

dir_name=boost_${version2}
archive=${dir_name}.tar.bz2
if [ ! -f "$archive" ]; then
  wget -O $archive "http://downloads.sourceforge.net/boost/$archive"
else
  echo "Archive $archive already downloaded"
fi

echo "Extracting..."
if [ ! -d "$dir_name" ]; then
  # rm -rf $dir_name
  tar xf $archive
else
  echo "Archive $archive already unpacked into $dir_name"
fi

rm -f boost_${version2}/libs/filesystem/src/operations.cpp
cp operations-${version}.cpp boost_${version2}/libs/filesystem/src/operations.cpp
cd $dir_name

echo "Generating config..."
# 也可以通过覆盖 project-config.jam
user_config=tools/build/src/user-config.jam
rm -f $user_config
cat > $user_config <<EOF
import os ;
import option ;

using ${XCOMPILER} : ${XPLATFORM} : $CXX ;
option.set keep-going : false ;
EOF

# using ${XCOMPILER} : target : $CXX : <archiver>$AR <ranlib>$RANLIB ;

echo "Bootstrapping..."
./bootstrap.sh #--with-toolset=${XCOMPILER}

echo "Building..."
B2_CMD="./b2 -j4 \
    --prefix=${prefix} \
    --with-atomic \
    --with-chrono \
    --with-container \
    --with-date_time \
    --with-exception \
    --with-filesystem \
    --with-graph \
    --with-graph_parallel \
    --with-iostreams \
    --with-locale \
    --with-log \
    --with-math \
    --with-mpi \
    --with-program_options \
    --with-random \
    --with-regex \
    --with-serialization \
    --with-signals \
    --with-system \
    --with-test \
    --with-thread \
    --with-timer \
    --with-type_erasure \
    --with-wave \
    -s NO_BZIP2=1 \
    toolset=${XCOMPILER}-${XPLATFORM} \
    variant=release \
    threading=multi \
    threadapi=pthread \
    link=static \
    install"

if test "${XARCH}" != ""
then
	B2_CMD="${B2_CMD} architecture=${XARCH}"
fi

${B2_CMD}

#    target-os=android \
#    --layout=versioned \
#    runtime-link=static \
#    --with-fiber \

echo "Running ranlib on libraries..."
libs=$(find "bin.v2/libs/" -name '*.a')
for lib in $libs; do
  "$RANLIB" "$lib"
done

echo "Done!"
