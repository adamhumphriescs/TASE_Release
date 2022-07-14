#!/bin/bash
/TASE/llvm-3.4.2/bin/clang -fno-slp-vectorize -Wall -Wextra -emit-llvm -Wno-unused -O3 -std=c++11 -c $1 -o $(dirname $1)/$(basename -s .cpp $1).bc
