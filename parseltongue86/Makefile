.PHONY: init lint test run clean
.DEFAULT_GOAL = run

# TODO: Use the llvm version that klee wants.

TARGET_PROJ = aes
TARGET_BIN = ../test/$(TARGET_PROJ)/$(TARGET_PROJ)
LLVM_DIR = /opt/llvm-3.4.2/bin

CLEAN_FILES = $(TARGET_PROJ).cpp $(TARGET_PROJ).bc $(TARGET_PROJ).ll $(TARGET_PROJ).vars

init:
	pip3 install -r requirements.txt

lint:
	python3 -m flake8 .

autofix:
	autopep8 --recursive --indent-size=2 --in-place --max-line-length 120 .

test: lint
	python3 -m pytest

# TODO: Double check if -O3 is valid given the "well-derived pointer" rules
# or if we need to go to C++14 and decorate the crap out of our pointer casts
# for sensible aliasing semantics.
$(TARGET_PROJ).cpp: $(TARGET_BIN) $(TARGET_BIN).tase parseltongue86.py
	python3 parseltongue86.py $< > $@

$(TARGET_PROJ).bc: $(TARGET_PROJ).cpp
	$(LLVM_DIR)/clang++ -fno-slp-vectorize -Wall -Wextra -O3 -emit-llvm -o $@ -c $< -std=c++11
	$(LLVM_DIR)/llvm-dis $@

$(TARGET_PROJ).vars: $(TARGET_BIN) $(TARGET_BIN).a rosettastone.py
	python3 rosettastone.py $< > $@

run: $(TARGET_PROJ).cpp $(TARGET_PROJ).bc $(TARGET_PROJ).vars

bash_run:
	python3 parseltongue86.py /bin/bash > bash.cpp
	$(LLVM_DIR)/clang++ -fno-slp-vectorize -Wall -Wextra -O3 -emit-llvm -o bash.bc -c bash.cpp -std=c++11
	$(LLVM_DIR)/llvm-dis bash.bc

clean:
	${RM} $(CLEAN_FILES)
