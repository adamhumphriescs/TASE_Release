set -e

rm -f ./build/*

MUSL_PATH="../../musl"
pushd $MUSL_PATH
cp ./TASEConfig/config.mak_no_simd ./config.mak
./getTASELibcSubset.sh
popd

#String 
#Has external deps on tase_springboard, tolower, malloc_tase
STRLIBS="memchr memcmp memcpy memmove memset strcasecmp strcat strchr strcmp strcpy strdup strlen strncasecmp strncmp strncpy strrchr strstr strtok stpcpy stpncpy strspn strcspn memrchr strchrnul"

CTLIBS=" isalnum isxdigit tolower "

STDLIBS=" atoi "

NETLIBS=" htonl htons ntohl ntohs "

for STRLIB in $STRLIBS
do
    cp $MUSL_PATH/obj/src/string/$STRLIB.o ./build/
done

#Ctype
for CTLIB in $CTLIBS
do
    cp $MUSL_PATH/obj/src/ctype/$CTLIB.o ./build/
done

#Stdlib

for STDLIB in $STDLIBS 
do
    cp $MUSL_PATH/obj/src/stdlib/$STDLIB.o ./build/
done

#Network
#These are all pure

for NETLIB in $NETLIBS
do
    cp $MUSL_PATH/obj/src/network/$NETLIB.o ./build/
done

#MATH
cp $MUSL_PATH/obj/src/math/*.o ./build/
cp $MUSL_PATH/obj/src/fenv/fenv.o ./build/
cp $MUSL_PATH/obj/src/fenv/fesetround.o ./build/

rm -f libtasec.a

ar -r libtasec.a ./build/*.o

