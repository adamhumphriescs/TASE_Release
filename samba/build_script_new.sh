#!/bin/sh

#sed -i 's/o.reg_size(reg.reg)/reg.size/g' /TASE/parseltongue86/translator/instruction.py

mkdir /compilers
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

# sed -i '89a\
#     conf.env.CC = ["/TASE/bin/clang"]\
#     conf.env.LINK_CC = ["/usr/bin/c++"]\
#     conf.env.COMPILER_CC = ["/TASE/bin/clang"]\
#     conf.env.CC_NAME = ["clang"]\
#     conf.env.CXX = ["/TASE/bin/clang++"]\
#     conf.ADD_CFLAGS(["-mllvm", "-x86-tase-max-cartridge-size=100000", "-I/TASE/include/traps/", "-I/TASE/include/tase/", "-DTASE_TEST", "-mllvm", "-x86-tase-modeled-functions=/TASE/include/tase/core_modeled.h", "-mno-mmx", "-mno-sse", "-mno-sse2", "-mno-sse3", "-mno-sse4", "-mno-80387", "-mno-avx", "-O0"])\
#     conf.ADD_LDFLAGS(["-D_GLIBCXX_USE_CXX11_ABI=0", "-fno-pie", "-no-pie", "-I/TASE/include/openssl/", "-Wall", "-Wextra", "-Wno-unused-parameter", "-O0", "-Wl,--start-group", "/TASE/lib/libtase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libstp.a", "/TASE/lib/libminisat.a", "/TASE/lib/libkleaverExpr.a", "/TASE/lib/libkleeSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMInstrumentation.a", "/TASE/llvm-3.4.2/lib/libLLVMIRReader.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMOption.a", "/TASE/llvm-3.4.2/lib/libLLVMLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMLinker.a", "/TASE/llvm-3.4.2/lib/libLLVMipo.a", "/TASE/llvm-3.4.2/lib/libLLVMVectorize.a", "/TASE/llvm-3.4.2/lib/libLLVMTableGen.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Disassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMX86AsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86CodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMSelectionDAG.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCDisassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMMCParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Desc.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Info.a" ,"/TASE/llvm-3.4.2/lib/libLLVMX86AsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Utils.a", "/TASE/llvm-3.4.2/lib/libLLVMInterpreter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCJIT.a", "/TASE/llvm-3.4.2/lib/libLLVMRuntimeDyld.a", "/TASE/llvm-3.4.2/lib/libLLVMExecutionEngine.a", "/TASE/llvm-3.4.2/lib/libLLVMCodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMObjCARCOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMScalarOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMInstCombine.a", "/TASE/llvm-3.4.2/lib/libLLVMTransformUtils.a", "/TASE/llvm-3.4.2/lib/libLLVMAnalysis.a", "/TASE/llvm-3.4.2/lib/libLLVMTarget.a", "/TASE/llvm-3.4.2/lib/libLLVMMC.a", "/TASE/llvm-3.4.2/lib/libLLVMObject.a", "/TASE/llvm-3.4.2/lib/libLLVMBitWriter.a", "/TASE/llvm-3.4.2/lib/libLLVMBitReader.a", "/TASE/llvm-3.4.2/lib/libLLVMCore.a", "/TASE/llvm-3.4.2/lib/libLLVMSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMJIT.a", "/TASE/llvm-3.4.2/lib/libLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMipa.a", "-lz", "-lpthread", "-ltinfo", "-ldl", "-lm", "-lstdc++", "-Wl,--end-group"])' wscript


# don't execute built binaries
#find . -type f -not -path '*/\.*' -exec sed -i 's/execute=True/execute=False/g' {} +

# no main, add begin_target_inner?
sed -i 's/int main(/int target_main(/g' /samba/source3/client/client.c
#cp /samba/lib/talloc/talloc.c /talloc.c
#head -n 388 /samba/lib/talloc/talloc.c > /samba/lib/talloc/talloc_alt.c
#tail -n+438 /samba/lib/talloc/talloc.c >> /samba/lib/talloc/talloc_alt.c
#mv /samba/lib/talloc/talloc_alt.c /samba/lib/talloc/talloc.c

