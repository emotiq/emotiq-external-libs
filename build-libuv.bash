#!/usr/bin/env bash
#
#  Assuming the proper development tools are in place,
#  build shared libuv library for use in Emotiq project
#
# Linux
#   apt-get install gcc make g++ flex bison
# MacOS
#   XCode needs to be installed

# debug
set -x

install_linux_deps() {
  sudo apt-get update && sudo apt-get install -y \
    libtool
}

install_macos_deps() {
  brew install libtool autoconf automake
}

BASE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBUV_VERSION=1.20.3
LIBUV_SRC=https://github.com/libuv/libuv/archive/v${LIBUV_VERSION}.tar.gz

# where make install will install stuff
var=${BASE}/var
prefix=${var}/local
src=${var}/src

lib=${prefix}/lib
inc=${prefix}/include

case $(uname -s) in
    Linux*)
        install_linux_deps
        arch=linux
        ;;
    Darwin*)
        install_macos_deps
        arch=osx
        ;;
    *)
        echo Unknown OS \"$(uname -s)\"

        ;;
esac


# Build libuv

mkdir -p ${src}

cd ${src} \
  && curl -L ${LIBUV_SRC} | tar xvfz - \
  && cd libuv-${LIBUV_VERSION} \
  && ./autogen.sh \
  && ./configure --prefix=${prefix} \
  && make \
  && make install

if [ ! -d ${lib} ]; then
    echo the directory ${lib} does not exist, something went wrong during build of gmp
    exit 1
fi

if [ ! -d ${inc} ]; then
    echo the directory /${inc}/ does not exist, something went wrong during build of gmp
    exit 1
fi

cd ${prefix} && \
    tar cvfz ../emotiq-libuv-${arch}.tgz * && \
    echo "var/emotiq-libuv-${arch}.tgz" >artifact.txt
