const std = @import("std");

const BLOCK_SIZE = 512;
const SN_LEN = 19;

const usage =
    \\GOcontroll serial numer utility v1.0.0
    \\Usage:
    \\go-sn [command] 'serial-number'
    \\
    \\Available commands:
    \\read		Read the serial number from memory
    \\write		Write the 'serial-number' to memory
    \\
;

pub fn main() !void {
    var args = std.process.args();
    if (!args.skip()) {
        std.debug.print(usage, .{});
        return;
    }
    const command = args.next() orelse {
        std.debug.print(usage, .{});
        return;
    };

    if (std.ascii.startsWithIgnoreCase("read", command)) {
        try read_sn();
    } else if (std.ascii.startsWithIgnoreCase("write", command)) {
        const sn = args.next() orelse {
            std.debug.print(usage, .{});
            return error.InvalidArgument;
        };
        if (sn.len != SN_LEN) {
            std.debug.print("The serial number has to be 19 characters long.\n", .{});
            return error.InvalidArgument;
        }
        try write_sn(sn);
    } else {
        std.debug.print(usage, .{});
        return;
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
    std.debug.print("{s}", .{sn});
}

fn write_sn(sn: []const u8) !void {
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
