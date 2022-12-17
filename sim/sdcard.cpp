#include "sdcard.h"
#include <cstdio>
#include <cstring>

enum cardstate_t {
    POWERUP,
    IDLE,
    READY,
};

union R1 {
    struct {
        unsigned in_idle_state: 1;
        unsigned erase_reset : 1;
        unsigned illegal_command : 1;
        unsigned com_crc_error : 1;
        unsigned erase_sequence_error : 1;
        unsigned address_error : 1;
        unsigned parameter_error : 1;
        unsigned reserved0: 1;
    } bits;
    uint8_t val;
};

static cardstate_t state;

static uint8_t recbuf[6];
static uint8_t recbuf_idx = 0;
static int appcmd = 0;

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
const uint8_t cmd8[] = {0x48, 0x00, 0x00, 0x01, 0x00, 0xd5 };
// no crc for the other cmds...
const uint8_t cmd17[] = { 0x51, 0x00, 0x01, 0x00, 0x00 };
const uint8_t cmd24[] = { 0x58, 0x00, 0x01, 0x00, 0x00 };
const uint8_t cmd41[] = { 0x69, 0x40, 0x00, 0x00, 0x00 };
const uint8_t cmd55[] = { 0x77, 0x00, 0x00, 0x00, 0x00 };
const uint8_t cmd58[] = { 0x7a, 0x00, 0x00, 0x00, 0x00 };

static int return_r1() {
    R1 r1 {0};
    r1.bits.in_idle_state = (state == IDLE);
    return r1.val;
}

static int illegal_cmd() {
    R1 r1 {0};
    r1.bits.in_idle_state = (state == IDLE);
    r1.bits.illegal_command = 1;
    return r1.val;
}

static int cmd0_handle(uint8_t *cmd, uint8_t *idx) {
    if (appcmd) {
        return illegal_cmd();
    }
    if (*idx == 8) {
        if (strncmp((const char*)cmd0, (const char*)cmd, sizeof(cmd0)) == 0) {
            state = IDLE;
            printf("CMD0: IDLE\n");
            *idx = 0;
            return return_r1();
        }
    }
    return 0xff;
}

static int cmd8_handle(uint8_t *cmd, uint8_t *idx) {
    if (*idx == 8) {
        if (strncmp((const char*)cmd8, (const char*)cmd, sizeof(cmd8)) == 0) {
            printf("CMD8\n");
            *idx = 0;
            return return_r1();
        }
    }
    return 0xff;
}

static int cmd55_handle(uint8_t *cmd, uint8_t *idx) {
    if (*idx == 8) {
        if (strncmp((const char*)cmd55, (const char*)cmd, 5) == 0) {
            printf("CMD55\n");
            *idx = 0;
            appcmd = 1;
            return return_r1();
        }
    }
    return 0xff;
}

static int cmd41_handle(uint8_t *cmd, uint8_t *idx) {
    static int retry = 3;
    if (*idx == 8) {
        printf("CMD41\n");
        if (!appcmd) {
            R1 r1 {0}; r1.bits.illegal_command = 1;
            return r1.val;
        }
        appcmd = 0;
        if (strncmp((const char*)cmd41, (const char*)cmd, 5) == 0) {
            *idx = 0;
            if (retry == 0) {
                state = READY;
                printf("READY\n");
            } else {
                retry--;
            }
            return return_r1();
        }
    }
    return 0xff;
}

static int cmd58_handle(uint8_t *cmd, uint8_t *idx) {
    printf("CMD58\n");
    return 0xff;
}

void sdcard_init(const char *diskfn) {
    state = POWERUP;
    recbuf_idx = 0;
}

int sdcard_handle(uint8_t dat) {
    int ret = 0xff;
    if ((recbuf_idx == 0) && (dat == 0xff)) {
        return 0xff;
    }
    if (recbuf_idx < 6) {
        recbuf[recbuf_idx] = dat;
    }
    recbuf_idx++;
    printf("%d: %02x\n", recbuf_idx, dat);
    if (recbuf_idx < 7) {
        return 0xff;
    }

    if ((recbuf[0] & 0xc0) == 0x40) {
        switch (recbuf[0] & 0x3f) {
            case 0: ret = cmd0_handle(recbuf, &recbuf_idx); break;
            case 8: ret = cmd8_handle(recbuf, &recbuf_idx); break;
            case 41: ret = cmd41_handle(recbuf, &recbuf_idx); break;
            case 55: ret = cmd55_handle(recbuf, &recbuf_idx); break;
            case 58: ret = cmd58_handle(recbuf, &recbuf_idx); break;
            default: ret = 0xff;
        }
    }

    return ret;
}