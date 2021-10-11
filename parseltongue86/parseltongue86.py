import logging
import operator
from pathlib import Path
from hashlib import md5
from argparse import ArgumentParser
from translator import elffile
import sys


def md5sum(filename):
  with open(filename, 'rb') as fh:
    hsh = md5()
    for blck in iter(lambda: fh.read(4096), b""):
      hsh.update(blck)
  return hsh.hexdigest()


def main(args):
  logging.basicConfig(level=logging.INFO)

  try:
    include_path = (Path(args['tase_include_dir']) / 'tase_interp_alt.h').resolve(strict=True)
    target_binary = Path(args['target_binary']).resolve(strict=True)
  
    if args['functions_file']:
      with open(Path(args['functions_file']).resolve(strict=True), 'r') as f:
        filters = [l.strip() for l in f.readlines()]
    else:
      logging.error('No functions file found - falling back to disassembling all functions')
      filters = None  
        
  except FileNotFoundError as e:
    logging.error(f'{e}')
    raise e
  
  logging.info(f'{target_binary} md5sum: {md5sum(target_binary)}')

  # These are TASE functions that we need the address for but don't want to process
  # IR for normally.
  springboard_functions = { 'sb_open': None, 'sb_modeled_return': None}
  #springboard_functions = {'sb_inject': None, 'sb_eject': None, 'sb_reopen': None, 'sb_open': None, 'sb_modeled_return': None}

  if filters is not None:
    filters.extend(springboard_functions.keys())
  p = elffile.ELFFile(sys.stdout, target_binary, filter_functions=filters)
  all_instrs = []
  nop_instrs = []
  
  with open('cartridge_info.txt') as c:
    cartridge_pairs = {int(head) : (int(head), int(tail)) for head, tail in (line.split() for line in c)}
  cartridge_heads = set(cartridge_pairs.keys())


  #cartridge_pairs.add(start,end)
  # TODO: Ensure experiment integrity by logging time of run and
  # md5/size/time-of-modification of input binaries.
#  print('#include <cinttypes>')
  print('#include <stdint.h>')  
  print(f'#include "{include_path}"')
  print('void dummyMain () { ')
  print('return; } ')
  
  for name, disasm in p.items():
    assert len(disasm) >= 1
    logging.info(f'{name} : {len(disasm)} instructions at {hex(disasm[0].vaddr)}')

    if name in springboard_functions:
      logging.info('  ! recognized spring board function')
      springboard_functions[name] = disasm[0]
    else:
      for instr in disasm:
        logging.info(f'  {instr.vaddr} {instr.op} -> {" | ".join([x.operand for x in instr.operands])}')
        logging.info(f'  {instr.size1 or 0} -({instr.sign_ext})-> {instr.size2 or 0}')
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
        if instr.vaddr + instr.length >= curr_cartridge[1]:
          print("//Cartridge end")
          instr.emit_function(3)
          in_cartridge = False
        else:
          print("//In cartridge")
          instr.emit_function(2)
      else: 
        if instr.vaddr in cartridge_pairs:
          print("// Cartridge start")
          curr_cartridge = cartridge_pairs[instr.vaddr]
          instr.emit_function(1)
          in_cartridge = True
          #Handle single instruction cartridge case:
          if instr.vaddr + instr.length >= curr_cartridge[1]:
            in_cartridge = False
            instr._emit_function_epilog()
        else:
          print("// Non-Cartridge record")
          if all(x in instr.original for x in ("jumpq", "sb_reopen")) or ("leaq   0x5(%rip),%r15" in instr.original):
            print("//Skipping lea to r15 or jmp to sb_reopen")
          else:
            instr.emit_function(0)
    else:
      instr.emit_function(0)

      
parser = ArgumentParser()
parser.add_argument('target_binary', help='path for binary to analyze')
parser.add_argument('tase_include_dir', help='directory for tase include statements')
parser.add_argument('-f,--functions_file', dest="functions_file", help='file of function names for which IR will be generated')

if __name__ == '__main__':
  main(vars(parser.parse_args()))
