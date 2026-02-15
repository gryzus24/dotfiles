#!/bin/dash

(set -x; zig build --prefix . --prefix-exe-dir . --cache-dir /tmp/dirg-cache -Doptimize=ReleaseFast)
rm -rf /tmp/dirg-cache
