#!/bin/dash

BUILD_FLAGS=
if [ "$1" = "-DPATH_PREFIXES" ]; then
    BUILD_FLAGS="$1"
fi

(set -x;
    cc -std=c11 \
    -Wall -Wextra -Wpedantic -Wconversion -Wdeclaration-after-statement \
    -s -static -nostdlib \
    -march=native \
    -O3 -fno-stack-protector \
    $BUILD_FLAGS \
    -T cgb.ld \
    cgb.c -o cgb
)
