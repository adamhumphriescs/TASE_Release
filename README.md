# TASE: Transactionally-Assisted Symbolic Execution

TASE is a symbolic execution tool.  TASE, short for "Transactionally-Assisted Symbolic Execution", uses 
specialized hardware (Intel's TSX instructions) to speculatively execute code natively and concretely within a
transaction during symbolic execution.  If symbolic data is encountered during the speculative concrete 
execution, the transaction rolls back and control is given to a KLEE-based interpreter which handles operations
on symbolic data.  See "Requirements" below for details on the necessary hardware and operating system needed to test TASE.
The NDSS paper also has more specifics.

TASE was originally created for expediting the speed of a special use case of symbolic execution called behavioral 
verification.  Briefly, behavioral verification is a technique for inspecting network traffic and determining 
if it could have been produced by a known client implementation by symbolically executing the client and marking its
unknown client-side inputs as symbolic; see the TASE paper for more details.  TASE is not specifically tooled for bugfinding,
but its core symbolic execution engine should be capable of the task.

TASE requires several other code bases to build, including the LLVM toolchain, KLEE, musl's libc implementation, 
and others.  Because of this, we provide TASE with a dockerfile and recommend that it be used within a container.

The TASE repo now contains a branch with experimental support for machines without transactional hardware.  Change to the 
noTSX branch for more details.

# Requirements
TASE can only run on a machine with support for Intel's Restricted Transactional Memory (RTM) instructions (i.e., XBEGIN, XEND, XABORT).  
You can determine if your processor supports the XBEGIN/XEND/XABORT instructions by consulting the Intel processor 
documentation at https://ark.intel.com/content/www/us/en/ark.html or looking for the 'rtm' flag in /proc/cpuinfo.  
TASE will not run on a machine with a non-Intel (e.g., AMD) processor. 

TASE can also only run on Linux-based operating systems.  Specifically, it has only been tested on Ubuntu 20.04.2.

# Setup

TASE is currently configured to run in a container due to hardcoded file paths.  Input the commands below to copy the source repo and
build the docker container.  The build usually takes at least 30 minutes.

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
You can also test the build by running a simplified behavioral verification test with TASE.  In this test a trace of messages, one of 
which contains the heartbleed exploit, is determined with symbolic execution to be consistent or inconsistent with a build of OpenSSL.  (The OpenSSL build is slightly
modified for simplicity to send a single heartbeat message after the handshake and then exit.)

If the build completed correctly, you should see that two "rounds" (i.e., client-to-server messages) of verification were completed before the
entire verification as a whole failed on the third client-to-server message with the heartbeat exploit.  Specifically,  in the test the verifier 
should print that a contradiction was found among the constraints accumulated during verification based on the contents of the 15th byte in the 
message, which, given our choice of cipher suite, is one of the bytes that represents the claimed length of the message to be replied back.

The behavioral verification test can be run in the container with the following commands.
```
$ cd /TASE/projects/SSLCliver
$ ./heartbleedEval.sh
```

As an alternative to Docker, if you'd like to try and build TASE outside a container, you can do so by cloning the repo and initializing the submodules as
noted above.  However, you'll need to set the environment variable TASE_ROOT_DIR to the base directory of TASE_Release 
(e.g., /Sample/Path/TASE_Release) , and then run the following commands.  Note that this build option has only recently been added, so use with caution.
```
$ cd /Sample/Path/TASE_Release/test
$ ./provision.sh
```

# Performing Symbolic Execution in TASE
Instructions are provided below for perfoming symbolic execution in TASE.  
The code paths in the commands below assume TASE is running in a container built with our dockerfile.

### Step 1: Setup the project directory and build files

After TASE has been built, switch to the "projects" directory and run the setupProj.sh script.  You'll need to pick a name 
for the project (e.g., "PROJ_NAME" as below).

```$ cd /TASE/projects ```

```$ ./setupProj.sh PROJ_NAME       ```

```$ cd ./PROJ_NAME ```

### Step 2.  Drop in source and configure the harness

Next, you'll want to grab the source code you'd like to run in TASE, and drop it in the "src" directory in your project directory.

```$ cp /MY/SOURCE/DIR/* ./src/ ``` 

The setupProj.sh script from step 1 should also have dropped a file called "harness.c" into the "src" directory.  "harness.c" controls how the program
in ./src/ initially launches.  You will need to edit "harness.c" to provide the signature of your desired entry function, and setup the initial call it it 
makes in a wrapper function called "begin_target_inner" that we use to launch symbolic execution.  The function you replace is initially stubbed 
out as "your_entry_fn."  (If your entry function is "main", you can refer to it as such; we automatically rename any function in ./src/ called "main"
to "target_main.")

Here's an example of what harness.c would look like if your entry function had signature "void func1 (int x, int y);" :

```
#include "tase_make_symbolic.h"

//This file is a testing harness used for TASE.  

//This harness should be updated to make the signature for "your_entry_fn" and input
//args match the entry function you chose.

void func1 (int x, int y);

void begin_target_inner () {

  func1(123,456);

}
```
Note that you can use a helper function "tase_make_symbolic" to make data symbolic from within the harness or elsewhere within your code.
For example:

```
int x;
tase_make_symbolic(&x, 4, "Making X Symbolic"); 
```

### Step 3.  Build the project for TASE
Run the build script.  If an external function from libc or elsewhere is needed but we can't find a definition for it, the build script will print an error.

Definitions for libc functions from stdlib.h, ctype.h, and string.h as well as functions from libm (e.g., sin/cos/etc) should be automatically by TASE's limited musl-based libc implementation.  You do not need to provide definitions for them in ./src/ .

```$ ./build.sh```

### Step 4.  Run the project in TASE
Launch TASE.
  
```$ ./TASE ```

Basic output information will be in the file named "Monitor", including the number of paths traversed.

