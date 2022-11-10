#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <stdlib.h>
#include "console.h"

static struct termios old_tio;
static int opts;

void console_reset(void) {
	tcsetattr(STDIN_FILENO,TCSANOW,&old_tio);
    fcntl(STDIN_FILENO, F_SETFL, opts);
}

void console_init(void) {
	struct termios new_tio;
    opts = fcntl(STDIN_FILENO, F_GETFL);
    fcntl(STDIN_FILENO, F_SETFL, opts | O_NONBLOCK);
	tcgetattr(STDIN_FILENO, &old_tio);
	new_tio=old_tio;
	new_tio.c_lflag &= (~ICANON & ~ECHO); // echo off and no buffering
	tcsetattr(STDIN_FILENO,TCSANOW, &new_tio);
	atexit(&console_reset);
}

char console_getc(void) {
    return getchar();
}
