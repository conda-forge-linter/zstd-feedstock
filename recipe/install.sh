#!/bin/bash

set -exo pipefail

export CFLAGS="${CFLAGS} -O3 -fPIC"

# Fix undefined clock_gettime (Is this needed? See above)
if [[ ${target_platform} =~ linux.* ]]; then
  export LDFLAGS="${LDFLAGS} -lrt"
fi

make -j$CPU_COUNT -C contrib/pzstd all

declare -a _CMAKE_EXTRA_CONFIG

if [[ ${HOST} =~ .*linux.* ]]; then
  # I hate you so much CMake.
  LIBPTHREAD=$(find ${PREFIX} -name "libpthread.so")
  _CMAKE_EXTRA_CONFIG+=(-DPTHREAD_LIBRARY=${LIBPTHREAD})
  LIBRT=$(find ${PREFIX} -name "librt.so")
  _CMAKE_EXTRA_CONFIG+=(-DRT_LIBRARIES=${LIBRT})
fi
  
if [[ "$PKG_NAME" == *static ]]; then
  # relying on conda to dedup package
  ZSTD_BUILD_STATIC=ON
else
  ZSTD_BUILD_STATIC=OFF
fi

pushd build/cmake
  FULL_AR=`which ${AR}`
  cmake -GNinja                            \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR="lib"       \
        -DCMAKE_PREFIX_PATH="${PREFIX}"    \
        -DCMAKE_AR=${FULL_AR}              \
        -DZSTD_BUILD_STATIC=${ZSTD_BUILD_STATIC} \
        -DZSTD_PROGRAMS_LINK_SHARED=ON     \
        "${_CMAKE_EXTRA_CONFIG[@]}"

  ninja install
popd
