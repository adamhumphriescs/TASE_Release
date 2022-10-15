ROOT?=/project
BIN?=main
all: build/main build/obj.dump


build/main: 
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make -f build.Makefile'


test:
	cd build/ && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - ../tsortFile


gdbtest: tsortShort
	cd build/ && head -n 1000 ../tsortFile > tsortShort && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main -project=main -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - tsortShort

smalltest: tsortShort
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - ../tsortShort

smallmixedtest: tsortShort
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false  -singleStepping -check-overshift=false - ../tsortShort

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -check-overshift=false -singleStepping -check-overshift=false - ../tsortFile

build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*

interpres:
	grep ^OUT build/Monitor | awk '{print $$2}' > interpres.txt

mixedres:
	grep ^OUT build/Monitor | awk '{print $$2}' > mixedres.txt


tsortShort:
	head -n 10000 tsortFile > tsortShort
