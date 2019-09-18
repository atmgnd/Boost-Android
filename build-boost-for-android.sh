#!/bin/bash

version=1.61.0
echo "Building boost $version..."

set -eu

prefix=`pwd`/build
export PATH=${HOME}/opt/android-ndk-r20/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}
export AR=arm-linux-androideabi-ar
export AS=arm-linux-androideabi-as
export CC=1rmv7a-linux-androideabi9-clang
export CXX=armv7a-linux-androideabi19-clang++
export LD=arm-linux-androideabi-ld
export RANLIB=arm-linux-androideabi-ranlib
export STRIP=arm-linux-androideabi-strip

dir_name=boost_$(sed 's#\.#_#g' <<< $version)
archive=${dir_name}.tar.bz2
if [ ! -f "$archive" ]; then
  wget -O $archive "https://dl.bintray.com/boostorg/release/$version/source/$archive"
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

rm -f boost_1_61_0/libs/filesystem/src/operations.cpp
cp operations-1.61.0.cpp boost_1_61_0/libs/filesystem/src/operations.cpp
cd $dir_name

echo "Generating config..."
user_config=tools/build/src/user-config.jam
rm -f $user_config
cat > $user_config <<EOF
import os ;

using clang : android
:
"$CXX"
:
<archiver>$AR
<ranlib>$RANLIB
;
EOF

echo "Bootstrapping..."
./bootstrap.sh #--with-toolset=clang

echo "Building..."
./b2 -j4 \
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
    toolset=clang-android \
    architecture=arm \
    variant=release \
    target-os=android \
    threading=multi \
    threadapi=pthread \
    link=static \
    install

#    --layout=versioned \
#    runtime-link=static \
#    --with-fiber \

echo "Running ranlib on libraries..."
libs=$(find "bin.v2/libs/" -name '*.a')
for lib in $libs; do
  "$RANLIB" "$lib"
done

echo "Done!"
