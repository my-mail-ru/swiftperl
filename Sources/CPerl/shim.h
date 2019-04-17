#include <termios.h>
#include <fcntl.h>
#include <stdbool.h>
#define PERL_NO_GET_CONTEXT

// workaround for "-Xcc -D_GNU_SOURCE" on Linux
#if defined(__linux__) && !defined(_GNU_SOURCE)
typedef __off64_t off64_t;
#endif
