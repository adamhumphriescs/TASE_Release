# import logging
import re
import subprocess
from . import instruction
from itertools import chain
#from multiprocessing import Pool
import concurrent.futures

class ELFFile():
  """
  Disassembles functions from a given ELF file.
  Acts as a dictionary mapping function names to their
  disassembled values after the first access to the dictionary.

  A disassembly for a function is a list of Instruction objects.
  """

  # Example:
  # 0000000000400760 <add_fruit_to_basket>:
  _regex_function_header = re.compile(
      r'^[0-9a-f]{16}\s+<(\S+)>:$')

  # Example:
  #   400861:  aa bb cc dd ee ff  data16 data16 data16 data16 data16 nopw %cs:0x0(%rax,%rax,1)
  _regex_instr = re.compile(
      r'^\s*(?P<vaddr>[0-9a-f]+):\s+'
      r'(?P<encoded>([0-9a-z]{2}\s)+)\s*'
      r'(?P<prefix>((lock|data16|data32|code16|'
      r'code32|rep|repe|repne|repz|repnz|cs) )*)'
      r'(?P<mnemonic>[0-9a-z]+)'
      r'(\s+(?P<operands>[^#]+))?')

  # Example:
  # 0000000000000000 0000000000000004 B ENCRYPT_ENABLED
  # 0000000000000008 0000000000000004 D EXTRA_WORK
  _regex_var_symbol = re.compile(
      r'^(?P<addr>[0-9a-f]+) (?P<size>[0-9a-f]+) '
      r'(?P<type>[^TtRrNp]) (?P<name>\S+)$')

  def __init__(self, file_path, nobatch=False, include_path=None, cartridge_pairs={}, springboard_functions=set(), filter_functions=[]):
    """
    file_path: str  a path to ELF file to be objdumped and analyzed.
    filter_functions: [str]  a list of functions to disassemble.
        If this is None, all functions are disassembled.
    """
    self._file_path = file_path
    self.include_path = include_path
    self._filter_functions = filter_functions
    self._springboard_functions = springboard_functions
    self.cartridge_pairs = cartridge_pairs
    self.functions = {}
    self._vloc = {}
    self.instrCtr = 0
    self._instr_ = self._instr_nobatch if nobatch else self._instr

  def __getattr__(self, name):
    if name == '_vars_loc':
      if self._vloc:
        return self._vloc
      return self._parse_nm_vars(self._nm())
    else:
      raise AttributeError

  def vars_loc(self):
    return self.__getattr__('_vars_loc')
    
  def __len__(self):
    return len(self._function_asm)

  def fasm(self, outname, threads=None):
    if threads and self._filter_functions:
      gsize = len(self._filter_functions) // threads
      groups = []
      for i in range(threads):
        if i == threads-1:
          groups.append(self._filter_functions[i*gsize:])
        else:
          groups.append(self._filter_functions[i*gsize:(i+1)*gsize])
      fnames = []
      for i, x in enumerate(groups):
        fnames.append((f'build/bitcode/{outname}.interp.{i}.cpp', f'.group-{i}', i == 0))
        with open(fnames[-1][1], 'w') as fh:
          for y in x:
            print(y, file=fh)
      with concurrent.futures.ThreadPoolExecutor(threads) as pool:
        pool.map(self._parse_objdump, fnames)
        
    else:
      self._parse_objdump((f'build/bitcode/{outname}.interp.0.cpp', 'build/main.tase', True))

  def _parse_nm_vars(self, text):
    """
    text: [str]
    """
    for line in text:
      if (result := self._regex_var_symbol.match(line)):
        # We may have multiple symbols corresponding to the same object
        # name if they are local and static. Collect all of them in
        # a list.
        addr = int(result.group('addr'), 16)
        size = int(result.group('size'), 16)
        self._vloc.setdefault(result.group('name'), []).append((addr, size))
    return self._vloc

  def _instr(self, fh, instr, current_cartridge):
    try:
      if current_cartridge:
        if instr.vaddr + instr.length >= current_cartridge[1]:
          print(f'//Cartridge end in fxn {instr.fname}', file=fh)
          instr.emit_function(3)
          current_cartridge = False
        else:
          print('//In cartridge', file=fh)
          instr.emit_function(2)
      else:
        if instr.vaddr in self.cartridge_pairs:
          print(f'//Cartridge start in fxn {instr.fname}', file=fh)
          current_cartridge = self.cartridge_pairs[instr.vaddr]
          instr.emit_function(1)
          if instr.vaddr + instr.length >= current_cartridge[1]:
            current_cartridge = None
            instr._emit_function_epilog()
        else:
          print(f'//Non-cartridge record in fxn {instr.fname}', file=fh)
          if all(x in instr.original for x in ('jmpq', 'sb_reopen')) or ('leaq   0x5(%rip),%r15' in instr.original):
            print("//Skipping lea to r15 or jmp to sb_reopen", file=fh)
          else:
            instr.emit_function(0)
    except:
      print(f'Error generating Instr: {instr.fname} -> {instr.original}')
      print(f'{instr.op}: {instr.operands}')
      raise
    print(instr, file=fh)
    return instr._var_count, current_cartridge


  def _instr_nobatch(self, fh, instr, current_cartridge):
    try:
      instr.emit_function(0)
    except:
      print(f'Error generating Instr: {instr.fname} -> {instr.original}')
      print(f'{instr.op}: {instr.operands}')
      raise
    print(instr, file=fh)
    return instr._var_count, current_cartridge


  def print_header(self, fh):
    print('#include <stdint.h>', file=fh)
    print(f'#include "{self.include_path}"', file=fh)


  def _parse_objdump(self, data):
    outname, filterFile, first = data # nobatch, 
    with open(outname, 'w') as fh:
      dupname_ctr = 0
      fname = None
      current_cartridge = None
      instrCtr = 0
      var_count = 0
      _fasm = {}

      self.print_header(fh)

      if first:
        print('void dummyMain () { ', file=fh)
        print('return; } ', file=fh)

      lines = self._objdump(filterFile=filterFile)
      for line in lines:
        if fname and (result := self._regex_instr.match(line)):
          instr = instruction.Instruction(
            line,
            result.group('vaddr'), result.group('encoded'),
            result.group('prefix'), result.group('mnemonic'),
            result.group('operands').strip() if result.group('operands') else '', var_count, f'{filterFile}:{fname}')
          instrCtr += 1
          if fname in self._springboard_functions and self._filter_functions:
            instr.emit_tase_springboard(f'_{fname.rpartition("sb_")[2]}')
            var_count = instr._var_count
          else:
            var_count, current_cartridge = self._instr_(fh, instr, current_cartridge)
        elif not fname and (result := self._regex_function_header.match(line)):
          var_count = 0
          fname = result.group(1)
          if fname in _fasm:
            fname = f'{fname} duplicate {dupname_ctr}'
            dupname_ctr += 1
        else:
          fname = None

  def _objdump(self, filterFile=None):
    status = subprocess.run([
        '/TASE/objdump',
        f'--disassemble_file={filterFile}' if filterFile else '-d',
        '-w',
        '-M', 'suffix',
        '-j', '.text',
        '-j', '.plt',
        self._file_path],
        stdout=subprocess.PIPE,
        universal_newlines=True)
    return status.stdout.splitlines()

  def _nm(self):
    status = subprocess.run([
        'nm',
        '--print-size',
        '--numeric-sort',
        self._file_path],
        stdout=subprocess.PIPE,
        universal_newlines=True)
    return status.stdout.splitlines()
