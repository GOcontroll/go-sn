const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .gnu,
        .glibc_version = std.SemanticVersion{ .major = 2, .minor = 31, .patch = 0 },
    });
    const exe = b.addExecutable(.{
        .name = "go-sn",
        //.root_source_file = .{ .path = "go-sn.c" },
        .target = target,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
        .optimize = std.builtin.OptimizeMode.ReleaseSmall,
        .link_libc = true,
        .strip = true,
    });
    exe.addCSourceFile(std.Build.Module.CSourceFile{ .file = .{ .path = "go-sn.c" } });

    b.installArtifact(exe);
}
