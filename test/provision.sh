#!/bin/bash

# Use this to provision the Vagrant test VM you instantiate or run this script as a super
# user manually on your machine in order to prepare it for development locally.
# VAGRANT=1 for vagrant vbox, NCPU=X for X CPUs


set -e
umask 022
#source ~/.bashrc


#ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ROOTDIR=/TASE
BUILD_DIR=/TASE_BUILD/

NCPU="${NCPU:-7}"
KLEE_LLVM_DIR="$ROOTDIR/llvm-3.4.2"

mkdir -p "${ROOTDIR}/include/"
mkdir -p "${ROOTDIR}/scripts/"
cp -r "${BUILD_DIR}/test/tase/include/tase/" "${ROOTDIR}/include/tase/"
cp -r "${BUILD_DIR}/test/other/" "${ROOTDIR}/include/traps/"
cp -r "${BUILD_DIR}/openssl/include/" "${ROOTDIR}/include/openssl/"
cp "${BUILD_DIR}/test/tase/tase_link.ld" "${ROOTDIR}/"
cp -r "${BUILD_DIR}/test/scripts/" "${ROOTDIR}/scripts/"

aptcmd="apt-get --yes"
if [[ $${VAGRANT:-0} == 1 ]]; then
  usermod -a -G vboxsf vagrant
  aptcmd="apt-get --yes"
  ROOTDIR="/TASE"
fi

INSTALLDIR="${ROOTDIR}/"
INC_DIR="${ROOTDIR}/include"

# Now expecting tase_link.ld in ROOTDIR

TASE_CFLAGS="-mllvm -x86-tase-modeled-functions=${INC_DIR}/tase/core_modeled.h -I${INC_DIR}/tase -T${ROOTDIR}/tase_link.ld -msse -msse2 -msse3 -msse4.2 -mno-80387 -mllvm -verify-regalloc -mllvm -verify-machineinstrs"

TASE_CFLAGS_NO_SSE="-mllvm -x86-tase-modeled-functions=${INC_DIR}/tase/core_modeled.h -I${INC_DIR}/tase -T${ROOTDIR}/tase_link.ld -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx -mllvm -verify-regalloc -mllvm -verify-machineinstrs -mllvm -x86-tase-paranoid-control-flow=true"


#-mllvm -print-before=x86-tase-capture-taint

# Tase only flags:
#-DTASE_INSTRUMENTATION_SIMD \
#-DTASE_ENABLE=1 \
#-DTASE_TSX \

setup_basic_tools () {
  echo "Installing basic tools"
  ${aptcmd} update

  # Basic development environment. Add editors, debuggers and other useful tools here.
  ${aptcmd} install \
    bash-completion \
    curl \
    wget \
    unzip \
    zip \
    build-essential \
    git \
    cmake \
    python3-dev \
    python3-pip \
    linux-tools-common \
    linux-tools-generic \
    libncurses5
#    diffutils \
#    dos2unix \
#    emacs \
#    vim \
#    subversion \
      
  echo "Adding LLVM apt sources/PPAs"
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
  apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main"
  apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-5.0 main"
  apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main"
  apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-8 main"
  ${aptcmd} update

  echo "Dropping LLVM 3.4 in " $KLEE_LLVM_DIR
  mkdir -p ${KLEE_LLVM_DIR}
  #Also appears to have dependency on libncurses5
  #Ran "sudo apt install libncurses5" to remove error when attempting to link in libtinfo
  #Maybe we should ideally pull in the source and build from scratch because of the old ubuntu 14 version?
  curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C ${KLEE_LLVM_DIR} --strip 1
}

gcc_alternatives () {
  version="$1"
  priority="${2:-40}"
  prefix="${3:-/usr/bin}"
  if [[ -f "${prefix}/gcc${version}" ]]; then
    update-alternatives --install /usr/bin/gcc gcc ${prefix}/gcc${version} ${priority} \
      --slave /usr/bin/cpp gcc-cpp ${prefix}/cpp${version} \
      --slave /usr/bin/g++ g++ ${prefix}/g++${version} \
      --slave /usr/bin/gcc-ar gcc-ar ${prefix}/gcc-ar${version} \
      --slave /usr/bin/gcc-nm gcc-nm ${prefix}/gcc-nm${version} \
      --slave /usr/bin/gcc-ranlib gcc-ranlib ${prefix}/gcc-ranlib${version} \
      --slave /usr/bin/gcov gcov ${prefix}/gcov${version} \
      --slave /usr/bin/gcov-tool gcov-tool ${prefix}/gcov-tool${version}
  fi
}

