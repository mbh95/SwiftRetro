build() (
    (cd $1
    make -f Makefile.libretro platform=$2 clean
    make -f Makefile.libretro platform=$2
    mkdir -p ../build
    cp $3 ../build/$3
    make -f Makefile.libretro platform=$2 clean)
)

# mGBA
build libretro-mgba ios-arm64 mgba_libretro_ios.dylib
build libretro-mgba ios-arm64-simulator mgba_libretro_ios_simulator.dylib
build libretro-mgba osx mgba_libretro.dylib

# 2048
build libretro-2048 ios-arm64 2048_libretro_ios.dylib
build libretro-2048 ios-arm64-simulator 2048_libretro_ios_simulator.dylib
build libretro-2048 osx 2048_libretro.dylib
