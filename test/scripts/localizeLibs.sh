set -e

BUILD_DIR=$1
LIBTASEC_PATH=$2

#TASE_DIR=/playpen/humphries/TASE/TASE/test/tase
#TASE_CLANG=/playpen/humphries/TASE/TASE/install_root/bin/clang
#MODELED_FN_ARG="-mllvm -x86-tase-modeled-functions=$TASE_DIR/include/tase/core_modeled.h"

pushd $LIBTASEC_PATH
./getclibs.sh
popd

cp $LIBTASEC_PATH/libtasec.a $BUILD_DIR/
pushd $BUILD_DIR
ar -x libtasec.a
popd

#$TASE_CLANG -c -O1 $MODELED_FN_ARG /playpen/humphries/TASE/TASE/test/libtasessl/misc/qsort.c -o $BUILD_DIR/qsort.o

ld -r $BUILD_DIR/*.o -o $BUILD_DIR/everything.o
#nm everything.o | grep  "[0-9a-f] [tTdDgGrRsSvVwWC] " | cut -f3 -d ' ' > targetsyms

STRLIBS="memchr memcmp memcpy memmove memset strcasecmp strcat strchr strcmp strcpy strdup strlen strncasecmp strncmp strncpy\
 strrchr strstr strtok stpcpy stpncpy \
strspn strcspn memrchr strchrnul"
CTLIBS=" isalnum isxdigit tolower "
#qsort from musl has a bsf instruction unfortunately
STDLIBS=" atoi qsort qsort_r "
NETLIBS=" htonl htons ntohl ntohs "

WEAKS_AND_STATICS=" __isspace __bswap_32 __bswap_16 __isalnum_l isalnum_l __isxdigit_l isdigit_l a_ctz_64  a_ctz_l  cycle  pn\
tz  shl  shr  sift  trinkle __strcasec\
mp_l strcasecmp_l  __strncasecmp_l  strncasecmp_l threebyte_strstr  twobyte_strstr twoway_strstr __tolower_l  tolower_l "

for LIB in $STRLIBS $CTLIBS $STDLIBS $NETLIBS $WEAKS_AND_STATICS
do
    objcopy --localize-symbol=$LIB $BUILD_DIR/everything.o
    done
