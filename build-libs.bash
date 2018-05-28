#!/usr/bin/env bash
#
#  Assuming the proper development tools are in place, make the
#  libraries needed, and produce a shared object suitable for loading
#  the code for Pair Based Curves (PBC).
#
# Linux
#   apt-get install gcc make g++ flex bison
# MacOS
#   XCode needs to be installed


# debug
set -x

BASE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GMP_SRC=https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2
# GMP_HG_REPO="https://gmplib.org/repo/gmp-6.1/"
PBC_SRC=https://crypto.stanford.edu/pbc/files/pbc-0.5.14.tar.gz

# where the tarballs should be
dist=${BASE}/src/PBC-Intf
# pbc intf files are in the same place
pbcintf=${dist}

uname_s=$(uname -s)
case ${uname_s} in
    Linux*)
        GMP_CONFIGURE_FLAGS="--host=core2-pc-linux-gnu --disable-shared --enable-static"
        PBC_CONFIGURE_FLAGS="--disable-shared --enable-static"
        arch=linux
        ;;
    Darwin*)
        arch=osx
        GMP_CONFIGURE_FLAGS="--host=core2-apple-darwin17.5.0 --disable-shared --enable-static"
        PBC_CONFIGURE_FLAGS="--disable-shared --enable-static"
        ;;
    CYGWIN_NT*)
        arch=win32
        GMP_CONFIGURE_FLAGS="--disable-static --enable-shared --host=core2-unknown-cygwin"
        PBC_CONFIGURE_FLAGS="--disable-static --enable-shared"
        ;;
    *)
        echo Unknown OS \"$(uname_s)\"
        exit 127
        ;;
esac

# where make install will install stuff
var=${BASE}/var
prefix=${var}/local
src=${var}/src
gmp=${src}/gmp-6.1.2
pbc=${src}/pbc-0.5.14

lib=${prefix}/lib
inc=${prefix}/include

# PBC depends on GMP, so build GMP first

mkdir -p ${src}

cd ${src} \
  && curl ${GMP_SRC} | tar xvfj - \
  && cd ${gmp} \
  && ./configure ${GMP_CONFIGURE_FLAGS} --prefix=${prefix} \
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

# Use @rpath in libraries ids for macOS
if [[ ${uname_s} = Darwin* ]] ; then
  (cd ${lib} && install_name_tool -id '@rpath/libgmp.dylib' libgmp.dylib)
fi

export CFLAGS=-I${inc}
export CPPFLAGS=-I${inc}
export CXXFLAGS=-I${inc}
export LDFLAGS=-L${lib}

cd ${src} \
    && curl ${PBC_SRC} | tar xvfz - \
    && cd ${pbc} \
    && ./configure ${PBC_CONFIGURE_FLAGS} --prefix=${prefix} \
    && make \
    && make install

# Use @rpath in libraries ids for macOS
if [[ ${uname_s} = Darwin* ]] ; then
  (cd ${lib} && install_name_tool -id '@rpath/libpbc.dylib' libpbc.dylib)
fi

cd ${prefix} && \
    tar cvfz ../emotiq-external-libs-${arch}.tgz * && \
    echo "var/emotiq-external-libs-${arch}.tgz" >artifact.txt
