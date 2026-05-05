const std = @import("std");

const usage =
    \\usage: dirg [a] [c] [h] <newline delimited paths from stdin>
    \\  a  sort alphabetically
    \\  c  show file count per directory
    \\  h  display this help and exit
    \\
;

pub fn IndexIterator(comptime T: type, findme: T) type {
    return struct {
        buf: []const T,
        i: usize,
        bits: std.meta.Int(.unsigned, BlockSize),

        const BlockSize = @min(64, 2 * (std.simd.suggestVectorLength(T) orelse 8));
        const Block = @Vector(BlockSize, T);

        pub fn init(buf: []const T) @This() {
            return .{ .buf = buf, .i = 0, .bits = 0 };
        }

        inline fn nextBit(self: *@This(), i: usize) usize {
            const lsb = self.bits & (~self.bits + 1);
            const j = @ctz(self.bits);
            self.bits ^= lsb;
            self.i = i + @intFromBool(self.bits == 0) * @as(usize, BlockSize);
            return i + j;
        }

        pub fn next(self: *@This()) ?usize {
            var i = self.i;
            if (self.bits != 0)
                return self.nextBit(i);

            const len = self.buf.len;
            while (i < len & ~@as(usize, BlockSize - 1)) : (i += BlockSize) {
                const block: Block = self.buf[i..][0..BlockSize].*;
                const mask = block == @as(Block, @splat(findme));
                if (@reduce(.Or, mask)) {
                    self.bits = @bitCast(mask);
                    return self.nextBit(i);
                }
            }
            while (i < len) : (i += 1) {
                if (self.buf[i] == findme) {
                    self.i = i + 1;
                    return i;
                }
            }
            self.i = len;
            return null;
        }
    };
}

fn write(writer: *std.Io.Writer, s: []const u8) void {
    _ = writer.write(s) catch {};
}

fn isFile_lstat_amd64(path: [*:0]const u8) bool {
    var statbuf: [144]u8 = undefined;
    const ret = std.os.linux.syscall2(
        std.os.linux.SYS.lstat,
        @intFromPtr(path),
        @intFromPtr(&statbuf),
    );
    return (ret == 0 and
        std.c.S.ISREG(std.mem.bytesAsValue(std.c.mode_t, statbuf[24..28]).*));
}

pub fn main(init: std.process.Init) void {
    errdefer std.process.exit(1);

    const alloc = init.arena.allocator();
    const io = init.io;

    var out_buf: [1 << 16]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &out_buf);
    const out = &writer.interface;
    defer out.flush() catch {};

    var f_a = false;
    var f_c = false;
    for (init.minimal.args.vector[1..]) |arg| {
        var i: usize = 0;
        while (arg[i] != 0) : (i += 1) switch (arg[i]) {
            'a' => f_a = true,
            'c' => f_c = true,
            'h' => return write(out, usage),
            else => {},
        };
    }

    var in = std.Io.File.stdin().reader(io, &.{});
    const reader = &in.interface;

    var data: std.ArrayList(u8) = .empty;
    try reader.appendRemainingUnlimited(alloc, &data);
    try data.append(alloc, '\n');

    var dir_count: std.StringArrayHashMapUnmanaged(u32) = .empty;

    var last: usize = 0;
    var it: IndexIterator(u8, '\n') = .init(data.items);
    while (it.next()) |nl| {
        const line = data.items[last..nl];
        last = nl + 1;
        data.items[nl] = 0;

        if (isFile_lstat_amd64(line.ptr[0..line.len :0])) {
            if (std.fs.path.dirname(line)) |dir| {
                const entry = try dir_count.getOrPutValue(alloc, dir, 1);
                if (entry.found_existing)
                    entry.value_ptr.* += 1;
            }
        }
    }
    if (dir_count.count() == 0)
        return;

    if (f_a) {
        const SortCtx = struct {
            dirs: []const []const u8,

            pub fn lessThan(self: @This(), a: usize, b: usize) bool {
                switch (std.mem.order(u8, self.dirs[a], self.dirs[b])) {
                    .eq => unreachable,
                    .lt => return true,
                    .gt => return false,
                }
            }
        };
        dir_count.sort(SortCtx{ .dirs = dir_count.keys() });
    } else {
        const SortCtx = struct {
            counts: []u32,

            pub fn lessThan(self: @This(), a: usize, b: usize) bool {
                return self.counts[a] < self.counts[b];
            }
        };
        dir_count.sort(SortCtx{ .counts = dir_count.values() });
    }

    if (f_c) {
        var max: u32 = 0;
        if (f_a) {
            for (dir_count.values()) |cnt| {
                max = @max(max, cnt);
            }
        } else {
            max = dir_count.values()[dir_count.count() - 1];
        }

        const width = std.fmt.count("{d}", .{max});
        for (dir_count.keys(), dir_count.values()) |dir, cnt| {
            out.printIntAny(cnt, 10, .lower, .{ .width = width }) catch {};
            out.print(" {s}\n", .{dir}) catch {};
        }
    } else {
        for (dir_count.keys()) |dir| {
            out.print("{s}\n", .{dir}) catch {};
        }
    }
}
