import logging
import operator
from pathlib import Path
from hashlib import md5
from argparse import ArgumentParser
from translator import elffile
import sys
from multiprocessing import Pool


def md5sum(filename):
  with open(filename, 'rb') as fh:
    hsh = md5()
    for blck in iter(lambda: fh.read(4096), b""):
      hsh.update(blck)
  return hsh.hexdigest()


def print_header(fh, include_path):
  print('#include <stdint.h>', file=fh)
  print(f'#include "{include_path}"', file=fh)


def unbatched(data):
  fname, instrCtr, funcs, cartridge_pairs, springboard_functions, filters, include_path = data

  with open(fname, 'w') as fh:
    print_header(fh, include_path)
    if instrCtr == 0:
      print('void dummyMain () { ', file=fh)
      print('return; } ', file=fh)
      if filters is not None:
        for (name, instr) in springboard_functions.items():
          instr.emit_tase_springboard('_' + name.rpartition('sb_')[2])
          print(instr)
    for instrs in funcs:
      for instr in instrs:
        instrCtr += 1
        print(f"//InstrCtr {instrCtr}", file=fh)
        instr.emit_function(0)
        print(instr)

def batched(data):
  fname, instrCtr, funcs, cartridge_pairs, springboard_functions, filters, include_path = data
  in_cartridge = False
  current_cartridge = []
  var_count = 0

  with open(fname, 'w') as fh:
    print_header(fh, include_path)
    if instrCtr == 0:
      print('void dummyMain () { ', file=fh)
      print('return; } ', file=fh)
      if filters is not None:
        for (name, instr) in springboard_functions.items():
          instr._var_count = var_count
          instr.emit_tase_springboard('_' + name.rpartition('sb_')[2])
          var_count = instr._var_count
          print(instr)

    for instrs in funcs:
      for instr in instrs:
        instr._var_count = var_count
        instrCtr += 1
        print(f"//InstrCtr {instrCtr}", file=fh)

        if in_cartridge:
          if instr.vaddr + instr.length >= curr_cartridge[1]:
            print("//Cartridge end", file=fh)
            instr.emit_function(3)
            in_cartridge = False
          else:
            print("//In cartridge", file=fh)
            instr.emit_function(2)
        else:
          if instr.vaddr in cartridge_pairs:
            print("// Cartridge start", file=fh)
            curr_cartridge = cartridge_pairs[instr.vaddr]
            instr.emit_function(1)
            in_cartridge = True
            #Handle single instruction cartridge case:
            if instr.vaddr + instr.length >= curr_cartridge[1]:
              in_cartridge = False
              instr._emit_function_epilog()
          else:
            print("// Non-Cartridge record", file=fh)
            if all(x in instr.original for x in ("jumpq", "sb_reopen")) or ("leaq   0x5(%rip),%r15" in instr.original):
              print("//Skipping lea to r15 or jmp to sb_reopen", file=fh)
            else:
              instr.emit_function(0)
        print(instr)
        var_count = instr._var_count


def main(args):
  filters = []
  logging.basicConfig(level=logging.INFO)

  try:
    include_path = (Path(args['tase_include_dir']) / 'tase_interp_alt.h').resolve(strict=True)
    target_binary = Path(args['target_binary']).resolve(strict=True)

    if args['functions_file']:
      with open(Path(args['functions_file']).resolve(strict=True), 'r') as f:
        filters = set([l.strip() for l in f.readlines()])
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
    filters |= springboard_functions.keys()

  with Pool(args['threads']) as pool:
    p = elffile.ELFFile(target_binary, filter_functions=filters)
    all_instrs = []
    nop_instrs = []

    with open('cartridge_info.txt') as c:
      cartridge_pairs = {int(head) : (int(head), int(tail)) for head, tail in (line.split() for line in c)}

  #cartridge_pairs.add(start,end)
  # TODO: Ensure experiment integrity by logging time of run and
  # md5/size/time-of-modification of input binaries.
  #print('#include <cinttypes>')
#  file_counter = 0
#  fh = open(Path(f'{args["outname"]}.{file_counter}.cpp'), 'w')
#  print_header(fh, include_path)
    for name, disasm in sorted(p.fasm(pool=pool).items(), key=lambda x: x[1][0].vaddr):
      print(name, disasm)
      assert len(disasm) >= 1
      if args['log']:
        logging.info(f'{name} : {len(disasm)} instructions at {hex(disasm[0].vaddr)}')

      if name in springboard_functions:
        if args['log']:
          logging.info('  ! recognized spring board function')
          springboard_functions[name] = disasm[0]
      else:
        if args['log']:
          for instr in disasm:
            logging.info(f'  {instr.vaddr} {instr.op} -> {" | ".join([x.operand for x in instr.operands])}')
            logging.info(f'  {instr.size1 or 0} -({instr.sign_ext})-> {instr.size2 or 0}')
            all_instrs.append(instr)
        else:
          all_instrs.append(disasm)

    numFuncs = len(all_instrs)
    print("// Total functions: ", numFuncs)

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
  #
    minsize = 20
    groupsize = numFuncs // args['threads']
    if args['threads'] > 1 and groupsize < minsize:
      args['threads'] -= 1
      groupsize = numFuncs // args['threads']

    groupsize = groupsize if groupsize else 1
    groups = numFuncs // groupsize

    print("groups:",groups)

    if groups > 1:
      grouped = []
      for i in range(groups-1):
        grouped.append((f'{args["outname"]}.{i}.cpp', i*groupsize, all_instrs[i*groupsize:(i+1)*groupsize], cartridge_pairs, springboard_functions, filters, include_path))
      grouped.append((f'{args["outname"]}.{groups-1}.cpp', (groups-1)*groupsize, all_instrs[(groups-1)*groupsize:], cartridge_pairs, springboard_functions, filters, include_path))
    else:
      grouped = [(f'{args["outname"]}.{0}.cpp', 0, all_instrs, cartridge_pairs, springboard_functions, filters, include_path)]

    print('generating cpp files...')

    if not args['no_batch']:
      pool.map(batched, grouped)
    else:
      pool.map(unbatched, grouped)



parser = ArgumentParser()
parser.add_argument('target_binary', help='path for binary to analyze')
parser.add_argument('tase_include_dir', help='directory for tase include statements')
parser.add_argument('outname', help='output filename stem')
parser.add_argument('-f,--functions_file', dest="functions_file", type=str, help='file of function names for which IR will be generated')
parser.add_argument('-n,--no_batch', dest='no_batch', action='store_true', default=False, help='don\'t batch IR')
parser.add_argument('-t,--threads', dest='threads', type=int, default=4, help='number of threads')
parser.add_argument('-l,--logging', dest='log', action='store_true', default=False, help='logging output')
if __name__ == '__main__':
  main(vars(parser.parse_args()))
