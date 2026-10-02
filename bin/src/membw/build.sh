#!/bin/dash

(set -x;
    cc -std=gnu23 \
    -Wall -Wextra -Wconversion -Wshadow \
    -march=native \
    -O2 \
    -DNOINLINE_DO_FUNCS \
    membw.c -o membw
)
strip -g membw
