ROOT?=/project
BIN?=main
CFLAGS?=-O1

all: build/main build/obj.dump


build/main:
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'


test:
	cd build/ && rm -f Monitor* && cp ../GutenburgDictionary.txt . && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false


smalltest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - ../harness.c

smallmixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - ../harness.c

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false  - ../harness.c

build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*


mixedres:
	grep harness build/Monitor > mixedres.txt

interpres:
	grep harness build/Monitor > interpres.txt
