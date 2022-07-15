// This is in a separate file because it needs to be instrumented.
// It is essentially a "modeled" function - it causes an ejection
// to the interpreter.
#include "tase.h"
#include <stdnoreturn.h>
#include <stdio.h>
#include <stdlib.h>

void noreturn exit_tase() {
  /* TODO: Log things? */
  printf("Exit Tase: exiting.\n");
  exit(0);
}
