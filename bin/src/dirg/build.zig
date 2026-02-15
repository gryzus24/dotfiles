const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "dirg",
        .root_module = b.createModule(.{
            .root_source_file = b.path("dirg.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
            .strip = true,
            .single_threaded = true,
            .omit_frame_pointer = true,
            .link_libc = false,
            .link_libcpp = false,
        }),
    });
    b.installArtifact(exe);
}
