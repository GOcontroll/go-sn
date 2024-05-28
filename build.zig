const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .gnu,
        .glibc_version = .{ .major = 2, .minor = 31, .patch = 0 },
    });
    const exe = b.addExecutable(.{
        .name = "go-sn",
        .target = target,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
        .optimize = .ReleaseSmall,
        .link_libc = true,
        .strip = true,
    });
    exe.addCSourceFile(.{ .file = .{ .path = "go-sn.c" } });

    b.installArtifact(exe);
}
