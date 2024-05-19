const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
const os = std.os;
const posix = std.posix;

fn isFile(path: []const u8) bool {
    const pathz = posix.toPosixPath(path) catch
        return false;

    var statbuf: os.linux.Stat = undefined;
    if (os.linux.lstat(&pathz, &statbuf) != 0)
        return false;

    return os.linux.S.ISREG(statbuf.mode);
}

fn usage(writer: anytype) u8 {
    _ = writer.write(
        \\usage: dirg [a] [c] [h] <newline delimited paths from stdin>
        \\  a  sort alphabetically
        \\  c  show file count per directory
        \\  h  display this help and exit
        \\
    ) catch
        return 1;

    return 2;
}

pub fn main() !u8 {
    var _arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer _arena.deinit();
    const arena = _arena.allocator();

    var stdout_buffer = io.bufferedWriter(io.getStdOut().writer());
    defer stdout_buffer.flush() catch {};
    const stdout = stdout_buffer.writer();

    var f_a = false;
    var f_c = false;
    for (os.argv[1..]) |arg| {
        var i: usize = 0;
        while (arg[i] != 0) : (i += 1) switch (arg[i]) {
            'a' => f_a = true,
            'c' => f_c = true,
            'h' => return usage(stdout),
            else => {},
        };
    }

    const buf = try io.getStdIn().reader().readAllAlloc(arena, math.maxInt(usize));
    var lines = mem.tokenizeScalar(u8, buf, '\n');
    var dircnt = std.StringArrayHashMap(u32).init(arena);

    while (lines.next()) |line| {
        if (isFile(line)) {
            if (fs.path.dirname(line)) |dname| {
                const entry = try dircnt.getOrPutValue(dname, 1);
                if (entry.found_existing)
                    entry.value_ptr.* += 1;
            }
        }
    }

    if (dircnt.count() == 0)
        return 0;

    if (f_a) {
        const SortCtx = struct {
            dirs: []const []const u8,

            pub fn lessThan(self: @This(), a_indx: usize, b_indx: usize) bool {
                switch (mem.order(u8, self.dirs[a_indx], self.dirs[b_indx])) {
                    .eq => unreachable,
                    .lt => return true,
                    .gt => return false,
                }
            }
        };
        dircnt.sort(SortCtx{ .dirs = dircnt.keys() });
    } else {
        const SortCtx = struct {
            counts: []u32,

            pub fn lessThan(self: @This(), a_indx: usize, b_indx: usize) bool {
                return self.counts[a_indx] < self.counts[b_indx];
            }
        };
        dircnt.sort(SortCtx{ .counts = dircnt.values() });
    }

    if (f_c) {
        var maxcnt: u32 = 0;
        if (f_a) {
            for (dircnt.values()) |cnt| if (cnt > maxcnt) {
                maxcnt = cnt;
            };
        } else {
            maxcnt = dircnt.values()[dircnt.count() - 1];
        }

        const width = fmt.count("{}", .{maxcnt});
        for (dircnt.keys(), dircnt.values()) |dname, cnt| {
            try fmt.formatInt(cnt, 10, .lower, .{ .width = width }, stdout);
            try stdout.print(" {s}\n", .{dname});
        }
    } else {
        for (dircnt.keys()) |dname| {
            try stdout.print("{s}\n", .{dname});
        }
    }

    return 0;
}
