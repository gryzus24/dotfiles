const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "dirg",
        .root_source_file = b.path("./dirg.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
        .strip = true,
    });
    b.installArtifact(exe);
}
