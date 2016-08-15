#!/bin/bash

BASEDIR="$(dirname $0)"
SRCDIR="$BASEDIR"
BUILDDIR="$BASEDIR/build"

test ! -d "$BUILDDIR" && mkdir "$BUILDDIR"

# This is the minimum required Mac OS X version for
# stat.st_birthtimespec
export MACOSX_DEPLOYMENT_TARGET=10.6

# Comment this out to make a non-optimized Debug build
RELEASE_BUILD_FLAGS="-Os"

clang $RELEASE_BUILD_FLAGS -g -fobjc-link-runtime -fvisibility=hidden "$SRCDIR/birthtime_touch.mm" -o "$BUILDDIR/birthtime_touch"
