const std = @import("std");

const BuildType = enum {
    c,
    zig,
};

const version = "1.0.2";

pub fn build(b: *std.Build) !void {
    const options = b.addOptions();
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .gnu,
        .glibc_version = .{ .major = 2, .minor = 31, .patch = 0 },
    } });
    const build_type = b.option(BuildType, "build_type", "Whether to build the C or Zig version, default is Zig") orelse .zig;

    // const target = b.resolveTargetQuery(.{
    //     .cpu_arch = .aarch64,
    //     .os_tag = .linux,
    //     .abi = .gnu,
    //     .glibc_version = .{ .major = 2, .minor = 31, .patch = 0 },
    // });

    const semver = try std.SemanticVersion.parse(version);

    switch (build_type) {
        .zig => { //build the zig version
            const exe = b.addExecutable(.{
                .name = "go-sn",
                .root_source_file = .{ .cwd_relative = "go-sn.zig" }, //the zig version of this program is a bit more than twice the size 6kb vs 14 kb
                .target = target,
                .version = semver,
                .optimize = .ReleaseSmall,
                .link_libc = true,
                .strip = true,
            });
            options.addOption([:0]const u8, "version", version); //add executable version to the "config" module
            exe.root_module.addOptions("config", options);
            b.installArtifact(exe);
        },
        .c => { //build the c version
            const exe = b.addExecutable(.{
                .name = "go-sn",
                .target = target,
                .version = semver,
                .optimize = .ReleaseSmall,
                .link_libc = true,
                .strip = true,
            });
            exe.root_module.addCMacro("VERSION", version); //add executable version as a #define
            exe.addCSourceFile(.{ .file = .{ .cwd_relative = "go-sn.c" } });
            b.installArtifact(exe);
        },
    }
}
