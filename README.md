# go-sn
Utility for writing and reading serial numbers of Moduline controllers.

The serial number is stored in a dedicated GPT partition labelled `serial`
(`/dev/disk/by-partlabel/serial`). The partition is created by the deploy
tooling and is *not* touched by `gpt write` during a re-flash, so the SN
persists through firmware updates.

For backwards compatibility with units flashed before the serial partition
was introduced, both read and write operations transparently fall back to
the last sector of `/dev/mmcblk0` when the partition is not present.

To compile with zig 0.12.0 or 0.13.0 run:
```sh
zig build
```
It will compile for the correct architecture and glibc version.

To switch between the zig version and the C version use the `-Dbuild_type` option, use `zig build -h` for more info

When compiling the C version with gcc make sure it doesn't link a glibc version greater than 2.31.