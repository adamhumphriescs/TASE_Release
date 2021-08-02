import logging
import operator
import sys
import os
from translator import elffile


def main():
  logging.basicConfig(level=logging.INFO)
  assert(len(sys.argv) > 3)

  # Required argument 1 - path to binary to analyze (e.g., "TASE")
  target_binary = sys.argv[1]
  # Argument 2 - path to file that contains the names of functions
  # for which parseltongue will gen IR (e.g., "SomeProject.tase")
  functions_file = sys.argv[2] 

  #Arg for root tase dir for use in "include" statement later
  #(e.g., "/TASE/")
  tase_root_dir = sys.argv[3]
  
  #tase_root_dir = os.environ.get('TASE_ROOT_DIR')
  #logging.info('tase_root_dir is %s ' % tase_root_dir)
  #if tase_root_dir ==  'None':
  #  raise ValueError('Unable to find TASE_ROOT_DIR environment variable.')
  
  try:
    with open(functions_file, 'r') as f:
      filters = f.readlines()
      filters = [l.strip() for l in filters]
  except FileNotFoundError:
    logging.error('No tase file found - falling back to disassembling all functions')
    filters = None

  # These are TASE functions that we need the address for but don't want to process
  # IR for normally.
  springboard_functions = { 'sb_open': None, 'sb_modeled_return': None}
  #springboard_functions = {'sb_inject': None, 'sb_eject': None, 'sb_reopen': None, 'sb_open': None, 'sb_modeled_return': None}
  if filters is not None:
    filters.extend(springboard_functions.keys())
  p = elffile.ELFFile(sys.stdout, target_binary, filter_functions=filters)
  all_instrs = []
  nop_instrs = []

  cartridge_heads = set()
  cartridge_pairs = {}
  
  with open('cartridge_info.txt') as c:
    for line in c:
      head,tail =  line.split(" ")
      cartridge_heads.add(int(head))
      cartridge_pairs[int(head)] = [int(head), int(tail)]


  #cartridge_pairs.add(start,end)
  # TODO: Ensure experiment integrity by logging time of run and
  # md5/size/time-of-modification of input binaries.
#  print('#include <cinttypes>')
  print('#include <stdint.h>')

  include_string = '#include "' + tase_root_dir + '/test/tase/include/tase/tase_interp_alt.h"'
  print(include_string)
  #print('#include "/test/tase/include/tase/tase_interp_alt.h"')

  print('void dummyMain () { ')
  print('return; } ')
  for name, disasm in p.items():
    assert len(disasm) >= 1
    logging.info(
        '%s : %d instructions at %s',
        name, len(disasm), hex(disasm[0].vaddr))

    if name in springboard_functions:
      logging.info('  ! recognized spring board function')
      springboard_functions[name] = disasm[0]
    else:
      for instr in disasm:
        logging.info(
            '  %x %s -> %s', instr.vaddr, instr.op,
            ' | '.join([x.operand for x in instr.operands]))
        logging.info('  %d -(%s)-> %d',
                     instr.size1 or 0, instr.sign_ext, instr.size2 or 0)
        all_instrs.append(instr)

  if filters is not None:
    for (name, instr) in springboard_functions.items():
      instr.emit_tase_springboard('_' + name.rpartition('sb_')[2])

  numInstrs = len(all_instrs) 
  print("// Total x86 instructions: ", numInstrs)
  
  in_cartridge = False
  curr_cartridge  = []
  batch_IR = True
  instrCtr = 0

  #Iterate through each instruction ordered by address.
  #We use the cartridge start and end points from tase_global_records
  #to determine how to call emit_function.  emit_function(0) emits
  #an independent record, while emit_function(1) and emit_function(3)
  #emit the record plus the start (ex " extern "C" void interp_fn_6b134 (tase_greg_t * gregs) {"
  # and end (ex " }")  of the cartridge respectivley.  emit_function(2)
  #only emits the interpretation code for the instruction without the 
  #start or end portions, and should only be used within a cartridge.

  #We should replace the constants passed into emit_function
  #with an enum that is more intuitive.
  
  for instr in sorted(all_instrs, key=operator.attrgetter('vaddr')):
    instrCtr += 1
    print ("//InstrCtr ",instrCtr)
    if batch_IR:
      if in_cartridge:
        if (instr.vaddr + instr.length >= curr_cartridge[1]):
          print("//Cartridge end")
          instr.emit_function(3)
          in_cartridge = False
        else:
          print("//In cartridge")
          instr.emit_function(2)
      else: 
        if (instr.vaddr in cartridge_pairs):
          print("// Cartridge start")
          curr_cartridge = cartridge_pairs[instr.vaddr]
          instr.emit_function(1)
          in_cartridge = True
          #Handle single instruction cartridge case:
          if (instr.vaddr + instr.length >= curr_cartridge[1]):
            in_cartridge = False
            #print(' }\n')
            instr._emit_function_epilog()
        else:
          print("// Non-Cartridge record")
          if ( ("jmpq" in instr.original and "sb_reopen" in instr.original) or ("leaq   0x5(%rip),%r15" in instr.original)):
            print("//Skipping lea to r15 or jmp to sb_reopen")
          else:
            instr.emit_function(0)
    else:
      instr.emit_function(0)


if __name__ == '__main__':
  sys.exit(main())
