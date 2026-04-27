#define _GNU_SOURCE //enable the strcasestr function from string.h

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>

#define BLOCK_SIZE 512
#define SN_LEN 19
#define SERIAL_PARTITION "/dev/disk/by-partlabel/serial"
#define LEGACY_DEVICE "/dev/mmcblk0"

#ifndef VERSION
#error "VERSION must be passed in by command: -DVERSION=<version>"
#endif

#define stringify_(x) #x
#define stringify(x) stringify_(x)

const char* usage =
"GOcontroll serial number utility v" stringify(VERSION) "\n"
"Usage:\n"
"go-sn [command] \'serial-number\'\n"
"\n"
"Available commands:\n"
"[r]ead		Read the serial number from memory\n"
"[w]rite		Write the 'serial-number' to memory\n"
"\n"
"'serial-number' must be a total of 19 characters long, and be segmented into 4 parts of 4 seperated by '-'\n"
"\n"
"Storage: prefers GPT partition labelled 'serial' (modern firmware),\n"
"falls back to last sector of /dev/mmcblk0 (legacy units pre-serial-partition).\n"
"\n"
"Examples:\n"
"go-sn read\n"
"go-sn write 1234-5678-9012-3456\n";

int validate_serial(char* sn) {
	if (strlen(sn) != SN_LEN) {
		fprintf(stderr, "The serial number has to be 19 characters long.\n");
		return -1;
	}
	for (int i = 0; i < SN_LEN; i++) { // sn is already verified to be SN_LEN long
		if ((sn[i] == '-') && (((i+1) % 5) != 0)) { //check if every - is at the proper position
			fprintf(stderr, "Each segment of the of the serial number should contain 4 characters\n");
			return -1;
		}
		if ((sn[i] != '-') && (((i+1) % 5) == 0)) { //check if every - position contains a -
			fprintf(stderr, "Each segment of the of the serial number should contain 4 characters\n");
			return -1;
		}
	}
	return 0;
}

// Open /dev/mmcblk0 and seek to the last sector. Used as legacy fallback when
// the dedicated GPT serial partition is not present (pre-migration firmware).
static int open_legacy(int flags) {
	int disk = open(LEGACY_DEVICE, flags);
	if (disk < 0) {
		fprintf(stderr, "Unable to open block device:\n%s\n", strerror(errno));
		return -1;
	}
	if (lseek(disk, -BLOCK_SIZE, SEEK_END) < 0) {
		close(disk);
		fprintf(stderr, "Could not seek to legacy serial number address:\n%s\n", strerror(errno));
		return -1;
	}
	return disk;
}

int read_serial() {
	char buffer[SN_LEN+1]; //buffer with null terminator

	// Try the dedicated GPT serial partition first.
	int disk = open(SERIAL_PARTITION, O_RDONLY);
	if (disk >= 0) {
		ssize_t bytes = read(disk, buffer, SN_LEN);
		close(disk);
		if (bytes == SN_LEN) {
			buffer[SN_LEN] = 0;
			if (validate_serial(buffer) == 0) {
				printf("%s\n", buffer);
				return 0;
			}
			// Partition is present but contains no valid SN (freshly flashed
			// unit, or migration-from-legacy). Fall through to legacy probe.
		}
	} else if (errno != ENOENT) {
		fprintf(stderr, "Unable to open serial partition:\n%s\n", strerror(errno));
		return -1;
	}

	// Legacy fallback.
	disk = open_legacy(O_RDONLY);
	if (disk < 0) {
		return -1;
	}
	ssize_t bytes = read(disk, buffer, SN_LEN);
	close(disk);
	if (bytes < 0) {
		fprintf(stderr, "Could not read the serial number:\n%s\n", strerror(errno));
		return -1;
	}
	if (bytes != SN_LEN) {
		fprintf(stderr, "Could not read full serial number, only %zd bytes read.\n", bytes);
		return -1;
	}
	buffer[SN_LEN] = 0;
	if (validate_serial(buffer) != 0) {
		return -1;
	}
	printf("%s\n", buffer); //print the sn to stdout
	return 0;
}

int write_serial(char* sn) {
	if (validate_serial(sn)) {
		return -1;
	}
	// Pad to a full sector with SN at offset 0, zeros after — block-device
	// friendly (avoids partial-sector read-modify-write through buffer cache).
	char buffer[BLOCK_SIZE] = {0};
	strncpy(buffer, sn, SN_LEN);

	// Prefer the dedicated GPT serial partition.
	int disk = open(SERIAL_PARTITION, O_RDWR);
	if (disk >= 0) {
		ssize_t bytes = write(disk, buffer, BLOCK_SIZE);
		close(disk);
		if (bytes != BLOCK_SIZE) {
			fprintf(stderr, "Could not write full block to serial partition.\n");
			return -1;
		}
		return 0;
	}
	if (errno != ENOENT) {
		fprintf(stderr, "Unable to open serial partition:\n%s\n", strerror(errno));
		return -1;
	}

	// Legacy fallback. Note: on modern firmware (with serial partition)
	// this region is the GPT backup header — we never get here in that
	// case because the partition open above succeeded.
	disk = open_legacy(O_RDWR);
	if (disk < 0) {
		return -1;
	}
	ssize_t bytes = write(disk, buffer, BLOCK_SIZE);
	close(disk);
	if (bytes != BLOCK_SIZE) {
		fprintf(stderr, "Could not write full block to legacy location.\n");
		return -1;
	}
	return 0;
}

int main (int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr,"%s",usage);
		return 0;
	}
	if (strcasestr("read", argv[1]) != NULL) {
		return read_serial();
	} else if (strcasestr("write", argv[1]) != NULL) {
		if (argc != 3) {
			fprintf(stderr,"%s", usage);
			return -1;
		}
		return write_serial(argv[2]);
	}
}
