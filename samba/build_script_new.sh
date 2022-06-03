#!/bin/sh

#sed -i 's/o.reg_size(reg.reg)/reg.size/g' /TASE/parseltongue86/translator/instruction.py

mkdir -p /compilers
cd compilers
STR="#!/bin/bash"
STR2='echo "$0 ${@}" >> /compilers/compile_commands.txt'
echo $STR > clang
echo $STR2 >> clang
echo '/TASE/bin/clang "${@}"' >> clang
chmod +x clang

# echo $STR > clang++
# echo $STR2 >> clang++
# echo '/TASE/bin/clang " ${@}"' >> clang++
# chmod +x clang++

# echo $STR > ld
# echo $STR2 >> ld
# echo '/usr/bin/ld "${@}"' >> ld
# chmod +x ld

echo $STR > gcc
#echo $STR2 > gcc
echo 'echo "$0 ${@}" >> /compilers/link_commands.txt' >> gcc
echo 'out=$(/compilers/get_out.py "${@}")' >> gcc
echo 'touch $out' >> gcc
#echo '/usr/bin/gcc "${@}"' >> gcc
chmod +x gcc

# echo $STR > c++
# echo $STR2 >> c++
# echo '/usr/bin/c++ "${@}"' >> c++
# chmod +x c++

#export PATH="/compilers/:$PATH"

cd /samba

# no main, add begin_target_inner?
sed -i 's/int main(/int target_main(/g' /samba/source3/client/client.c

./configure --without-ad-dc --without-gpgme --without-pam --without-relro --with-static-modules='!FORCED' --with-shared-modules='!FORCED' --with-shared-modules='!vfs_snapper' --without-libarchive --without-ldap --without-ads --without-pie --with-system-mitkrb5 --bundled-libraries='!heimdal,!popt,!zlib'
#--bundled-libraries='!heimdal,!popt,!zlib,!ldb,!pyldb,!talloc,!pytalloc,!tevent'
#--disable-python
#--without-json

echo '' > /compilers/compile_commands.txt

sed -i 's|CC = \[.*\]|CC = ["/compilers/clang"]|g' /samba/bin/c4che/default.cache.py

sed -i 's/CC_NAME = .*/CC_NAME = "clang"/g' /samba/bin/c4che/default.cache.py

sed -Ei 's|EXTRA_CFLAGS = \[(.*)\]|EXTRA_CFLAGS = [\1, "-mllvm", "-x86-tase-max-cartridge-size=100000", "-I/TASE/include/traps/", "-I/TASE/include/tase/", "-DTASE_TEST", "-mllvm -x86-tase-modeled-functions=/TASE/include/tase/core_modeled.h", "-mno-mmx", "-mno-sse", "-mno-sse2", "-mno-sse3", "-mno-sse4", "-mno-80387", "-mno-avx", "-O0", "-emit-llvm"]|g' /samba/bin/c4che/default.cache.py

