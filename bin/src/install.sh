#!/bin/sh

PREFIX="$HOME"
BINDIR="$PREFIX/bin"
SRCDIR="$BINDIR/src"
OVRDIR="$BINDIR/overridden"

if [ -z "${PROGS+x}" ]; then
    PROGS='dirg cgb'
fi

IFS=' '
for prog in $PROGS; do
    cd "$SRCDIR/$prog" || exit 1

    bin_path="$BINDIR/$prog"
    if [ -e "$bin_path" ] && file -b "$bin_path" | grep -q script; then
        mkdir -p "$OVRDIR"
        (set -x; mv -n "$bin_path" "$OVRDIR/$prog")
    fi
    ./build.sh
    (set -x; mv "$prog" "$bin_path")
done
