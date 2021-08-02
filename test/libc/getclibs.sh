#We grab a subset of the libc functions in this script, including everything in string, ctype,
#errno, math.  We also get most of stdlib, with the remaining functions covered via traps in the interpreter.

set -e

rm -f ./build/*

MUSL_PATH="../../musl"
pushd $MUSL_PATH
cp ./TASEConfig/config.mak_no_simd ./config.mak
./getTASELibcSubset.sh
popd

#STRING (plus locale dependency) ---------
cp $MUSL_PATH/obj/src/string/*.o ./build/
cp $MUSL_PATH/obj/src/locale/__lctrans.o ./build/ #external dependency

#CTYPE------------------------------------
cp $MUSL_PATH/obj/src/ctype/*.o ./build/

#STDLIB-----------------------------------
#Grab all the STDLIB files except for strtod/l and wcstod/l.  We have traps for those for now in TASE,
# so all of stdlib should be supported.
STDLIBS="abs atof atoi atol atoll bsearch div ecvt fcvt gcvt imaxabs imaxdiv labs ldiv llabs lldiv qsort"
for STDLIB in $STDLIBS 
do
    cp $MUSL_PATH/obj/src/stdlib/$STDLIB.o ./build/
done
cp $MUSL_PATH/obj/src/string/*.o ./build/
cp $MUSL_PATH/obj/src/locale/__lctrans.o ./build/ #external dependency

#ERRNO------------------------------------
cp $MUSL_PATH/obj/src/errno/*.o ./build/

#NETWORK (subset)-------------------------
#These are all pure
NETLIBS=" htonl htons ntohl ntohs "
for NETLIB in $NETLIBS
do
    cp $MUSL_PATH/obj/src/network/$NETLIB.o ./build/
done

#MATH-------------------------------------
cp $MUSL_PATH/obj/src/math/*.o ./build/
cp $MUSL_PATH/obj/src/fenv/fenv.o ./build/  #external dependency
cp $MUSL_PATH/obj/src/fenv/fesetround.o ./build/ #external dependency

rm -f libtasec.a

ar -r libtasec.a ./build/*.o

