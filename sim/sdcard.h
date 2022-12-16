#ifndef __SDCARD_H
#define __SDCARD_H

#include <stdint.h>

void sdcard_init(const char *diskfn);

int sdcard_handle(uint8_t dat);


#endif
