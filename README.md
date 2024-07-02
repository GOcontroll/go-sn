# go-sn
Utility for writing and reading serial numbers of Moduline controllers.

This utility works by writing a serial number to an area of eMMC memory that is not mapped by the filesystem, because of this it persists through reflashes.

To compile with zig 0.12.0 or 0.13.0 run:
```sh
zig build
```
It will compile for the correct architecture and glibc version.

To switch between the zig version and the C version use the `-Dbuild_type` option, use `zig build -h` for more info

When compiling the C version with gcc make sure it doesn't link a glibc version greater than 2.31.