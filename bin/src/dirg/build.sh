#!/bin/dash

(set -x; zig build --prefix . --prefix-exe-dir . -Doptimize=ReleaseFast)
