#!/bin/dash

(set -x;
    cc -Wall -Wextra -Wpedantic -Wconversion -Wdeclaration-after-statement \
    -s -static -nostdlib \
    -fno-stack-protector -O3 \
    -T cgb.ld \
    cgb.c -o cgb
)
