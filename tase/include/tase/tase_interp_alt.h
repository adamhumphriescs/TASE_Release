
typedef uint64_t tase_greg_t;


/* Number of each register in the gregs array */
#define GREG_RAX                 0
#define GREG_RBX                 1
#define GREG_RCX                 2
#define GREG_RDX                 3
#define GREG_RSI                 4
#define GREG_RDI                 5
#define GREG_RBP                 6
#define GREG_RSP                 7
#define GREG_R8                  8
#define GREG_R9                  9
#define GREG_R10                10
#define GREG_R11                11
#define GREG_R12                12
#define GREG_R13                13
#define GREG_R14                14
#define GREG_R15                15
/* Alias to support legacy single-instruction interpreter. */
#define GREG_RIP                16
#define GREG_EFL                17
/* Number of general registers.  */
#define TASE_NGREG                   18
#define TASE_GREG_SIZE                8

#define NXMMREG                 16
#define XMMREG_SIZE             16
