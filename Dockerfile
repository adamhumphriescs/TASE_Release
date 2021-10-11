FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

COPY . /TASE_BUILD/

RUN apt-get update -y && apt-get install --no-install-recommends -y make git software-properties-common binutils emacs bison flex libboost-program-options-dev perl zlib1g-dev libcap-dev libncurses-dev && \
cd /TASE_BUILD/test/ && NCPU=8 ./provision.sh && \
cd /TASE_BUILD/install/ &&  make setup && \
rm -rf /TASE_BUILD/ /var/lib/apt/lists/* && apt-get autoremove