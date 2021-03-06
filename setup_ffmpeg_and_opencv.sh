#!/usr/bin/env bash

############################
### PART 0: GLOBAL SETUP ###
############################

# Set number of jobs, probably best to choose number of CPUS
export NUM_JOBS=4
NUM_JOBS=$(grep "cpu cores" /proc/cpuinfo | uniq | awk '{print $NF}')

export INSTALL_LOCATION="$HOME/.local"
mkdir -p "$INSTALL_LOCATION"

# install destination for binaries
export LOCAL_BIN_DIR="$INSTALL_LOCATION/bin"
mkdir -p "$LOCAL_BIN_DIR"
# install destination for libraries
export LOCAL_LIB_DIR="$INSTALL_LOCATION/lib"
mkdir -p "$LOCAL_LIB_DIR"
# tell linker where new libs will be added
export LD_LIBRARY_PATH="$LOCAL_LIB_DIR:$LD_LIBRARY_PATH"

# add bin dir to path
export PATH="$LOCAL_BIN_DIR:$PATH"

export PKG_CONFIG_PATH="$INSTALL_LOCATION/lib/pkgconfig"
# Install tooling from yum
sudo yum install autoconf \
	         automake \
		 bzip2 \
		 bzip2-devel \
		 cmake \
		 freetype-devel \
		 gcc \
		 gcc-c++ \
		 git \
		 libtool \
		 make \
		 pkgconfig \
		 zlib-devel \
		 wget \
		 -y

##############################
### PART 1: Install FFmpeg ###
##############################

# download destination for ffmpeg + dependencies
export FFMPEG_SRC_DIR="$HOME/ffmpeg_sources"
mkdir -p "$FFMPEG_SRC_DIR"
# scratch folder for temp files generated during build process
export FFMPEG_BUILD_DIR="$HOME/ffmpeg_sources"
mkdir -p "$FFMPEG_BUILD_DIR"


# install nasm (assembler)
cd "$FFMPEG_SRC_DIR" || exit
curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
tar xjvf nasm-2.15.05.tar.bz2
cd nasm-2.15.05 || exit
./autogen.sh
./configure --prefix="$INSTALL_LOCATION" --bindir="$LOCAL_BIN_DIR"
make -j"$NUM_JOBS"
make install

# install yasm (another assembler)
cd "$FFMPEG_SRC_DIR" || exit
curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0 || exit
./configure --prefix="$INSTALL_LOCATION" --bindir="$LOCAL_BIN_DIR"
make -j"$NUM_JOBS" 
make install

# install libx264
cd "$FFMPEG_SRC_DIR" || exit
git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git
cd x264 || exit
PKG_CONFIG_PATH="$INSTALL_LOCATION/lib/pkgconfig" ./configure --prefix="$INSTALL_LOCATION" --enable-static --enable-shared
make -j"$NUM_JOBS"
make install
cd ..

# install libx265
cd "$FFMPEG_SRC_DIR" || exit
git clone --branch stable --depth 2 https://bitbucket.org/multicoreware/x265_git
cd "x265_git/build/linux" || exit
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_LOCATION" -DENABLE_SHARED:bool=on ../../source
CFLAGS=-fPIC CXXFLAGS=-fPIC make -j"$NUM_JOBS"
make install

# install libvpx
cd "$FFMPEG_SRC_DIR" || exit
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx || exit
./configure --prefix="$INSTALL_LOCATION" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm --enable-shared
CFLAGS=-fPIC CXXFLAGS=-fPIC make -j"$NUM_JOBS" 
make install

# install libfdk_aac (AAC support)
cd "$FFMPEG_SRC_DIR" || exit
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac || exit
autoreconf -fiv
./configure --prefix="$INSTALL_LOCATION" --enable-shared
CFLAGS=-fPIC CXXFLAGS=-fPIC make -j"$NUM_JOBS" 
make install

# install libmp3lame (MP3 support)
cd "$FFMPEG_SRC_DIR" || exit
curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100 || exit
./configure --prefix="$INSTALL_LOCATION" --enable-shared --enable-nasm
CFLAGS=-fPIC CXXFLAGS=-fPIC make -j"$NUM_JOBS" 
make install
cd ..

# install libopus (OGG/Opus)
cd "$FFMPEG_SRC_DIR" || exit
curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
tar xzvf opus-1.3.1.tar.gz
cd opus-1.3.1 || exit
./configure --prefix="$INSTALL_LOCATION" --enable-shared
CFLAGS=-fPIC CXXFLAGS=-fPIC make -j"$NUM_JOBS" 
make install
cd ..

# install the rest of the FFmpeg codebase
cd "$FFMPEG_SRC_DIR" || exit
curl -O -L https://ffmpeg.org/releases/ffmpeg-4.2.4.tar.bz2
tar xjvf ffmpeg-4.2.4.tar.bz2
cd "$FFMPEG_SRC_DIR/ffmpeg-4.2.4" || exit
./configure \
  --prefix="$INSTALL_LOCATION"\
  --pkg-config-flags="--static" \
  --extra-cflags="-I$INSTALL_LOCATION/include" \
  --extra-ldflags="-L$INSTALL_LOCATION/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="$LOCAL_BIN_DIR" \
  --enable-gpl \
  --enable-shared \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
make -j"$NUM_JOBS"
make install

echo "TEST"
ffmpeg -version
echo "ENV"
printenv
##############################
### PART 2: Install OpenCV ###
##############################

export OPENCV_INSTALL_PREFIX="$HOME/.local"
export OPENCV_REPO_DIR="$HOME/opencv"
export OPENCV_CONTRIB_REPO_DIR="$HOME/opencv_contrib"
export OPENCV_VERSION="4.5.3"

# Clone the main repo + extra modules
git clone --recursive "https://github.com/opencv/opencv" "$OPENCV_REPO_DIR"
git clone --recursive "https://github.com/opencv/opencv_contrib" "$OPENCV_CONTRIB_REPO_DIR"


# checkout release commit for both main repo and modules
cd "$OPENCV_REPO_DIR" || exit
git checkout $OPENCV_VERSION

cd "$OPENCV_CONTRIB_REPO_DIR" || exit
git checkout $OPENCV_VERSION

# make build dir and setup makefiles
mkdir -p "$OPENCV_REPO_DIR/build" && cd "$OPENCV_REPO_DIR/build" || exit
cmake .. \
	-DCMAKE_BUILLD_TYPE=Release \
	-DWITH_FFMPEG=ON \
	-DOPENCV_EXTRA_MODULES_PATH="$OPENCV_CONTRIB_REPO_DIR/modules" \
	-DCMAKE_INSTALL_PREFIX="$OPENCV_INSTALL_PREFIX"

# compile and install
make -j"$NUM_JOBS" install

# show relevant env info
echo "Here are some changes you probably want to add to your shell env"

echo "export LD_LIBRARY_PATH=\"$LOCAL_LIB_DIR:\$LD_LIBRARY_PATH\""
echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\""
echo "export PKG_CONFIG_PATH=\"$INSTALL_LOCATION/lib/pkgconfig\""