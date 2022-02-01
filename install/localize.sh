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
# objcopy --redefine-syms=redefinedSF $OBJ
# objcopy --redefine-syms=redefinedStrConv $OBJ

# objcopy --redefine-sym sprintf=sprintf_tase $OBJ
# objcopy --redefine-sym printf=printf_tase $OBJ
# objcopy --redefine-sym puts=puts_tase_shim $OBJ
# objcopy --globalize-symbol=a_ctz_64 $OBJ
# objcopy --globalize-symbol=a_clz_64 $OBJ
# objcopy --redefine-sym a_ctz_64=a_ctz_64_tase $OBJ
# objcopy --redefine-sym a_clz_64=a_clz_64_tase $OBJ

# objcopy --redefine-sym calloc=calloc_tase_shim $OBJ
# objcopy --redefine-sym realloc=realloc_tase_shim $OBJ
# objcopy --redefine-sym malloc=malloc_tase_shim $OBJ
# objcopy --redefine-sym free=free_tase_shim $OBJ
# objcopy --redefine-sym getc_unlocked=getc_unlocked_tase_shim $OBJ

#Changed because we now link in the definition of memcpy from musl, but still
#want to trap for efficiency.
# objcopy --redefine-sym memcpy=memcpy_tase $OBJ
# objcopy --globalize-symbol=memcpy_tase $OBJ

# objcopy --redefine-sym main=tase_project_entry $OBJ
