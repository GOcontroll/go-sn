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
"Examples:\n"
"go-sn read\n"
"go-sn write 1234-5678-9012-3456\n";

int get_disk() {
	int disk;
	if ((disk = open("/dev/mmcblk0", O_RDWR)) < 0) {
		fprintf(stderr, "Unable to open block device:\n%s\n", strerror(errno));
		return -1;
	}
	if (lseek(disk, -BLOCK_SIZE, SEEK_END) < 0) {
		close(disk);
		fprintf(stderr, "Could not seek to serial number address:\n%s\n", strerror(errno));
		return -1;
	}
	return disk;
}

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

int read_serial() {
	int disk;
	if ((disk = get_disk()) < 0) {
		return -1;
	}
	char buffer[SN_LEN+1]; //buffer with null terminator
	ssize_t bytes;
	if ((bytes = read(disk, buffer, SN_LEN)) < 0) {
		close(disk);
		fprintf(stderr, "Could not read the serial number:\n%s\n", strerror(errno));
		return -1;
	}
	if (bytes != 19) {
		fprintf(stderr, "Could not read full serial number, only %d bytes read.\n", bytes);
		return -1;
	}
	buffer[SN_LEN] = 0; //add null terminator
	if (validate_serial(buffer)) {
		return -1;
	}
	printf("%s\n",buffer); //print the sn to stdout
	close(disk);
	return 0;
}

int write_serial(char* sn) {
	if (validate_serial(sn)) {
		return -1;
	}
	int disk;
	if ((disk = get_disk()) < 0) {
		return -1;
	}
	char buffer[BLOCK_SIZE] = {0};
	strncpy(buffer, sn, SN_LEN);
	if (write(disk, buffer, BLOCK_SIZE) < 0) {
		close(disk);
		fprintf(stderr,"Could not write the serial number to memory:\n%s\n", strerror(errno));
		return -1;
	}
	close(disk);
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
