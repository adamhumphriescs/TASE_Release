# TASE: Transactionally-Assisted Symbolic Execution

This branch contains an experimental build of TASE which removes its dependence on transactional hardware.

Instead of speculatively opening transactions and attempting to execute code natively, this TASE build 
eagerly checks the operands of each instruction during native execution before the instruction is executed.
If the operands contain symbolic data, control is transferred to the interpreter, which handles symbolic 
computations until all registers no longer contain symbolic data and native execution can be resumed.  Otherwise,
the structure of TASE is largely the same.  The eager checks are inserted by backend compiler passes implemented in 
the LLVM subrepo.

TASE requires several other code bases to build, including the LLVM toolchain, KLEE, musl's libc implementation, 
and others.  Because of this, we provide TASE with a dockerfile and recommend that it be used within a container.

# Requirements

TASE can also only run on Linux-based operating systems.  Specifically, it has only been tested on Ubuntu 20.04.2.

# Setup

TASE is currently configured to build in containers and drop an executable in the host OS.  Input the commands below to copy the source repo and
start the build.  The build usually takes at least 30 minutes.

```
$ git clone https://github.com/adamhumphriescs/TASE_Release.git
$ cd ./TASE_Release
$ git checkout noTSX
$ make 
```

You can then test the build and run some of the microbenchmarks (albeit without transactional hardware) in the TASE paper by typing the following.
```
$ cd microbenchmarks && make
```
