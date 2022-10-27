set -e

OBJ="$1"

objcopy --localize-hidden $OBJ
objcopy --localize-symbols=libtasec.syms $OBJ
objcopy --redefine-syms=redefinedSF $OBJ
objcopy --redefine-syms=redefinedStrConv $OBJ
objcopy --globalize-symbols=taseglob $OBJ
objcopy --redefine-syms=tase $OBJ

#These are some symbol redefinition hacks that help us link in much of
#libc from musl.  Specifically, the a_ctz_64 and a_clz_64 functions have
#bsr instructions when they're compiled in TASE, so we just trap on those for now
#and use a model in KLEE.