clang_alternatives () {
  version="$1"
  priority="${2:-40}"
  prefix="${3:-/usr/bin}"
  if [[ -f "${prefix}/clang${version}" ]]; then
    update-alternatives --install /usr/bin/clang clang ${prefix}/clang${version} ${priority} \
      --slave /usr/bin/bugpoint bugpoint ${prefix}/bugpoint${version} \
      --slave /usr/bin/c-index-test c-index-test ${prefix}/c-index-test${version} \
      --slave /usr/bin/clang++ clang++ ${prefix}/clang++${version} \
      --slave /usr/bin/clang-check clang-check ${prefix}/clang-check${version} \
      --slave /usr/bin/clang-format clang-format ${prefix}/clang-format${version} \
      --slave /usr/bin/clang-tblgen clang-tblgen ${prefix}/clang-tblgen${version} \
      --slave /usr/bin/llc llc ${prefix}/llc${version} \
      --slave /usr/bin/lld lld ${prefix}/lld${version} \
      --slave /usr/bin/lldb lldb ${prefix}/lldb${version} \
      --slave /usr/bin/lli lli ${prefix}/lli${version} \
      --slave /usr/bin/lli-child-target lli-child-target ${prefix}/lli-child-target${version} \
      --slave /usr/bin/llvm-ar llvm-ar ${prefix}/llvm-ar${version} \
      --slave /usr/bin/llvm-as llvm-as ${prefix}/llvm-as${version} \
      --slave /usr/bin/llvm-bcanalyzer llvm-bcanalyzer ${prefix}/llvm-bcanalyzer${version} \
      --slave /usr/bin/llvm-config llvm-config ${prefix}/llvm-config${version} \
      --slave /usr/bin/llvm-cov llvm-cov ${prefix}/llvm-cov${version} \
      --slave /usr/bin/llvm-diff llvm-diff ${prefix}/llvm-diff${version} \
      --slave /usr/bin/llvm-dis llvm-dis ${prefix}/llvm-dis${version} \
      --slave /usr/bin/llvm-dwarfdump llvm-dwarfdump ${prefix}/llvm-dwarfdump${version} \
      --slave /usr/bin/llvm-extract llvm-extract ${prefix}/llvm-extract${version} \
      --slave /usr/bin/llvm-link llvm-link ${prefix}/llvm-link${version} \
      --slave /usr/bin/llvm-mc llvm-mc ${prefix}/llvm-mc${version} \
      --slave /usr/bin/llvm-mcmarkup llvm-mcmarkup ${prefix}/llvm-mcmarkup${version} \
      --slave /usr/bin/llvm-nm llvm-nm ${prefix}/llvm-nm${version} \
      --slave /usr/bin/llvm-objdump llvm-objdump ${prefix}/llvm-objdump${version} \
      --slave /usr/bin/llvm-ranlib llvm-ranlib ${prefix}/llvm-ranlib${version} \
      --slave /usr/bin/llvm-readobj llvm-readobj ${prefix}/llvm-readobj${version} \
      --slave /usr/bin/llvm-rtdyld llvm-rtdyld ${prefix}/llvm-rtdyld${version} \
      --slave /usr/bin/llvm-size llvm-size ${prefix}/llvm-size${version} \
      --slave /usr/bin/llvm-stress llvm-stress ${prefix}/llvm-stress${version} \
      --slave /usr/bin/llvm-symbolizer llvm-symbolizer ${prefix}/llvm-symbolizer${version} \
      --slave /usr/bin/llvm-tblgen llvm-tblgen ${prefix}/llvm-tblgen${version} \
      --slave /usr/bin/macho-dump macho-dump ${prefix}/macho-dump${version} \
      --slave /usr/bin/opt opt ${prefix}/opt${version}
  fi
}

setup_alternatives () {
  echo "Setup alternatives for easy switching"

  # Not all the clangs have all the binaries listed above
  set +e

  gcc_alternatives "-5" 60
  gcc_alternatives "-6"
  gcc_alternatives "-7"

  clang_alternatives "-8" 60
  clang_alternatives "-7"
  clang_alternatives "-5.0"
  clang_alternatives "-4.0"
  clang_alternatives "" 30 "${KLEE_LLVM_DIR}/bin"
  
  set -e
}

