#include "disk.h"
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

static uint32_t g_dts = 0xffffffff; // dts=disk track sector
static uint32_t g_secpos = 0;
static const char *disk_fn = NULL;
static uint8_t *diskbuf = NULL;
static size_t disk_size = 0;

static uint16_t sectors_per_track = 0;

void disk_exit(void) __attribute__((destructor));

static void decode_sector(uint32_t dts, uint8_t *disk, uint16_t *track, uint8_t *sector) {
    // disk, track_lo, track_hi, sector
    *disk = (dts >> 24) & 0xf;
    *track = (dts >> 8) & 0xff00;
    *track = (dts >> 16) & 0xff;
    *sector = dts & 0xff;
}

void disk_sector_write(uint32_t dts, uint8_t dat) {
    uint8_t disk, sector;
    uint16_t track;
    decode_sector(dts, &disk, &track, &sector);
    if (dts != g_dts) {
        g_dts = dts;
        g_secpos = 0;
        // printf("write disk: %u, track: $%x, sector: $%x\n", disk, track, sector);
    }
    uint32_t addr = (sectors_per_track*track+sector) * 128 + g_secpos;
    assert(addr < disk_size);
    diskbuf[addr] = dat;
    g_secpos = (g_secpos+1) % 128;
}

uint8_t disk_sector_read(uint32_t dts) {
    uint8_t disk, sector;
    uint16_t track;
    decode_sector(dts, &disk, &track, &sector);
    if (dts != g_dts) {
        g_dts = dts;
        g_secpos = 0;
        // printf("read disk: %u, track: $%x, sector: $%x\n", disk, track, sector);
    }
    uint32_t addr = (sectors_per_track*track+sector) * 128 + g_secpos;
    assert(addr < disk_size);
    uint8_t dat = diskbuf[addr];
    g_secpos = (g_secpos+1) % 128;
    return dat;
}

int disk_init(const char *fn, uint16_t spt) {
    disk_fn = fn;
    sectors_per_track = spt;
    FILE *f = fopen(fn, "r");
    if (f == NULL) {
        fprintf(stderr, "ERROR: %s\n", strerror(errno));
        return -1;
    }
    fseek(f, 0, SEEK_END);
    disk_size = ftell(f);
    fseek(f, 0, SEEK_SET);
    diskbuf = new uint8_t[disk_size];
    fread(diskbuf, disk_size, 1, f);
    fclose(f);
    return 0;
}

void disk_exit(void) {
    // if (disk_fn) {
    //     FILE *f = fopen(disk_fn, "w");
    //     fwrite(diskbuf, disk_size, 1, f);
    //     fclose(f);
    // }
    if (diskbuf) {
        delete[] diskbuf;
    }
}
