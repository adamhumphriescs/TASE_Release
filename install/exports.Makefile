export BUILD_DIR?=/TASE_BUILD
export RUN_DIR?=/TASE

# all headers
export INCLUDE_DIR=$(RUN_DIR)/include

export TASE_CLANG=$(RUN_DIR)/bin/clang
export CLANG=$(RUN_DIR)/llvm-3.4.2/bin/clang

# TASE headers + .c/S files
TASE_DIR=$(BUILD_DIR)/tase
export TASE_LINK=$(RUN_DIR)/tase_link.ld

# options for TASE compilation
export MODELED_FN_ARG=-mllvm -x86-tase-modeled-functions=$(INCLUDE_DIR)/tase/core_modeled.h -mllvm -x86-tase-instrumentation-mode=naive
export NO_FLOAT_ARG=-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx

export LLVM_LIBS=$(addprefix $(RUN_DIR)/llvm-3.4.2/lib/,libLLVMInstrumentation.a libLLVMIRReader.a libLLVMAsmParser.a libLLVMOption.a libLLVMLTO.a libLLVMLinker.a libLLVMipo.a libLLVMVectorize.a libLLVMTableGen.a libLLVMX86Disassembler.a libLLVMX86AsmParser.a libLLVMX86CodeGen.a libLLVMSelectionDAG.a libLLVMAsmPrinter.a libLLVMMCDisassembler.a libLLVMMCParser.a libLLVMX86Desc.a libLLVMX86Info.a libLLVMX86AsmPrinter.a libLLVMX86Utils.a libLLVMInterpreter.a libLLVMMCJIT.a libLLVMRuntimeDyld.a libLLVMExecutionEngine.a libLLVMCodeGen.a libLLVMObjCARCOpts.a libLLVMScalarOpts.a libLLVMInstCombine.a libLLVMTransformUtils.a libLLVMAnalysis.a libLLVMTarget.a libLLVMMC.a libLLVMObject.a libLLVMBitWriter.a libLLVMBitReader.a libLLVMCore.a libLLVMSupport.a libLLVMJIT.a libLTO.a libLLVMipa.a)

export KLEE_LIBS=kleeTase kleeSupport kleeModule kleeCore kleeBasic kleaverSolver kleaverExpr
export KLEE_LINK_LIBS=$(addprefix $(RUN_DIR)/lib/,$(addprefix lib,$(addsuffix .a,$(KLEE_LIBS))) libtase.a libminisat.a libstp.a)
export KLEE_BITCODE=$(addprefix $(RUN_DIR)/install/klee_bitcode/,klee-libc.bc kleeRuntimeIntrinsic.bc)
