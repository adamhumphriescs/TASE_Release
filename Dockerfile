# syntax=docker/dockerfile:1
FROM ubuntu:20.04 AS tase_llvm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install --no-install-recommends -y build-essential binutils bison flex make cmake git wget curl bash-completion software-properties-common linux-tools-generic linux-tools-common python3-dev python3-pip zip unzip emacs libboost-program-options-dev perl zlib1g-dev libcap-dev libncurses5 libncurses-dev libgmp-dev texinfo less && \
git clone --remote-submodules -b docker https://github.com/adamhumphriescs/TASE_Release.git /TASE_BUILD && \
git clone git://sourceware.org/git/binutils-gdb.git && \
cd binutils-gdb/ && git checkout 20756b0fbe065a84710aa38f2457563b57546440 && \
cp /TASE_BUILD/objdump.c binutils/ && \
cp /TASE_BUILD/section.c bfd.h bfd/ && \
./configure && make && \
mv binutils/objdump / && cd / && rm -f binUtils-gdb && \
cd /TASE_BUILD/ && git submodule update --init && git checkout docker && cd / && \
mkdir -p /TASE/llvm-3.4.2 && \
curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C /TASE/llvm-3.4.2 --strip 1 && \
mkdir -p /TASE/include/ /TASE/scripts/ && \
cp -r /TASE_BUILD/test/tase/include/tase/ /TASE/include/tase/ && \
cp -r /TASE_BUILD/test/other/ /TASE/include/traps/ && \
cp -r /TASE_BUILD/openssl/include/ /TASE/include/openssl/ && \
cp /TASE_BUILD/test/tase/tase_link.ld /TASE/ && \
cp -r /TASE_BUILD/test/scripts/ /TASE/scripts/ && \
cd /TASE_BUILD/install/ &&  make -j 16 tase_clang


FROM tase_llvm AS tase
RUN cd /TASE_BUILD/ && git pull && git submodule set-branch -b docker klee && git submodule update --remote klee
RUN apt-get install -y gdb
RUN cd /TASE_BUILD/install/ && make -j 16 setup && cd / && mv /TASE_BUILD/install/ /TASE/ && \
rm -rf /TASE_BUILD/ /var/lib/apt/lists/* && apt-get autoremove
