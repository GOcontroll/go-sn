const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "go-sn",
        .root_source_file = .{ .path = "go-sn.c" },
        .target = std.zig.CrossTarget{
            .os_tag = .linux,
            .cpu_arch = .aarch64,
            .abi = .gnu,
            .glibc_version = std.SemanticVersion{ .major = 2, .minor = 31, .patch = 0 },
        },
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
        .optimize = std.builtin.OptimizeMode.ReleaseSmall,
    });

    exe.linkLibC();

    b.installArtifact(exe);
}
