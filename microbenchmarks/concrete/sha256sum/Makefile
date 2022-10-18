ROOT?=/project
BIN?=main
CFLAGS?=-O0

all: build/main build/obj.dump

build/main: 
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'


test:
	cd build/ && rm -f Monitor* && ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - ../GutenburgDictionary.txt


smalltest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - ../harness.c

smallmixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - ../harness.c


mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -singleStepping -taseManager=false -dontFork -check-overshift=false - ../GutenburgDictionary.txt

gdbtest:
		cd build/ && rm -f Monitor* && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main -project=main -taseDebug -modelDebug -singleStepping -taseManager=false -dontFork -check-overshift=false - ../GutenburgDictionary.txt


build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*

mixedres:
	grep -A2 printf build/Monitor | tail -n1 > mixedres.txt

interpres:
	grep -A2 printf build/Monitor | tail -n1 > interpres.txt
