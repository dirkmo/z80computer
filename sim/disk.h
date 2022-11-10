#ifndef _DISK_H
#define _DISK_H

#include <stdint.h>

void disk_sector_write(uint32_t sec, uint8_t dat);
uint8_t disk_sector_read(uint32_t sec);
int disk_init(const char *fn, uint16_t spt);

#endif
