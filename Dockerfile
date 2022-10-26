# syntax=docker/dockerfile:1
FROM ubuntu:22.04 AS tase_llvm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install --no-install-recommends -y build-essential binutils bison flex make cmake git wget curl bash-completion software-properties-common linux-tools-generic linux-tools-common python2 python3-dev python3-pip zip unzip emacs libboost-program-options-dev perl zlib1g-dev libcap-dev libncurses5 libncurses-dev libgmp-dev texinfo less gdb libz3-4 libz3-dev && \
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
python2.7 get-pip.py && \
pip2.7 install -U pygments pyyaml && \
python3 -m pip install -U mypy


FROM tase_llvm AS tase
RUN cd /TASE_BUILD/ && git pull && git submodule set-branch -b docker klee && git submodule update --remote klee
RUN cd /TASE_BUILD/install/ && make -j 16 setup && cd / && mv /TASE_BUILD/install/ /TASE/ && \
rm -rf /TASE_BUILD/ /var/lib/apt/lists/* && apt-get autoremove
