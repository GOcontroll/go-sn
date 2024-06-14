const std = @import("std");

const BLOCK_SIZE = 512;
const SN_LEN = 19;

const usage =
    \\GOcontroll serial numer utility v1.0.1
    \\Usage:
    \\go-sn [command] 'serial-number'
    \\
    \\Available commands:
    \\[r]ead		Read the serial number from memory
    \\[w]rite		Write the 'serial-number' to memory
    \\
    \\'serial-number' must be a total of 19 characters long, and be segmented into 4 parts of 4 seperated by '-'
    \\
    \\Examples:
    \\go-sn read
    \\go-sn write 1234-5678-9012-3456
;

pub fn main() !void {
    var args = std.process.args();
    if (!args.skip()) {
        std.debug.print(usage, .{});
        return error.InvalidArgument;
    }
    const command = args.next() orelse {
        std.debug.print(usage, .{});
        return error.InvalidArgument;
    };

    if (std.ascii.startsWithIgnoreCase("read", command)) {
        try read_sn();
    } else if (std.ascii.startsWithIgnoreCase("write", command)) {
        const sn = args.next() orelse {
            std.debug.print(usage, .{});
            return error.InvalidArgument;
        };
        try write_sn(sn);
    } else {
        std.debug.print(usage, .{});
        return error.InvalidArgument;
    }
}

fn read_sn() !void {
    const disk = try get_disk();
    defer disk.close();
    var sn = [_]u8{0} ** 19;
    const bytes = try disk.read(&sn);
    if (bytes != 19) {
        std.debug.print("Could not read full serial number, only {} bytes read.\n", .{bytes});
        return error.IOError;
    }
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("{s}\n", .{sn});
    try bw.flush();
}

fn write_sn(sn: []const u8) !void {
    if (sn.len != SN_LEN) {
        std.debug.print("The serial number has to be 19 characters long.\n", .{});
        return error.InvalidArgument;
    }
    var segments = std.mem.split(u8, sn, "-");
    while (segments.next()) |segment| {
        if (segment.len != 4) {
            std.debug.print("Each segment of the of the serial number should contain 4 characters", .{});
            return error.InvalidArgument;
        }
    }
    const disk = try get_disk();
    defer disk.close();
    const bytes = try disk.write(sn);
    if (bytes != 19) {
        std.debug.print("Could not write full serial number, only {} bytes written.\n", .{bytes});
        return error.IOError;
    }
}

fn get_disk() !std.fs.File {
    const disk = try std.fs.openFileAbsolute("/dev/mmcblk0", .{ .mode = .read_write });
    try disk.seekFromEnd(-BLOCK_SIZE);
    return disk;
}
