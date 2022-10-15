ROOT?=/project
BIN?=main
all: build/main build/obj.dump


build/main: 
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make -f build.Makefile'


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
	grep -A19 printf build/Monitor  | grep RDX | awk 'BEGIN{a=""}{split($$3,m,/x/); a=a""m[2]}END{print a}' > mixedres.txt

interpres:
	grep -A1 puts build/Monitor | tail -n1 > interpres.txt
