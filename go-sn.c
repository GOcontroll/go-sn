#define _GNU_SOURCE

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

const char* usage =
"GOcontroll serial number utility v1.0.0\n" 
"Usage:\n"
"go-sn [command] \'serial-number\'\n"
"\n"
"Available commands:\n"
"read		Read the serial number from memory\n"
"write		Write a serial number to memory\n";

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

int read_serial() {
	int disk;
	
	if ((disk = get_disk()) < 0) {
		return -1;
	}

	char buffer[SN_LEN+1]; //buffer with null terminator
	if (read(disk, buffer, SN_LEN) < 0) {
		close(disk);
		fprintf(stderr, "could not read the serial number:\n%s\n", strerror(errno));
		return -1;
	}
	buffer[SN_LEN] = 0; //add null terminator
	printf("%s",buffer); //print the sn to stdout
	return 0;
}

int write_serial(char* sn) {
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

	return 0;
}

int main (int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr,"%s",usage);
		return -1;
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