SHELL=/bin/bash
NAME?=
TARGET?=tase$(NAME)
DIR?=
USER=--user $$(id -u):$$(id -g)

all: update tase_llvm_base tase_llvm tase container

.phony: update
update:
	git submodule update --init --jobs 7

.phony: tase_llvm_base
tase_llvm_base:
	docker build --network=host --no-cache --target tase_llvm -t tase_llvm_base .

.tase_llvm_id:
	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --mount type=bind,src=$$(pwd)/install_root/,dst=/install_root/ --name $(TARGET)_llvm_build -d tase_llvm_base > .tase_llvm_id

base_llvm:
	mkdir -p install_root/llvm-3.4.2 install_root/include/tase install_root/include/traps install_root/openssl/include install_root/scripts
	cd install_root && curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C llvm-3.4.2 --strip 1


tase_llvm: base_llvm .tase_llvm_id
	docker exec $(USER) $(TARGET)_llvm_build bash -c 'cd /TASE_BUILD/install/ && make -j 16 RUN_DIR=/install_root/ /install_root/objdump'
	docker exec $(USER) $(TARGET)_llvm_build bash -c 'cd /TASE_BUILD/install/ && make -j 16 RUN_DIR=/install_root/ tase_clang'


tase: .tase_llvm_id
	docker exec $(USER) $(TARGET)_llvm_build bash -c 'cd /TASE_BUILD/install && make -j 16 RUN_DIR=/install_root/ setup && make parseltongue'
	docker stop $(TARGET)_llvm_build


container: .tase_llvm_id
	docker exec $(TARGET)_llvm_build bash -c 'mkdir -p /TASE && cp -r /install_root/* /TASE/ && cp -r /TASE_BUILD/install/* /TASE/install/ && cp -r /TASE_BUILD/parseltongue86 /TASE/'
	docker tag $$(docker commit $(TARGET)_llvm_build | awk '{split($$0, m, /:/); print m[2]}') $(TARGET)
	docker rm -f $(TARGET)_llvm_build
	rm -f .tase_llvm_id

clean:
	make -C musl clean && rm -rf build/* && docker rm -f tase_llvm_build && rm -f .tase_llvm_id


# from container:	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --mount type=bind,src=$$(pwd)/install_root/,dst=/install_root/ --name $(TARGET)_llvm_build -d tase_llvm_base


#clean:
#	docker run --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --rm -it cleaner bash -c 'make -C /TASE_BUILD/musl/ clean && rm -rf /TASE_BUILD/build/*'


# directory:
# 	mkdir -p $(DIR)/llvm-3.4.2
# 	curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C $(DIR)/llvm-3.4.2 --strip 1
# 	mkdir -p $(DIR)/include/ $(DIR)/scripts/
# 	cp -r $$(pwd)/test/tase/include/tase/ $(DIR)/include/tase/
# 	cp -r $$(pwd)/test/other/ $(DIR)/include/traps/
# 	cp -r $$(pwd)/openssl/include/ $(DIR)/include/openssl/
# 	cp $$(pwd)/test/tase/tase_link.ld $(DIR)/
# 	cp -r $$(pwd)/test/scripts/ $(DIR)/scripts/
# 	env BUILD_DIR=$$(pwd) RUN_DIR=$(DIR) $(MAKE) -C install setup
# 	mkdir -p $(DIR)/install
# 	cp -r $$(pwd)/install/* $(DIR)/install/


klee-update:
	cd klee && git status --porcelain | awk '$$1=="M"{print $$2}' > ../klee_changes.txt
	while read line; do cp klee/$$line ~/current/TASE_KLEE/$$line; done < klee_changes.txt
	rm klee_changes.txt
	make -C ~/current/TASE_KLEE/update/
	git submodule update --remote --force klee
	git add klee
	git commit -m 'updated klee'
	git push

llvm-update:
	cd llvm && git status --porcelain | awk '$$1=="M"{print $$2}' > ../llvm_changes.txt
	while read line; do cp llvm/$$line ~/current/llvm/$$line; done < llvm_changes.txt
	make -C ~/current/llvm/update
	git submodule update --remote --force llvm
	git add llvm
	git commit -m 'updated llvm'
	git push

musl-update:
	cd musl && git status --porcelain | awk '$$1=="M"{print $$2}' > ../musl_changes.txt
	while read line; do cp musl/$$line ~/current/TASE_musl/$$line; done < musl_changes.txt
	make -C ~/current/TASE_musl/update
	git submodule update --remote --force musl
	git add musl
	git commit -m 'updated musl'
	git push

