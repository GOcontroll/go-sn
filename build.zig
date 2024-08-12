const std = @import("std");

const BuildType = enum {
    c,
    zig,
};

const version = "1.0.2";

pub fn build(b: *std.build.Builder) !void {
    const options = b.addOptions();

    const build_type = b.option(BuildType, "build_type", "Whether to build the C or Zig version, default is C") orelse .c;
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .abi = .gnu,
            .os_tag = .linux,
            .glibc_version = .{ .major = 2, .minor = 31, .patch = 0 },
            .cpu_arch = .aarch64,
        },
    });
    const semver = try std.builtin.Version.parse(version);
    //const semver = try std.SemanticVersion.parse(version);

    switch (build_type) {
        .zig => { //build the zig version
            var exe = b.addExecutable("go-sn", "go-sn.zig");

            exe.target = target;
            exe.linkLibC();
            exe.build_mode = .ReleaseSmall;
            exe.strip = true;
            exe.version = semver;
            options.addOption([]const u8, "version", version);
            exe.addOptions("config", options);
            b.installArtifact(exe);
        },
        .c => { //build the c version
            var exe = b.addExecutable("go-sn", "go-sn.c");
            exe.target = target;
            exe.linkLibC();
            exe.build_mode = .ReleaseSmall;
            exe.strip = true;
            exe.version = semver;
            exe.defineCMacro("VERSION", version);
            b.installArtifact(exe);
        },
    }
}