sed -Ei 's|EXTRA_LDFLAGS = \[(.*)\]|EXTRA_LDFLAGS = [\1, "-D_GLIBCXX_USE_CXX11_ABI=0", "-fno-pie", "-no-pie", "-I/TASE/include/openssl/", "-Wall", "-Wextra", "-Wno-unused-parameter", "-O0", "-Wl,--start-group", "/TASE/lib/libtase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libstp.a", "/TASE/lib/libminisat.a", "/TASE/lib/libkleaverExpr.a", "/TASE/lib/libkleeSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMInstrumentation.a", "/TASE/llvm-3.4.2/lib/libLLVMIRReader.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMOption.a", "/TASE/llvm-3.4.2/lib/libLLVMLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMLinker.a", "/TASE/llvm-3.4.2/lib/libLLVMipo.a", "/TASE/llvm-3.4.2/lib/libLLVMVectorize.a", "/TASE/llvm-3.4.2/lib/libLLVMTableGen.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Disassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMX86AsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86CodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMSelectionDAG.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCDisassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMMCParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Desc.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Info.a" ,"/TASE/llvm-3.4.2/lib/libLLVMX86AsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Utils.a", "/TASE/llvm-3.4.2/lib/libLLVMInterpreter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCJIT.a", "/TASE/llvm-3.4.2/lib/libLLVMRuntimeDyld.a", "/TASE/llvm-3.4.2/lib/libLLVMExecutionEngine.a", "/TASE/llvm-3.4.2/lib/libLLVMCodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMObjCARCOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMScalarOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMInstCombine.a", "/TASE/llvm-3.4.2/lib/libLLVMTransformUtils.a", "/TASE/llvm-3.4.2/lib/libLLVMAnalysis.a", "/TASE/llvm-3.4.2/lib/libLLVMTarget.a", "/TASE/llvm-3.4.2/lib/libLLVMMC.a", "/TASE/llvm-3.4.2/lib/libLLVMObject.a", "/TASE/llvm-3.4.2/lib/libLLVMBitWriter.a", "/TASE/llvm-3.4.2/lib/libLLVMBitReader.a", "/TASE/llvm-3.4.2/lib/libLLVMCore.a", "/TASE/llvm-3.4.2/lib/libLLVMSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMJIT.a", "/TASE/llvm-3.4.2/lib/libLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMipa.a", "-lz", "-lpthread", "-ltinfo", "-ldl", "-lm", "-lstdc++", "-Wl,--end-group"]|g' /samba/bin/c4che/default.cache.py

sed -i 's|LINK_CC = \[.*\]|LINK_CC = ["/compilers/gcc"]|g' /samba/bin/c4che/default.cache.py

head -n 198 /samba/third_party/waf/wafadmin/Utils.py > /cache.tmp
echo $'        kw["shell"] = True\n\tif not isinstance(s, str):'  >> /cache.tmp
echo $'\t\tfor idx, x, in enumerate(s):'  >> /cache.tmp
echo $'\t\t\tif " " in x:'  >> /cache.tmp
echo $'\t\t\t\ta = x.split("=")'  >> /cache.tmp
echo $'\t\t\t\tif len(a) > 1:'  >> /cache.tmp
echo $'\t\t\t\t\ts[idx] = "=".join([a[0], "\"" + a[1] + "\""])'  >> /cache.tmp
echo $'\t\t\telif "\"" in x:'  >> /cache.tmp
echo $'\t\t\t\ta = x.split("=")'  >> /cache.tmp
echo $'\t\t\t\ts[idx] = "=".join([a[0], "'"'"'" + a[1] + "'"'"'"])'  >> /cache.tmp
echo $'\t\twith open("/compile.log", "a") as fh:'  >> /cache.tmp
echo $'\t\t\tfh.write(str(s))'  >> /cache.tmp
echo $'\t\t\tfh.write("\\n\\n")'  >> /cache.tmp
echo $'\t\ts = " ".join(s)\n'  >> /cache.tmp
tail -n+200 /samba/third_party/waf/wafadmin/Utils.py >> /cache.tmp
mv /cache.tmp /samba/third_party/waf/wafadmin/Utils.py
sed -i 's|^\$||g' /samba/third_party/waf/wafadmin/Utils.py  # ?? bash is being strange


#/recompile.sh
sed -i 's|--targets=client/smbclient|-vvv --targets=client/smbclient|g' /samba/Makefile
make bin/smbclient

mkdir -p /samba/bin/objs/

cd /samba/bin/
sed 's/-emit-llvm//g' /compilers/compile_commands.txt | sed 's/-fstack-protector//g' | awk '{if($0~/PROTO/){a=0;for(i=1;i<=NF;i++){if($i~/PROTO/){a=i}} if(a!=0){split($a, m, "="); out=$1; for(i=2;i<a;i++){out=out" "$i}out=out" "m[1]"=\""m[2]" "$(a+1)" "$(a+2)"\"";for(i=a+3;i<=NF;i++){out=out" "$i}print out}else{print $0}}else{print $0}}' | sed -E 's|(-D[A-Za-z_]+=)("[A-Za-z0-9_/.]+")|\1'"'"'\2'"'"'|g' >> finish.sh
parallel -j 20 :::: finish.sh

