# import logging
import re
import subprocess
from . import instruction
from itertools import chain

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
      r'code32|rep|repe|repne|repz|repnz) )*)'
      r'(?P<mnemonic>[0-9a-z]+)'
      r'(\s+(?P<operands>[^#]+))?')

  # Example:
  # 0000000000000000 0000000000000004 B ENCRYPT_ENABLED
  # 0000000000000008 0000000000000004 D EXTRA_WORK
  _regex_var_symbol = re.compile(
      r'^(?P<addr>[0-9a-f]+) (?P<size>[0-9a-f]+) '
      r'(?P<type>[^TtRrNp]) (?P<name>\S+)$')

  def __init__(self, file_path, filter_functions=None):
    """
    file_path: str  a path to ELF file to be objdumped and analyzed.
    filter_functions: [str]  a list of functions to disassemble.
        If this is None, all functions are disassembled.
    """
    self._file_path = file_path
    self._filter_functions = list(set(filter_functions)) if filter_functions else []
    self._fasm = {}
    self._vloc = {}
    # self._function_asm = dict() # name -> parsed assembly
    # self._vars_loc = dict() # name -> [(start address, length)] non-empty

  def __getattr__(self, name):
    if name == '_vars_loc':
      if self._vloc:
        return self._vloc
      return self._parse_nm_vars(self._nm())
    else:
      raise AttributeError

  def __len__(self):
    return len(self._function_asm)

  def vars_loc(self):
    return self._vars_loc

  def fasm(self, pool=None):
    if not self._fasm:
      if self._filter_functions:
        res = None
        if pool:
          pcs = len(pool._pool)
          gsize = len(self._filter_functions) // pcs
          groups = []
          for i in range(pcs):
            if i == pcs-1:
              groups.append((self._filter_functions[i*gsize:], i))
            else:
              groups.append((self._filter_functions[i*gsize:(i+1)*gsize], i))
          fnames = []
          for x in groups:
            fnames.append(f'.group-{x[1]}')
            with open(fnames[-1], 'w') as fh:
              for y in x[0]:
                print(y, file=fh)
          for x in pool.map(self._parse_objdump, fnames):
            self._fasm.update(x)
        else:
          self.fasm = self._parse_objdump()
      else:
        self._fasm = self._parse_objdump()
    return self._fasm

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


  def _parse_objdump(self, filename=None):
    """
    text: [str]
    """
    dupname_ctr = 0
    fname = None
    _fasm = {}
    lines = self._objdump(filename=filename)
    for line in lines:
      if fname and (result := self._regex_instr.match(line)):
        instr = instruction.Instruction(
          line,
          result.group('vaddr'), result.group('encoded'),
          result.group('prefix'), result.group('mnemonic'),
          result.group('operands').strip() if result.group('operands') else '', f'{filename}:{fname}')
        _fasm[fname].append(instr)
      elif not fname and (result := self._regex_function_header.match(line)):
        fname = result.group(1)
        if fname in _fasm:
          fname = f'{fname} duplicate {dupname_ctr}'
          dupname_ctr += 1
        _fasm[fname] = []
      else:
        fname = None
    return _fasm


  def _objdump(self, filename):
    status = subprocess.run([
        '/objdump',
        f'--disassemble_file={filename}' if filename else '-d',
        '-w',
        '-M', 'suffix',
        '-j', '.text',
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
