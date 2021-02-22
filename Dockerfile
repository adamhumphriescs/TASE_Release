FROM ubuntu:20.04

COPY . /TASE/

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y git sudo software-properties-common emacs

RUN cd /TASE/test && ./provision.sh