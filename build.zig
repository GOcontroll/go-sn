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
        // .root_source_file = .{ .cwd_relative = "go-sn.zig" }, //the zig version of this program is a bit more than twice the size 6kb vs 14 kb
        .target = target,
        .version = .{ .major = 1, .minor = 0, .patch = 1 },
        .optimize = .ReleaseSmall,
        .link_libc = true,
        .strip = true,
    });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "go-sn.c" } });

    b.installArtifact(exe);
}