#head -n 141 /samba/nsswitch/wb_common.c > /samba/nsswitch/wb_common.c.tmp
#tail -n+147 /samba/nsswitch/wb_common.c >> /samba/nsswitch/wb_common.c.tmp
#mv /samba/nsswitch/wb_common.c.tmp /samba/nsswitch/wb_common.c

#awk '{if(NR==69){print "\t\tp(str(result))"}else{print $0}}' /samba/buildtools/wafsamba/samba_autoconf.py > tmp.py
#mv tmp.py /samba/buildtools/wafsamba/samba_autoconf.py

#awk '{if(NR==307 || NR==308 || NR==309){print "#"$0}else{print $0}}' /samba/third_party/waf/wafadmin/Tools/python.py > tmp.py
#mv tmp.py /samba/third_party/waf/wafadmin/Tools/python.py

./configure --without-ad-dc --without-gpgme --without-pam --without-relro --with-static-modules='!FORCED' --with-shared-modules='!FORCED' --with-shared-modules='!vfs_snapper' --without-libarchive --without-ldap --without-ads --without-pie --with-system-mitkrb5 --bundled-libraries='!heimdal,!popt,!zlib,!ldb,!pyldb,!talloc,!pytalloc,!tevent'
#--disable-python
#--without-json

echo '' > /compilers/compile_commands.txt

sed -i 's|CC = \[.*\]|CC = ["/compilers/clang"]|g' /samba/bin/c4che/default.cache.py

sed -i 's/CC_NAME = .*/CC_NAME = "clang"/g' /samba/bin/c4che/default.cache.py

sed -Ei 's|EXTRA_INCLUDES = \[(.*)\]|EXTRA_INCLUDES = [\1, "-mllvm", "-x86-tase-max-cartridge-size=100000", "-I/TASE/include/traps/", "-I/TASE/include/tase/", "-DTASE_TEST", "-mllvm", "-x86-tase-modeled-functions=/TASE/include/tase/core_modeled.h", "-mno-mmx", "-mno-sse", "-mno-sse2", "-mno-sse3", "-mno-sse4", "-mno-80387", "-mno-avx", "-O0"]|g' /samba/bin/c4che/default.cache.py

sed -Ei 's|EXTRA_LDFLAGS = \[(.*)\]|EXTRA_LDFLAGS = [\1, "-D_GLIBCXX_USE_CXX11_ABI=0", "-fno-pie", "-no-pie", "-I/TASE/include/openssl/", "-Wall", "-Wextra", "-Wno-unused-parameter", "-O0", "-Wl,--start-group", "/TASE/lib/libtase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeCore.a", "/TASE/lib/libkleeModule.a", "/TASE/lib/libkleeTase.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libkleeBasic.a", "/TASE/lib/libkleaverSolver.a", "/TASE/lib/libstp.a", "/TASE/lib/libminisat.a", "/TASE/lib/libkleaverExpr.a", "/TASE/lib/libkleeSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMInstrumentation.a", "/TASE/llvm-3.4.2/lib/libLLVMIRReader.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMOption.a", "/TASE/llvm-3.4.2/lib/libLLVMLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMLinker.a", "/TASE/llvm-3.4.2/lib/libLLVMipo.a", "/TASE/llvm-3.4.2/lib/libLLVMVectorize.a", "/TASE/llvm-3.4.2/lib/libLLVMTableGen.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Disassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMX86AsmParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86CodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMSelectionDAG.a", "/TASE/llvm-3.4.2/lib/libLLVMAsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCDisassembler.a", "/TASE/llvm-3.4.2/lib/libLLVMMCParser.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Desc.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Info.a" ,"/TASE/llvm-3.4.2/lib/libLLVMX86AsmPrinter.a", "/TASE/llvm-3.4.2/lib/libLLVMX86Utils.a", "/TASE/llvm-3.4.2/lib/libLLVMInterpreter.a", "/TASE/llvm-3.4.2/lib/libLLVMMCJIT.a", "/TASE/llvm-3.4.2/lib/libLLVMRuntimeDyld.a", "/TASE/llvm-3.4.2/lib/libLLVMExecutionEngine.a", "/TASE/llvm-3.4.2/lib/libLLVMCodeGen.a", "/TASE/llvm-3.4.2/lib/libLLVMObjCARCOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMScalarOpts.a", "/TASE/llvm-3.4.2/lib/libLLVMInstCombine.a", "/TASE/llvm-3.4.2/lib/libLLVMTransformUtils.a", "/TASE/llvm-3.4.2/lib/libLLVMAnalysis.a", "/TASE/llvm-3.4.2/lib/libLLVMTarget.a", "/TASE/llvm-3.4.2/lib/libLLVMMC.a", "/TASE/llvm-3.4.2/lib/libLLVMObject.a", "/TASE/llvm-3.4.2/lib/libLLVMBitWriter.a", "/TASE/llvm-3.4.2/lib/libLLVMBitReader.a", "/TASE/llvm-3.4.2/lib/libLLVMCore.a", "/TASE/llvm-3.4.2/lib/libLLVMSupport.a", "/TASE/llvm-3.4.2/lib/libLLVMJIT.a", "/TASE/llvm-3.4.2/lib/libLTO.a", "/TASE/llvm-3.4.2/lib/libLLVMipa.a", "-lz", "-lpthread", "-ltinfo", "-ldl", "-lm", "-lstdc++", "-Wl,--end-group"]|g' /samba/bin/c4che/default.cache.py

