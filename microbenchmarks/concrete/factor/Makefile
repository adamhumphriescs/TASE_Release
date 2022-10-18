ROOT?=/project
BIN?=main
SMALL=5413218152718641574491217
LARGE=16895424309675413218152718641574491217
CFLAGS?=-O0

all: build/main build/obj.dump


build/main: 
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'

.PHONY: test gdbtest smalltest mixedtest objdump clean
test:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - $(SMALL)


gdbtest:
	cd build/ && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main -project=main -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - $(SMALL)


smalltest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - $(SMALL)

smallmixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - $(SMALL)

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - $(LARGE)

build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

longtest:
	cd build/ && rm -f Monitor* && nohup ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - $(LARGE) &

clean:
	rm -rf build/*


mixedres:
	grep $(SMALL) build/Monitor | tail -n1 | sed 's/.*"//g' > mixedres.txt

interpres:
	grep $(SMALL) build/Monitor | tail -n1 | sed 's/.*"//g' > interpres.txt
