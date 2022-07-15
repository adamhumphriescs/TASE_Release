# syntax=docker/dockerfile:1
FROM ubuntu:20.04 AS tase_llvm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install --no-install-recommends -y build-essential binutils bison flex make cmake git wget curl bash-completion software-properties-common linux-tools-generic linux-tools-common python3-dev python3-pip zip unzip emacs libboost-program-options-dev perl zlib1g-dev libcap-dev libncurses5 libncurses-dev libgmp-dev texinfo less gdb && \
python3 -m pip install -U mypy && \
mkdir -p /TASE/llvm-3.4.2 /TASE/include/tase /TASE/include/traps /TASE/openssl/include /TASE/scripts && \
curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C /TASE/llvm-3.4.2 --strip 1 &&\
chmod -R a+rw /TASE/


FROM tase_llvm AS tase
RUN cd /TASE_BUILD/ && git pull && git submodule set-branch -b docker klee && git submodule update --remote klee
RUN cd /TASE_BUILD/install/ && make -j 16 setup && cd / && mv /TASE_BUILD/install/ /TASE/ && \
rm -rf /TASE_BUILD/ /var/lib/apt/lists/* && apt-get autoremove