cd default
mkdir -p objs
find . -name '*.o' | xargs -I{} -n1 -P1 bash -c 'x="{}"; cp $x /samba/bin/default/objs/$(sed "s|/|_|g" <<<${x:2})'
cd objs

for x in $(find . -name '*.o')
do
    objcopy --localize-hidden $x
done


/TASE/bin/clang -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx -mllvm -x86-tase-modeled-functions=/TASE/include/tase/core_modeled.h -c /harness.c -o harness.o

rm /samba/bin/default/objs/lib_replace_replace_1.o # conflict with replace_2.o, but replace_1.o not actually used by vanilla samba linking...

ld -r $(find . -name '*.o') -o /samba/bin/default/source3/client/everything.o

cd /TASE/install
./localize.sh /samba/bin/default/source3/client/everything.o
objcopy --globalize-symbol=gensec_may_reset_crypto /samba/bin/default/source3/client/everything.o
objcopy --globalize-symbol=ldb_register_extended_match_rules /samba/bin/default/source3/client/everything.o

cd /samba/bin/default/source3/client/
/usr/bin/c++ -T/TASE/tase_link.ld -fno-pie -no-pie -D_GLIBCXX_USE_CXX11_ABI=0 -I/TASE/include/openssl/ -Wall -Wextra -Wno-unused-parameter -O0 -o/samba/bin/default/source3/client/smbclient -rdynamic /TASE/lib/main.cpp.o everything.o -L/usr/lib/x86_64-linux-gnu/mit-krb5 -Wl,--start-group /TASE/lib/libtase.a /TASE/lib/libkleeCore.a /TASE/lib/libkleeModule.a /TASE/lib/libkleeTase.a /TASE/lib/libkleeCore.a /TASE/lib/libkleeModule.a /TASE/lib/libkleeTase.a /TASE/lib/libkleeBasic.a /TASE/lib/libkleaverSolver.a /TASE/lib/libkleeBasic.a /TASE/lib/libkleaverSolver.a /TASE/lib/libstp.a /TASE/lib/libminisat.a /TASE/lib/libkleaverExpr.a /TASE/lib/libkleeSupport.a /TASE/llvm-3.4.2/lib/libLLVMInstrumentation.a /TASE/llvm-3.4.2/lib/libLLVMIRReader.a /TASE/llvm-3.4.2/lib/libLLVMAsmParser.a /TASE/llvm-3.4.2/lib/libLLVMOption.a /TASE/llvm-3.4.2/lib/libLLVMLTO.a /TASE/llvm-3.4.2/lib/libLLVMLinker.a /TASE/llvm-3.4.2/lib/libLLVMipo.a /TASE/llvm-3.4.2/lib/libLLVMVectorize.a /TASE/llvm-3.4.2/lib/libLLVMTableGen.a /TASE/llvm-3.4.2/lib/libLLVMX86Disassembler.a /TASE/llvm-3.4.2/lib/libLLVMX86AsmParser.a /TASE/llvm-3.4.2/lib/libLLVMX86CodeGen.a /TASE/llvm-3.4.2/lib/libLLVMSelectionDAG.a /TASE/llvm-3.4.2/lib/libLLVMAsmPrinter.a /TASE/llvm-3.4.2/lib/libLLVMMCDisassembler.a /TASE/llvm-3.4.2/lib/libLLVMMCParser.a /TASE/llvm-3.4.2/lib/libLLVMX86Desc.a /TASE/llvm-3.4.2/lib/libLLVMX86Info.a /TASE/llvm-3.4.2/lib/libLLVMX86AsmPrinter.a /TASE/llvm-3.4.2/lib/libLLVMX86Utils.a /TASE/llvm-3.4.2/lib/libLLVMInterpreter.a /TASE/llvm-3.4.2/lib/libLLVMMCJIT.a /TASE/llvm-3.4.2/lib/libLLVMRuntimeDyld.a /TASE/llvm-3.4.2/lib/libLLVMExecutionEngine.a /TASE/llvm-3.4.2/lib/libLLVMCodeGen.a /TASE/llvm-3.4.2/lib/libLLVMObjCARCOpts.a /TASE/llvm-3.4.2/lib/libLLVMScalarOpts.a /TASE/llvm-3.4.2/lib/libLLVMInstCombine.a /TASE/llvm-3.4.2/lib/libLLVMTransformUtils.a /TASE/llvm-3.4.2/lib/libLLVMAnalysis.a /TASE/llvm-3.4.2/lib/libLLVMTarget.a /TASE/llvm-3.4.2/lib/libLLVMMC.a /TASE/llvm-3.4.2/lib/libLLVMObject.a /TASE/llvm-3.4.2/lib/libLLVMBitWriter.a /TASE/llvm-3.4.2/lib/libLLVMBitReader.a /TASE/llvm-3.4.2/lib/libLLVMCore.a /TASE/llvm-3.4.2/lib/libLLVMSupport.a /TASE/llvm-3.4.2/lib/libLLVMJIT.a /TASE/llvm-3.4.2/lib/libLTO.a /TASE/llvm-3.4.2/lib/libLLVMipa.a -lz -lpthread -ltinfo -ldl -lm -lgnutls -lkrb5 -lk5crypto -lcom_err -lgssapi_krb5 -lcap -ltalloc -ltdb -lpopt -ltevent -lnsl -lrt -lresolv -lstdc++ -Wl,--end-group