sed -i 's|LINK_CC = \[.*\]|LINK_CC = ["/compilers/gcc"]|g' /samba/bin/c4che/default.cache.py

rep=$'        kw["shell"] = True\n\tif not isinstance(s, str):\n\t\tfor idx, x, in enumerate(s):\n\t\t\tif " " in x:\n\t\t\t\ta = x.split("=")\n\t\t\t\tif len(a) > 1:\n\t\t\t\t\ts[idx] = "=".join([a[0], "\"" + a[1] + "\""])\n\t\twith open("/compile.log", "a") as fh:\n\t\t\tfh.write(str(s))\n\t\t\tfh.write("\\n\\n")\n\t\ts = " ".join(s)\n'  

head -n 198 /samba/third_party/waf/wafadmin/Utils.py > /cache.tmp
echo "$rep" >> /cache.tmp
tail -n+200 /samba/third_party/waf/wafadmin/Utils.py >> /cache.tmp
mv /cache.tmp /samba/third_party/waf/wafadmin/Utils.py
sed -i 's|^\$||g' /samba/third_party/waf/wafadmin/Utils.py  # ?? bash is being strange

#sed -i 's/LDFLAGS_\(\w*\) = \[.*\]/LDFLAGS_\1 = []/g' /samba/bin/c4che/default_cache.py
#sed -i 's/\(\w*\)_LDFLAGS = \[.*\]/\1_LDFLAGS = []/g' /samba/bin/c4che/default_cache.py

#sed -i 's/HAVE_UNSHARE_CLONE_FS = 1//g' /samba/bin/c4che/default_cache.py
#sed -i 's/#define HAVE_UNSHARE_CLONE_FS 1//g' /samba/bin/default/include/config.h

#sed -i '981i char tase_progname[10] = "smbclient";' /samba/lib/replace/replace.c
#sed -i 's/program_invocation_short_name/\&tase_progname[0]/g' /samba/lib/replace/replace.c


#sed -i '1370i printf("opt: %s\\n", optString);\n' /samba/third_party/popt/popt.c
#sed -i '1301i printf("entered poptGetNextOpt\\n");\n' /samba/third_party/popt/popt.c
#sed -i 's/stdout/1/g' /samba/third_party/popt/popthelp.c

#sed -i '650,658d' /samba/third_party/popt/popthelp.c
#sed -i '650i len += fprintf(fp, " %s", tase_progname);' /samba/third_party/popt/popthelp.c
#sed -i '637i extern char tase_progname[10];'  /samba/third_party/popt/popthelp.c

#sed -i 's/jumpq/jmpq/g' /TASE/parseltongue86/translator/elffile.py

#make -j 16 bin/smbclient || echo "should fail at linking step!"

#cd /samba/bin/default

#/recompile.sh
sed -i 's|--targets=client/smbclient|-vvv --targets=client/smbclient|g' /samba/Makefile
make bin/smbclient