#Possible to use cryptominisat IF it's installed
# and option is toggled on below.
setup_klee_solver () {
  echo "CC is $CC"
  echo "Building Minisat"
  cd ${BUILD_DIR}/build_minisat
  cmake \
    -DSTATIC_BINARIES=ON \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} \
    ../minisat
  make -j ${NCPU}
  make install

  
  echo "Building STP"
  cd "${BUILD_DIR}/build_stp"
  cmake \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DENABLE_PYTHON_INTERFACE:BOOL=OFF \
    -DCMAKE_INSTALL_PREFIX="${INSTALLDIR}" \
    -DUSE_CRYPTOMINISAT4:BOOL=OFF  \
    -DNO_BOOST:BOOL=ON \
    ../stp
  make -j "${NCPU}"
  make install
}

setup_openssl () {
  echo "Building openssl"
  cd "${BUILD_DIR}/openssl"

  (
    export CC="${INSTALLDIR}/bin/clang"
    export PATH="${INSTALLDIR}/bin:${PATH}"

    # Info from Marie:
    # We definitely need ssl3 srp idea camellia ocsp and rc4
    # to match the traffic we have already captured for sclient.
    #make dclean

    ./config \
      --prefix=${INSTALLDIR} \
      --openssldir=${INSTALLDIR} \
      -DPURIFY \
      -DCLIVER \
      -DTASE_TSX \
      ${TASE_CFLAGS_NO_SSE} -O1 \
      -Qunused-arguments \
      no-asm \
      no-engine \
      no-err \
      no-gmp \
      no-hw \
      no-hardware \
      no-locking \
      no-shared \
      no-threads \
      no-zlib \
      no-cast \
      no-comp \
      no-dso \
      no-dtls \
      no-dtls1 \
      no-md4 \
      no-mdc2 \
      no-nextprotoneg \
      no-npn \
      no-psk \
      no-ripemd \
      no-srtp \
      no-ssl2 \
      no-weak-ssl-ciphers

    make build_taseall
  )
}

setup_klee () {
  echo "Building klee"
  #Make a dummy "project" file so that klee will build the first time
  cd ${BUILD_DIR}/test
  ./buildDummyProject.sh
  
  cd ${BUILD_DIR}/build_klee
  CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 -fno-pie -no-pie -T${ROOTDIR}/tase_link.ld -I${INC_DIR}/openssl/" cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALLDIR}" \
    -DLLVM_CONFIG_BINARY="${KLEE_LLVM_DIR}/bin/llvm-config" \
    -DLLVMCC="${KLEE_LLVM_DIR}/bin/clang" \
    -DLLVMCXX="${KLEE_LLVM_DIR}/bin/clang++" \
    -DENABLE_KLEE_UCLIBC=FALSE \
    -DENABLE_POSIX_RUNTIME=FALSE \
    -DENABLE_SOLVER_STP=TRUE \
    -DSTP_DIR="${BUILD_DIR}/build_stp" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_KLEE_ASSERTS=FALSE \
    -DENABLE_UNIT_TESTS=FALSE \
    -DENABLE_SYSTEM_TESTS=FALSE \
    -DENABLE_DOCS=FALSE \
    -DPOSITION_INDEPENDENT_CODE=FALSE \
    -DINCLUDE_DIRECTORIES="${INC_DIR}/openssl/" \
    ../klee
  make -j ${NCPU}
}

setup_tsx_llvm () {
  echo "Building TSX inserting LLVM"
  cd "${BUILD_DIR}/build_llvm"
  cmake \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} \
    -DCMAKE_BUILD_TYPE="Debug" \
    -DCMAKE_C_FLAGS="-fdiagnostics-color=always -fmax-errors=3" \
    -DCMAKE_CXX_FLAGS="-fdiagnostics-color=always -fmax-errors=3" \
    -DLLVM_USE_LINKER="gold" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DBUILD_SHARED_LIBS=TRUE \
    -DLLVM_OPTIMIZED_TABLEGEN=TRUE \
    ../llvm
  make -j "${NCPU}"
  make install
}

setup_musl () {
  echo "Building musl for target"
  cd "${BUILD_DIR}/musl"

  (
    export CC="${INSTALLDIR}/bin/clang"
    export PATH="${INSTALLDIR}/bin:${PATH}"
    export CFLAGS="${TASE_CFLAGS} -O1"
    #-mllvm -debug -mllvm -view-sched-dags -mllvm -filter-view-dags=sw.bb2"

    cd TASEConfig
    ./addMuslFilePath.sh
    cp config.mak_simd ../config.mak
    cd ../
    #./configure \
    #  --prefix=${INSTALLDIR} \
    #  --disable-shared
    make -j "${NCPU}"
    make install
  )
}

setup_basic_tools
setup_klee_solver
setup_tsx_llvm
setup_musl
setup_openssl
