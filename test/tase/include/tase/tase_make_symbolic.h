
//C header file for making a byte symbolic in TASE.  Very similar to "klee_make_symbolic"
//in vanilla KLEE.

void tase_make_symbolic (void * ptr, unsigned long size, const char * name) __attribute__ ((optnone));