echo "#!/bin/bash" > run_smbclient.sh
echo 'KLEE_RUNTIME_LIBRARY_PATH=/samba/bin/default/source3/client/build/bitcode/ ./smbclient "${@}"' >> run_smbclient.sh
chmod +x run_smbclient.sh

mkdir -p build/bitcode
cp /TASE/install/libtasec.syms client.tase.tmp
for x in $(ls /samba/bin/default/objs/); do  python3 /TASE/parseltongue86/rosettastone.py smbclient -f /samba/bin/default/objs/$x >> client.vars.tmp; nm --defined-only /samba/bin/default/objs/$x | grep -i " t " | cut -d' ' -f 3 >> client.tase.tmp; done
readelf --relocs smbclient | grep std | grep GLIBC | grep GLOB_DAT | awk '{print $1, "0x8"; print $4, "0x10"}' >> client.vars.tmp

sort client.tase.tmp | uniq > client.tase && rm client.tase.tmp
sort client.vars.tmp | uniq > client.vars && rm client.vars.tmp
cp /TASE/install/klee_bitcode/* build/bitcode
./run_smbclient.sh -tasePreProcess=TRUE

python3 /TASE/parseltongue86/parseltongue86.py -n -f client.tase smbclient /TASE/include/tase/ client -t 40

echo '#!/bin/bash' > compile.sh
echo '/TASE/llvm-3.4.2/bin/clang -fno-slp-vectorize -Wall -Wextra -emit-llvm -Wno-unused -O3 -std=c++11 -c $1 -o build/bitcode/$(basename -s .cpp $1).bc' >> compile.sh
chmod +x compile.sh

find build/bitcode -name '*.cpp' | xargs -n1 -P20 -I{} ./compile.sh {}

if [[ $(ls build/bitcode | grep -E -c 'client.interp.[0-9]+.bc$') -gt 1 ]]
then
    /TASE/llvm-3.4.2/bin/llvm-link build/bitcode/client.interp.*.bc -o build/bitcode/client.interp.bc
else
    mv build/bitcode/client.interp.0.bc build/bitcode/client.interp.bc
fi

objdump -D -C -w -M suffix -j .text smbclient > obj.dump

./run_smbclient.sh -taseManager=false -dontFork -execMode=INTERP_ONLY -taseDebug -modelDebug - --help
