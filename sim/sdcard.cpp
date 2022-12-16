#include "sdcard.h"
#include <cstdio>
#include <cstring>

enum cardstate_t {
    POWERUP,
    IDLE,
    READY,
};

static cardstate_t state;

static uint8_t recbuf[6];
static uint8_t recbuf_idx = 0;

/*
CMD0 40 00 00 00 00 95 - R: ff 01 ff ff ff ff ff ff
CMD8 48 00 00 01 00 d5 - R: ff 01 00 00 01 00 ff ff
V2.00 or later SD memory card
CMD58 7a 00 00 00 00 fd - R: ff 01 00 ff 80 00 ff ff
CMD41 69 40 00 00 00 77 - R: ff 01 ff ff ff ff ff ff
CMD41 69 40 00 00 00 77 - R: ff 00 ff ff ff ff ff ff
CMD58 7a 00 00 00 00 fd - R: ff 00 c0 ff 80 00 ff ff
SDHC or SDUC card (ccs=1)
*/

const uint8_t cmd0[] = {0x40, 0x00, 0x00, 0x00, 0x00, 0x95};

static int is_valid_cmd0(uint8_t *cmd) {
    return strncmp((const char*)cmd0, (const char*)cmd, 6);
}

void sdcard_init(const char *diskfn) {
    state = POWERUP;
    recbuf_idx = 0;
}

int sdcard_handle(uint8_t dat) {
    if ((recbuf_idx == 0) && (dat == 0xff)) {
        return 0xff;
    }
    recbuf[recbuf_idx] = dat;
    if (recbuf_idx < 6) {
        printf("%d: %02x\n", recbuf_idx, dat);
        recbuf_idx++;
        if (recbuf_idx < 6) {
            return 0xff;
        }
    }
    switch(state) {
        case POWERUP:
            if (is_valid_cmd0(recbuf) == 0) {
                state = IDLE;
                recbuf_idx = 0;
                printf("SD: change to IDLE\n");
            }
        break;
        case IDLE:
        break;
        default:;
    }
    return 0xff;
}
