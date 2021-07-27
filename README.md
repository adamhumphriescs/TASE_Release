# TASE: Transactionally-Assisted Symbolic Execution

TASE is a symbolic execution tool.  TASE, short for "Transactionally-Assisted Symbolic Execution", uses 
specialized hardware (Intel's TSX instructions) to speculatively execute code natively and concretely within a
transaction during symbolic execution.  If symbolic data is encountered during the speculative concrete 
execution, the transaction rolls back and control is given to a KLEE-based interpreter which handles operations
on symbolic data.  See "Requirments" below for details on the necessary hardware and operating system needed to test TASE.
The NDSS paper also has more specifics.

TASE was originally created for expediting the speed of a special use case of symbolic execution called behavioral 
verification.  Briefly, behavioral verification is a technique for inspecting network traffic and determining 
if it could have been produced by a known client implementation by symbolically executing the client and marking its
uknown client-side inputs as symbolic; see X Y Z for more details.  TASE is not specifically tooled for bugfinding,
but its core symbolic execution engine should be capable of the task.

TASE requires several other code bases to build, including the llvm toolchain, klee, musl's libc implementation, 
and others.  Because of this, we provide TASE with and dockerfile and recommend that it be used within a container.

# Requirements
TASE can only run on a machine with support for Intel's Restricted Transactional Memory (RTM) instructions (i.e., XBEGIN, XEND, XABORT).  
You can determine if your processor supports the XBEGIN/XEND/XABORT instructions by consulting the Intel processor 
documentation at https://ark.intel.com/content/www/us/en/ark.html or looking for the 'rtm' flag in /proc/cpuinfo.  
TASE will not run on a machine with a non-Intel (e.g., AMD) processor. 

TASE can also only run on Linux-based operating systems.  Specifically, it has only been tested on Ubuntu 20.04.2.

# Setup

TASE is currently configured to run in a container due to hardcoded file paths.  Input the commands below to copy the source repo and
build the docker container.

```
$ git clone https://github.com/adamhumphriescs/TASE_Release.git
$ cd ./TASE_Release
$ git submodule update --init
$ docker build -t tase .
```
After the build completes, you can run tase in a container with the following commmand.  
(Note that the args in this docker command will delete the container after you exit from it.)

```
$ docker run --rm -it tase
```

From within the container, you can test the build and run some of the microbenchmarks in the TASE paper by typing the following.
```
$ cd /TASE/test
$ ./doMicrobenchmarks.sh
```

# Using TASE

More to come here later this week.
