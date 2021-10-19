FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

COPY . /TASE_BUILD/

RUN apt-get update -y && apt-get install --no-install-recommends -y build-essential binutils bison flex make cmake git wget curl bash-completion software-properties-common linux-tools-generic linux-tools-common python3-dev python3-pip zip unzip emacs libboost-program-options-dev perl zlib1g-dev libcap-dev libncurses5 libncurses-dev && \
mkdir -p /TASE/llvm-3.4.2 && \
curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C /TASE/llvm-3.4.2 --strip 1 && \
mkdir -p /TASE/include/ /TASE/scripts/ && \
cp -r /TASE_BUILD/test/tase/include/tase/ /TASE/include/tase/ && \
cp -r /TASE_BUILD/test/other/ /TASE/include/traps/ && \
cp -r /TASE_BUILD/openssl/include/ /TASE/include/openssl/ && \
cp /TASE_BUILD/test/tase/tase_link.ld /TASE/ && \
cp -r /TASE_BUILD/test/scripts/ /TASE/scripts/ #&& \
cd /TASE_BUILD/install/ &&  make -j 12 setup && \
rm -rf /TASE_BUILD/ /var/lib/apt/lists/* && apt-get autoremove