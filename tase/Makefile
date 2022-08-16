SRC=$(BUILD_DIR)/tase/src
DST=$(BUILD_DIR)/build/tase

TASE_OBJSA=$(addsuffix .o,$(addprefix $(DST)/springboard/,$(basename $(notdir $(wildcard $(SRC)/tase/springboard/*.c) $(wildcard $(SRC)/tase/springboard/springboard.S)))))

TASE_OBJSA2=$(addsuffix .o,$(addprefix $(DST)/springboard/,$(basename $(notdir $(wildcard $(SRC)/tase/springboard/*.c) $(wildcard $(SRC)/tase/springboard/springboard_notsx.S)))))

TASE_OBJSB=$(addsuffix .o,$(addprefix $(DST)/,$(basename $(notdir $(wildcard $(SRC)/tase/*.c)))))

TASE_SHIMOBJS=$(DST)/traps/tase_shims.o

TASE_OBJS=$(TASE_OBJSA) $(TASE_OBJSB) $(TASE_SHIMOBJS) $(SFLOAT_OBJS)
TASE_OBJS2=$(TASE_OBJSA2) $(TASE_OBJSB) $(TASE_SHIMOBJS) $(SFLOAT_OBJS)

SFLOAT_OBJS=$(addprefix $(DST)/compiler-rt_soft_float/,$(addsuffix .o,$(basename $(notdir $(wildcard $(SRC)/compiler-rt_soft_float/*.c)))))


all: $(RUN_DIR)/lib/libtase.a $(RUN_DIR)/lib/libtase_notsx.a $(TASE_LINK)

$(TASE_LINK):
	cp $(BUILD_DIR)/tase/tase_link.ld $(RUN_DIR)/tase_link.ld

$(RUN_DIR)/lib/libtase.a: dirs $(TASE_OBJS)
	ar crs $(RUN_DIR)/lib/libtase.a $(TASE_OBJS)

$(RUN_DIR)/lib/libtase_notsx.a: dirs $(TASE_OBJS2)
	ar crs $(RUN_DIR)/lib/libtase_notsx.a $(TASE_OBJS2)

.phony: dirs
dirs:
	mkdir -p $(DST)/traps/ $(DST)/compiler-rt_soft_float/ $(DST)/springboard/ $(RUN_DIR)/lib/

$(DST)/springboard/%.o: $(SRC)/tase/springboard/%.c
	$(TASE_CLANG) -fPIC -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(INCLUDE_DIR)/tase/  $(MODELED_FN_ARG) $< -o $@

$(DST)/springboard/%.o: $(SRC)/tase/springboard/%.S
	$(TASE_CLANG) -fPIC -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(INCLUDE_DIR)/tase/  $(MODELED_FN_ARG) $< -o $@


$(DST)/%.o: $(SRC)/tase/%.c
	$(CLANG) -fPIC -c -O1 -I$(INCLUDE_DIR)/tase/ $< -o $@

$(DST)/traps/%.o: $(SRC)/tase/traps/%.c
	$(TASE_CLANG) -fPIC -c -O0 -I$(INCLUDE_DIR)/tase/ $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@

$(DST)/compiler-rt_soft_float/%.o: $(SRC)/compiler-rt_soft_float/%.c
	$(CLANG) -c $< -o $@
