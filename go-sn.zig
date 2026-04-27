const std = @import("std");
const config = @import("config");

const BLOCK_SIZE = 512;
const SN_LEN = 19;
const SERIAL_PARTITION = "/dev/disk/by-partlabel/serial";
const LEGACY_DEVICE = "/dev/mmcblk0";

const usage =
    \\GOcontroll serial numer utility v{s}
    \\Usage:
    \\go-sn [command] 'serial-number'
    \\
    \\Available commands:
    \\[r]ead		Read the serial number from memory
    \\[w]rite		Write the 'serial-number' to memory
    \\
    \\'serial-number' must be a total of 19 characters long, and be segmented into 4 parts of 4 seperated by '-'
    \\
    \\Storage: prefers GPT partition labelled 'serial' (modern firmware),
    \\falls back to last sector of /dev/mmcblk0 (legacy units pre-serial-partition).
    \\
    \\Examples:
    \\go-sn read
    \\go-sn write 1234-5678-9012-3456
    \\
;

pub fn main() !void {
    var args = std.process.args();
    if (!args.skip()) {
        std.debug.print(usage, .{config.version});
        return;
    }
    const command = args.next() orelse {
        std.debug.print(usage, .{config.version});
        return;
    };

    if (std.ascii.startsWithIgnoreCase("read", command)) {
        try read_sn();
    } else if (std.ascii.startsWithIgnoreCase("write", command)) {
        const sn = args.next() orelse {
            std.log.err(usage, .{config.version});
            return error.InvalidArgument;
        };
        try write_sn(sn);
    } else {
        std.log.err(usage, .{config.version});
        return error.InvalidArgument;
    }
}

fn read_sn() !void {
    var sn: [SN_LEN]u8 = undefined;

    // Try the dedicated GPT serial partition first.
    if (std.fs.openFileAbsolute(SERIAL_PARTITION, .{ .mode = .read_only })) |f| {
        defer f.close();
        const bytes = try f.read(&sn);
        if (bytes == SN_LEN) {
            if (validate_sn(&sn)) |_| {
                return print_sn(&sn);
            } else |_| {
                // Partition is present but contains no valid SN (freshly flashed
                // unit, or migration-from-legacy). Fall through to legacy probe.
            }
        }
    } else |err| {
        if (err != error.FileNotFound) return err;
    }

    // Legacy fallback: last sector of /dev/mmcblk0 (pre-serial-partition firmware).
    const f = try std.fs.openFileAbsolute(LEGACY_DEVICE, .{ .mode = .read_only });
    defer f.close();
    try f.seekFromEnd(-BLOCK_SIZE);
    const bytes = try f.read(&sn);
    if (bytes != SN_LEN) {
        std.log.err("Could not read full serial number, only {} bytes read.\n", .{bytes});
        return error.IOError;
    }
    try validate_sn(&sn);
    try print_sn(&sn);
}

fn write_sn(sn: []const u8) !void {
    try validate_sn(sn);

    // Pad to a full sector with SN at offset 0, zeros after — block-device
    // friendly (avoids partial-sector read-modify-write through the buffer cache).
    var buffer = [_]u8{0} ** BLOCK_SIZE;
    @memcpy(buffer[0..SN_LEN], sn);

    // Prefer the dedicated GPT serial partition.
    if (std.fs.openFileAbsolute(SERIAL_PARTITION, .{ .mode = .read_write })) |f| {
        defer f.close();
        try f.writeAll(&buffer);
        return;
    } else |err| {
        if (err != error.FileNotFound) return err;
    }

    // Legacy fallback: last sector of /dev/mmcblk0. Note: on modern firmware
    // (with serial partition) this region is the GPT backup header — we never
    // get here in that case because the partition open above succeeded.
    const f = try std.fs.openFileAbsolute(LEGACY_DEVICE, .{ .mode = .read_write });
    defer f.close();
    try f.seekFromEnd(-BLOCK_SIZE);
    try f.writeAll(&buffer);
}

fn print_sn(sn: []const u8) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("{s}\n", .{sn});
    try bw.flush();
}

fn validate_sn(sn: []const u8) !void {
    if (sn.len != SN_LEN) {
        std.log.err("The serial number has to be 19 characters long.\n", .{});
        return error.InvalidArgument;
    }
    var segments = std.mem.splitSequence(u8, sn, "-");
    while (segments.next()) |segment| {
        if (segment.len != 4) {
            std.log.err("Each segment of the of the serial number should contain 4 characters\n", .{});
            return error.InvalidArgument;
        }
    }
}
