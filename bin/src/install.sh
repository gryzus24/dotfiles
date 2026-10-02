#!/bin/dash

BINDIR=~/bin
SRCDIR=~/bin/src
OVRDIR=~/bin/overridden

if [ -z "${PROGS+x}" ]; then
    PROGS='dirg cgb membw'
fi

IFS=' '
for prog in $PROGS; do
    cd "$SRCDIR/$prog" || exit 1

    bin_path="$BINDIR/$prog"
    if [ -r "$bin_path" ] && file -b "$bin_path" | grep -q script; then
        mkdir -p "$OVRDIR"
        (set -x; mv -n "$bin_path" "$OVRDIR/$prog")
    fi
    ./build.sh
    (set -x; mv "$prog" "$bin_path")
done
