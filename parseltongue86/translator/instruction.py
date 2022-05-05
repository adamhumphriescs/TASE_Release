import functools
from itertools import chain
import logging
from . import operand as o
import re

# b,c -> CF=1, z,e -> ZF=1, l -> SF!=OF, o -> OF, p -> PF, s -> SF
COND_DEMORGAN = {'a': 'c', 'g': 'l'}
COND_ALIAS = {'b': 'c', 'e': 'z'}
COND_FLAG = {'c': o.FLAG_CF, 'z': o.FLAG_ZF, 'o': o.FLAG_OF, 'p': o.FLAG_PF, 's': o.FLAG_SF, 'd': o.FLAG_DF}

SUFFIX_COND_N_E = ['a', 'b', 'g', 'l']  # allows 'n' before and 'e' after it.
SUFFIX_COND_N = ['c', 'e', 'o', 'p', 's', 'z']  # allows 'n' before it.
SUFFIX_COND_P = ['pe', 'po']  # parity flags: pe -> p, po -> np
SUFFIX_COND_ALL = SUFFIX_COND_N_E + SUFFIX_COND_N + SUFFIX_COND_P
SUFFIX_SIZE = {'b': 1, 'w': 2, 'l': 4, 'q': 8}
SUFFIX_TEST = ['c', 'r', 's']
# d = 0 => increment.
SUFFIX_FLAG = ['c', 'd', 'i']

# Ordered by prefix length to avoid parse conflicts.
# Instructions used by transaction instrumentation - ignore these.
OPS_TRAN = ['xend', 'xbegin', 'xabort']

# Every instruction starting with f is an x87 floating point instruction.
# They can be ignored safely.
OPS_IGNORE = [
    'v',
    'f', 'ud',
    'pinsr', 'pcmpe', 'por', 'pxor', 'ptest',
    'movss', 'movsd', 'movhps', 'movdqa', 'movaps'
]

OPS_XCHG = [
    'cmpxchg8b', 'cmpxchg16b',
    'cmpxchg',  # {bwlq}
    'xadd', 'xchg'  # {bwlq}
]

OPS_MATH = [  # {bwlq} for all.
    'adc', 'add', 'sbb', 'sub',
    'cmp',
    'and', 'or', 'xor',
    'not', 'neg',
    'dec', 'inc',
    'div', 'idiv', 'mul', 'imul'
]

# Need to implement bsf/bsr - hint: look for deBruijn sequence trick.
OPS_BIT = [
    'set',  # allows SUFFIX_COND
    'bsf', 'bsr',  # {wlq}
    'bt',  # allows SUFFIX_TEST and #{wlq}.
    'test'  # {bwlq}
]

OPS_FLOW = [
    'call', 'ret',  # objdump adds q.
    'loop',  # allows 'n' and {ze}.
    'jmp',   # objdump adds q.
    'jecxz', 'jcxz',  # Invalid for x86-64 - reject.
    'j',  # allows SUFFIX_COND.
    'hlt'
]

# Need to implement thses
OPS_STR = [  # {bwlq} for all.
    'cmps', 'lods',
    'movs',  # Note that this will clash with movsx.
    'smov',  # Alias for movs - just canonicalize to movs.
    'scas', 'stos'
]

# clt* needs to come before cl
OPS_CONV = ['cbtw', 'cwtl', 'cltq', 'cwtd', 'cltd', 'cqtd', 'cqto']

OPS_FLAG = [
    'pushf', 'popf',  # allows {wlq}
    'cl', 'st',  # allows SUFFIX_FLAG
    'cmc'
]

OPS_SHIFT = [  # {lr}{bwlq}
    'rc', 'ro', 'sa',
    'sh',  # special case - allow for shld shrd.
    'sh_d'
]

OPS_DATA = [
    'bswap',  # {lq}
    'cmov',  # allows SUFFIX_COND and #{wlq}.
    'enter', 'leave',  # objdump adds q
    'lea',  # {wlq}
    'movabs',  # {bwlq} - eliminated during fixup.
    # Spelled movs in gas but renamed to avoid clash with string instruction.
    'movsx', 'movz',  # double suffix - eliminated during fixup.
    'mov',  # {bwlq}
    'nop',  # different nop widths result in objdump adding suffixes.
    'pop', 'push'  # {wlq}
]

OPS_SIZED = list(chain(OPS_XCHG[2:], OPS_MATH, OPS_SHIFT, OPS_BIT[1:],
                       OPS_FLOW[:-4], OPS_STR, OPS_FLAG[:2], OPS_DATA))
OPS_IMM32 = ['test', 'mov', OPS_MATH[:8]]

# OPS_STR needs to come early - to match cmps before cmp
# OPS_IGNORE comes fires to catch 'movaps' etc. before they get matched.
all_ops = [*OPS_IGNORE, *OPS_TRAN, *OPS_XCHG, *OPS_STR, *OPS_MATH, *OPS_BIT, *OPS_FLOW, *OPS_CONV, *OPS_FLAG, *OPS_SHIFT, *OPS_DATA]

# operand_re = re.compile(
#   r'(?P<pre>\*)?'
#   r'(%(?P<reg>\w+)(?=,|$)|'
#   r'(?P<addr>[0-9a-f]+)\s+<(?P<symbol>\S+)>|'
#   r'\$(?P<imm>(0x)?[0-9a-f]+)|'
#   r'(%(?P<seg>\w+):)?'
#   r'(?P<offset>-?(0x)?[0-9a-f]+)?'
#   r'(\((%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))?)')


# pre_re = r'(?P<pre>\*)?'
# operand_res = [re.compile(pre_re + x) for x in [r'%(?P<reg>\w+)(?=,|$)',
#                                                 r'(?P<addr>[0-9a-f]+)\s+<(?P<symbol>\S+)>(?=,|$)',
#                                                 r'\$(?P<imm>(0x)?[0-9a-f]+)(?=,|$)',
#                                                 r'%(?P<seg>\w+):(?P<offset>-?(0x)?[0-9a-f]+)(?=,|$)',
#                                                 r'%(?P<seg>\w+):(?P<offset>-?(0x)?[0-9a-f]+)(\((%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))(?=,|$)',
#                                                 r'(?P<offset>-?(0x)?[0-9a-f]+)?(\((%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))(?=,|$)']]

# A) % -> reg ,/$ | seg offset (bis)? ,/$
# B) \$ -> imm
# C) hex -> addr symbol ,/$ | offset (bis)? ,/$
# D) offset? (bis) ,/$

operand_res = [re.compile(x) for x in [
               r'^(?P<pre>\*)?%((?P<reg>\w+)(?=,|$)|((?P<seg>\w+):)(?P<offset>-?(0x)?[0-9a-f]+)(\((?!\))(%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))?)(?=,|$)',
               r'^\$(?P<imm>(0x)?[0-9a-f]+)(?=,|$)',
               r'^(?P<pre>\*)?\((%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\)(?=,|$)',
               r'^(?P<pre>\*)?(?P<addr>[0-9a-f]+)\s+<(?P<symbol>\S+)>(?=,|$)',
               r'(?P<pre>\*)?(?P<offset>-?(0x)?[0-9a-f]+)?(\((?!\))(%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))(?=,|$)',
               r'(?P<pre>\*)?(?P<offset>-?(0x)?[0-9a-f]+)']]


all_regnames = ['RIP', 'EFL', 'RAX', 'RBX', 'RCX', 'RDX', 'RSI', 'RDI', 'RSP', 'RBP', 'R8', 'R9', 'R10', 'R11', 'R12', 'R13', 'R14', 'R15']

dblookup64 = '0, 1, 48,  2, 57, 49, 28,  3,\n \
61, 58, 50, 42, 38, 29, 17,  4,\n \
62, 55, 59, 36, 53, 51, 43, 22,\n \
45, 39, 33, 30, 24, 18, 12,  5,\n \
63, 47, 56, 27, 60, 41, 37, 16,\n \
54, 35, 52, 21, 44, 32, 23, 11,\n \
46, 26, 40, 15, 34, 20, 31, 10,\n \
25, 14, 19,  9, 13,  8,  7,  6'
db64 = '0x03f79d71b4cb0a89'

class Instruction:
  """
  POD type for x86-64 instructions.

  original: str       the original instruction string - useful to print logs.
  vaddr:    int       address space location of instruction.
  length:   int       length of the instruction in bytes.
  prefixes: [str]     all the x86 prefixes used - see regex in elffile.
  mnemonic: str       the original mnemonic.
  op:       str       the mnemonic without any suffix if recognized.
  sign_ext: bool?     True for 's', False for 'z'.  None if unknown.
  size1:    int?      1,2,4 or 8.  None if unknown.
  size2:    int?      second size suffix if available. Similar to size2.
  cond:     str?      If operation is conditional, describes the condition.
  c_neg:    bool?     ' if it is negated.
  c_eq:     bool?     ' if equality is checked.
  c_left:   bool?     If operation is a shift, True if it goes left.
  c_noflag: bool?     ' if this is a BMI "x" variant shift instruction.
  flag_bit: str?      If operation is a flag operation, describes the flag.
  test_bit: str?      If operation is a test, describes the test bit.
  operands: [Operand] At most 3 operands listed in AT&T order.
  ignored:  bool      True if this needs no processing.
  """

  def __init__(self, original, vaddr, encoded, prefix, mnemonic, operands, var_count, fxn):

    """
    Parses out an instruction from a format that elffile generates.

    Yes yes... it should be a factory to facilitate alternative instantiations
    for testing but this is easier for now.

    original: str   the unparsed instruction line - used for debug output.
    vaddr:    str   unparsed vaddr (see above).
    encoded:  str   hex 'XX XX XX ' representation of instructions.  Can be ''.
    prefix:   str   unsplit string of prefix mnemonics.
    mnemonic  str   unparsed at&t mnemonic for an x86-64 instruction.
    operands  str?  string representing all operands (can be None).
    out       io.*  a file like object that supports appending strings.
    """
    # Use in test code later.
    # assert size1 is None or size1 in SUFFIX_SIZE.values()
    # assert size2 is None or size2 in SUFFIX_SIZE.values()
    # assert cond is None or cond in SUFFIX_COND_ALL
    # assert flag_bit is None or flag_bit in SUFFIX_FLAG
    # assert test_bit is None or test_bit in SUFFIX_TEST
    # assert src is None or isinstance(src, Operand)
    # assert dest is None or isinstance(dest, Operand)

    assert isinstance(original, str) and original, original
    self.original = original
    self.vaddr = int(vaddr, 16)

    self.length = len(encoded.split())
    assert self.length > 0 and self.length < 16
    self.fname = fxn
    self.prefixes = prefix.split()
    self.mnemonic = mnemonic.strip()
    self.sign_ext = None
    self.size1 = None
    self.size2 = None
    self.cond = None
    self.c_neg = None
    self.c_eq = None
    self.c_left = None
    self.c_noflag = None
    self.flag_bit = None
    self.test_bit = None
    self.operands = []
    self.out = ""
    self.ignored = False

    self._var_count = var_count

    try:
      (op, suffix) = self._parse_op()
      self.op = op
      assert suffix is not None, f'Unknown instruction in function {fxn}'
      self._parse_mnemonic(suffix)
      if not self.ignored:
        if operands:
          self._parse_operands(operands)
        self._fixup_instructions()

      self._parsed_result_message = f'<{vaddr}> : <{encoded}> : <{prefix}> : <{mnemonic}> : <{operands}>'

    except AssertionError as err:
      logging.error(f'Failed parsing assertion with:  {self.original}')
      logging.error(f'<{vaddr}> : <{encoded}> : <{prefix}> : <{mnemonic}> : <{operands}>')
      print(err, self.operands)
      raise err

    self.instrumentation = any(op.instrumentation for op in self.operands) or "fs:0x28" in self.original

  def __str__(self):
    return self.out

  # Functions to parse out objdump instruction output.

  def emit_get_flag(self, flags_mask, var):
    """
    Emit a statement that gets flags at their bit positions.

    flags_mask: int  An "or" of all the flags being fetched.
    var: str  Name of the variable that will hold the flag value.
    """
    self.out += f'  uint16_t {var} = {o._reg_exp_r("efl", size=2)} & {hex(flags_mask)};\n'


  def emit_set_flag(self, flags_mask, value, clean_clobber_flags=False):
    """
    Sets the given flags in the RFLAGS register.

    flags_mask: int  An "or" of the mask of all the flags being set.
    value: int  The values of the flags sepecified in flags_mask at their
              correct bit position with all other bits set to 0.
   clean_clobber_flags: bool  Completely clobber flags.
              Can be used on cmp instructions.
              Assumes our compiler only uses/sets the 5 cozps flags
              in eflags, which are clobbered by cmp.
    """
    efl = o._reg_exp_l('efl', size=8)


    if clean_clobber_flags:
      self.out += f'   {efl} = {value}; \n'
    else:
      self.out += f'  {efl} = ({efl} & ~({hex(flags_mask)})) | ({value});\n'

  def _parse_op(self):
    """
    returns (str, str):
      (matched operation, remaining suffix) or (unmatched full mnemonic, None)
    """
    for op in all_ops:
      if self.mnemonic.startswith(op):
        return (op, self.mnemonic[len(op):])
    return (self.mnemonic, None)

  def _parse_shift(self, suffix):
    assert suffix and suffix[0] in ['l', 'r'], 'Shift direction required'
    self.c_left = suffix[0] == 'l'
    if self.op == 'sh' and len(suffix) > 1 and suffix[1] == 'd':
      self.op = 'sh_d'
      suffix = suffix[2:]
    else:
      suffix = suffix[1:]
    self.c_noflag = len(suffix) > 1 and suffix[0] == 'x'
    if self.c_noflag:
      suffix = suffix[1:]

    return suffix

  def _parse_bt(self, suffix):
    if suffix and suffix[0] in SUFFIX_TEST:
      self.test_bit = suffix[0]
      suffix = suffix[1:]
    else:
      self.test_bit = ''
    return suffix

  def _parse_flag(self, suffix):
    assert len(suffix) > 0, 'An eflags fragment is required'
    assert suffix[0] in SUFFIX_FLAG, 'Unknown eflags bit'
    self.flag_bit = suffix[0]
    return suffix[1:]

  def _parse_cond(self, suffix):
    assert suffix, 'A condition fragment is required'
    if suffix[0] == 'q' and self.op == 'loop':
      return suffix

    if len(suffix) > 2 and suffix[:2] in SUFFIX_COND_P:
      self.c_neg = suffix[:2] == 'po'
      self.cond = 'p'
      self.c_eq = False
      return suffix[2:]

    if suffix[0] == 'n':
      self.c_neg = True
      suffix = suffix[1:]
    else:
      self.c_neg = False

    assert suffix, 'A known primary condition is required'
    assert suffix[0] in chain(SUFFIX_COND_N, SUFFIX_COND_N_E), (
        'Cannot use this suffix with a conditional')
    self.cond = suffix[0]
    if (suffix[0] in SUFFIX_COND_N_E and
            len(suffix) > 1 and suffix[1] == 'e'):
      self.c_eq = True
      suffix = suffix[2:]
    else:
      self.c_eq = suffix[0] == 'e'
      suffix = suffix[1:]

    # Simplifications:
    if self.cond in COND_DEMORGAN:
      self.c_eq = not self.c_eq
      self.c_neg = not self.c_neg
      self.cond = COND_DEMORGAN[self.cond]
    elif self.cond in COND_ALIAS:
      self.cond = COND_ALIAS[self.cond]

    return suffix

  def _parse_size(self, suffix):
    # Special case - objdump omits size suffix for a few of these.
    if self.op in ['nop', 'jmp'] and suffix == '':
      # TODO: Double check this.
      self.size1 = 8
      return suffix
    # Objdump byg - it doesn't emit bswap suffix even if forced to.
    elif self.op == 'bswap' and suffix == '':
      self.size1 = 4
      return suffix

    assert suffix, 'No operand size suffix'
    assert suffix[0] in SUFFIX_SIZE, 'Unknown size suffix'
    self.size1 = SUFFIX_SIZE[suffix[0]]

    if self.op in ['movsx', 'movz']:
      assert len(suffix) > 1, 'Need 2 operand size suffixes for movsx/movsz'
      assert suffix[1] in SUFFIX_SIZE, 'Unknown size suffix'
      self.size2 = SUFFIX_SIZE[suffix[1]]
      return suffix[2:]
    else:
      return suffix[1:]

  def _parse_mnemonic(self, suffix):
    assert self.op not in ['jecxz', 'jcxz'], 'Invalid instruction in x86-64'
    
    if 'xmm' in self.original:
      self.op = 'nop'
      suffix = ''
      self.ignored = True
    elif self.op == 'movs' and len(suffix) > 1:
      # Fixup movsx/movs/smov confusion.
      self.op = 'movsx'
    elif self.op == 'smov':
      self.op = 'movs'
    elif self.op in OPS_TRAN:
      self.op = 'nop'
      suffix = ''
    elif self.op in OPS_IGNORE:
      suffix = ''
      self.ignored = True
    # For debugging
    # elif self.op in OPS_STR:
    #   self.ignored = True
    
    if self.op in OPS_SHIFT:
      suffix = self._parse_shift(suffix)
    elif self.op == 'bt':
      suffix = self._parse_bt(suffix)
    elif self.op in ['cl', 'st']:
      suffix = self._parse_flag(suffix)
    elif self.op in ['set', 'j', 'loop', 'cmov']:
      suffix = self._parse_cond(suffix)

    if self.op in OPS_SIZED:
      suffix = self._parse_size(suffix)
    assert suffix == '', f'Unable to use all of the suffix: {suffix}'

  def _parse_operands(self, operand_str)
    prev = -1
    start = 0
    while start < len(operand_str):
      prev = start
      for x in operand_res:
        if (m := x.match(operand_str[start:])):
          start += m.end() - m.start() + 1
          self.operands.append(o.Operand(self, m.groupdict()))
      assert prev != start, f'Could not parse operand string: "{operand_str}", {self.operands}, failed at character {start} out of {len(operand_str)}'
    start -= 1
    assert start == len(operand_str), f'Could not parse operand string: "{operand_str}", {self.operands}, failed at character {start} out of {len(operand_str)}'


  def _fixup_instructions(self):
    # On x86-64, only mov and a very peculiar encoding of or are allowed to
    # load a 64-bit immediate (which gas calls movabs).  Otherwise all other
    # movq and arithmetic "q" instructions use 32-bit immediates which,
    # unlike the other mov{bwl}, sign-extend the immediate.
    if (self.op in OPS_IMM32 and self.size1 == 8 and
            self.operands[1].mode == o.MODE_IMM):
      self.size2 = 8
      self.size1 = 4
      self.sign_ext = True
    elif self.op == 'movsx' or self.op == 'movz':
      self.sign_ext = self.op == 'movsx'
      self.op = 'mov'
    elif self.op == 'movabs':
      self.sign_ext = False
      self.op = 'mov'
    elif self.op in ['cbtw', 'cwtl', 'cltq']:
      self.sign_ext = True
      self.size1 = SUFFIX_SIZE[self.op[1]]
      self.size2 = SUFFIX_SIZE[self.op[3]]
      self.op = 'mov'
      self.operands.extend([
          o.reg_operand(self, 'rax', self.size1),
          o.reg_operand(self, 'rax', self.size2)
      ])
    elif self.op in ['cwtd', 'cltd', 'cqtd', 'cqto']:
      # cqto is an alias for cqtd - so it'll get handled automatically.
      self.sign_ext = True
      self.size1 = SUFFIX_SIZE[self.op[1]]
      self.size2 = self.size1
      self.op = 'c_td'
      self.operands.extend([
          o.reg_operand(self, 'rax', self.size1),
          o.reg_operand(self, 'rdx', self.size2)
      ])
    elif self.op == 'jmp':
      self.op = 'j'
    elif self.op == 'j':
      self.size1 = 8
    elif self.op == 'set':
      self.size1 = 1
    elif self.op in ['idiv', 'imul']:
      self.sign_ext = True
      self.op = self.op[1:]
    elif self.op in ['div', 'mul']:
      self.sign_ext = False
    elif self.op in ['sa', 'sh']:
      self.sign_ext = self.op == 'sa'
      self.op = 'sh'
    elif self.op == 'hlt':
      self.op = 'nop'

    # Implicit shift form.
    if self.op in OPS_SHIFT:
      if len(self.operands) == (2 if self.op == 'sh_d' else 1):
        self.operands.insert(0, o.Operand(self, {'imm': '1'}))

      # A shift always has an amount and a destination
      # and the instruction suffix describes the destination.
      self.size2 = self.size1
      # Just to fuck with us, shrx and shlx take destination sized
      # registers for the shift amount. Otherwise, it is always
      # 8-bit values.
      if not (self.op == 'sh' and self.c_noflag):
        self.size1 = 1

  # Functions to emit IR after instruction is pars
  #
  #
  #ed.

  def emit_tase_springboard(self, suffix):
    """
      Emits an empty instruction IR function at this vaddr.
    """
    self._emit_function_prolog(suffix)
    self.out += '  // This function should never be executed.\n'
    self.out += f'  throw "Unreachable code for {suffix}";\n'
    self._emit_function_epilog()

  def emit_function(self, Type):
    """
      Top level function to output the C++ code for an instruction.
      "Type" Arg -
       0 - Non-cartridge record
       1 - Cartridge start  (include prolog and starting brace '{')
       2 - Inside cartridge (no prolog/epilog)
       3 - End of cartridge (include closing brace '}')
    """
    self.out += f'  // addr 0x{self.vaddr}\n'
    if "fs:0x28" in self.original:
      self.out += ' //Stackguard instruction with fs operand \n'
        
    if (Type == 0 or Type == 1):
      self._emit_function_prolog('')
    self.out += f'  rip_tmp = rip_tmp + {self.length};\n'
    
    if self.ignored or self.op == 'nop' or self.instrumentation:
      self.out += '  // Nothing to do\n'
    elif self.op == 'xchg':
      self._emit_xchg()
    elif self.op == 'xadd':
      self._emit_xadd()
    elif self.op == 'lea':
      self._emit_lea()
    elif self.op == 'mov':
      self._emit_mov()
    elif self.op == 'cmov':
      self._emit_cmov()
    elif self.op == 'c_td':
      self._emit_ctd()
    elif self.op == 'push':
      self._emit_push()
    elif self.op == 'pop':
      self._emit_pop()
    elif self.op == 'enter':
      self._emit_enter()
    elif self.op == 'leave':
      self._emit_leave()
    elif self.op == 'add':
      self._emit_add()
    elif self.op == 'sub':
      self._emit_add(sub=True)
    elif self.op == 'adc':
      self._emit_add(carry=True)
    elif self.op == 'sbb':
      self._emit_add(sub=True, carry=True)
    elif self.op == 'cmp':
      self._emit_add(sub=True, target_l=None, clean_clobber_flags=True)
    elif self.op == 'neg':
      self._emit_add(sub=True, arg_l=o.Operand(self, {'imm': '0'}), target_l=False)
    elif self.op == 'inc':
      self._emit_add(arg_l=self.operands[0], arg_r=o.Operand(self, {'imm': '1'}), set_carry=False)
    elif self.op == 'dec':
      self._emit_add(arg_l=self.operands[0], arg_r=o.Operand(self, {'imm': '1'}), sub=True, set_carry=False)
    elif self.op == 'mul':
      self._emit_mul()
    elif self.op == 'div':
      self._emit_div()
    elif self.op in ['and', 'or', 'xor']:
      self._emit_logical({'and': '&', 'or': '|', 'xor': '^'}[self.op])
    elif self.op == 'not':
      self._emit_not()
    elif self.op in OPS_SHIFT:
      self._emit_shift()
    elif self.op == 'call':
      self._emit_call()
    elif self.op == 'ret':
      self._emit_ret()
    elif self.op == 'loop':
      self._emit_loop()
    elif self.op == 'j':
      self._emit_jump()
    elif self.op == 'set':
      self._emit_set()
    elif self.op == 'bt':
      self._emit_bittest()
    elif self.op == 'test':
      self._emit_logical('&', write_target=False, clean_clobber_flags=True)
    elif self.op == 'bswap':
      self._emit_bswap()
    elif self.op == 'pushf':
      self._emit_push(src=o.Operand(self, {'reg': 'efl'}))
    elif self.op == 'popf':
      self._emit_pop(dest=o.Operand(self, {'reg': 'efl'}))
    elif self.op == 'cl':
      self._emit_flag(clear=True)
    elif self.op == 'st':
      self._emit_flag(clear=False)
    elif self.op == 'cmc':
      self._emit_cmc()
    elif self.op == 'bsr':
      self._emit_bsr()
    elif self.op == 'bsf':
      self._emit_bsf()
    else:
      raise ValueError(f"Encountered an instruction that we do not handle : {self.original}")
      # self.out += '  // Unimplemented\n'
    if (Type == 0 or Type == 3):
      self._emit_function_epilog()

  def _emit_function_prolog(self, suffix):
    #Grab all possible register values as local variables.
    #If we don't use the register while interpreting through
    #the basic block, then we don't write it back at the end of the
    #basic block, and the compiler optimizes out the
    #initial load.
    self.out += f'// {self.original}\n// {self._parsed_result_message}\nextern "C" void interp_fn_{self.vaddr:x}{suffix}(tase_greg_t* __restrict__ gregs) {{\n'
    self.out += '\n'.join([f'  uint64_t {x.lower()}_tmp = gregs[GREG_{x}];' for x in all_regnames]) + '\n'

  def _emit_function_epilog(self):
    self.out +='\n'.join(f'  gregs[GREG_{r.upper()}] = {r}_tmp;' for r in o.BB_ASSIGNED_REGS) + '\n}\n\n'
    o.clear_bb_reg_refs()

  def _make_var(self, prefix):
    self._var_count += 1
    return f'{prefix}{self._var_count}'

  def emit_var_decl(self, prefix, size, exp, signed=False):
    v = self._make_var(prefix)
    self.out += f'  {"__" if size == 16 else ""}{"" if signed else "u"}int{size*8}_t {v} = {exp};\n'
    return v

  def _emit_flag_decl(self):
    return self.emit_var_decl('efl', 2, '0')

  # Exchange instructions
  def _emit_xchg(self):
    src = self.operands[0]
    dest = self.operands[1]
    v_src = src.emit_fetch('src', self.size1)
    v_dest = dest.emit_fetch('dest', self.size1)
    src.emit_store(v_dest, self.size1)
    dest.emit_store(v_src, self.size1)

  def _emit_xadd(self):
    self._emit_xchg()
    self._emit_add()

  # Math instructions
  # Dang - we can't use __builtin_add_overflow and friends because they showed
  # up in Clang 4.0.

  def _emit_zps(self, v_efl, v_res):
    size = self.size1
    # Capture parity flag.
    # See https://graphics.stanford.edu/~seander/bithacks.html
    self.out += f'  {v_efl} |= ((0x6996 >> ((({v_res} >> 4) ^ {v_res}) & 0xf)) & 1) << {o.FLAG_PF};\n'
    # Capture zero flag.
    self.out += f'  {v_efl} |= ({v_res} == 0) << {o.FLAG_ZF};\n'
    # Capture sign flag.
    self.out += f'  {v_efl} |= ({v_res} >> {size*8 - o.FLAG_SF - 1}) & {hex(2**o.FLAG_SF)};\n'

  def _emit_store_cozps(self, v_efl, clean_clobber_flags=False):
    mask = functools.reduce(lambda acc, x: acc | 2 ** x,
                            [o.FLAG_CF, o.FLAG_PF, o.FLAG_ZF, o.FLAG_SF, o.FLAG_OF], 0)
    self.emit_set_flag(mask, v_efl, clean_clobber_flags)

  def _emit_add(self, arg_l=None, arg_r=None, carry=False, sub=False, target_l=True, set_carry=True, clean_clobber_flags=False):
    """
    carry: bool  Should the operation add or subtract the carry bit as well?
    target_l: bool  True if the result is written to arg_l. False to write in arg_r.
                    None to not write it at all.
    set_carry: bool  True if this operation updates the carry flag afterwards.
    clean_clobber_flags: bool Force-clobber flags with new value, rather than bitwise ORing.
    """
    arg_r = arg_r or self.operands[0]
    arg_l = arg_l or self.operands[1]
    size = self.size1
    op = '-' if sub else '+'

    # augend is also the minuend during subtraction.
    v_aug = arg_l.emit_fetch('augend', size)
    # addend is also the subtrahend during subtraction.
    v_add = arg_r.emit_fetch('addend', size)
    if carry:
      v_cf = self._make_var('cf')
      self.emit_get_flag(2 ** o.FLAG_CF, v_cf)
      # We know CF is bit 0 - so no need to explicitly shift it.
      # self.out += '  %s >>= %s;\n' % (v_cf, o.FLAG_CF)
      v_res = self.emit_var_decl('sum', size, f'{v_aug} {op} {v_add} {op} {v_cf}')
    else:
      v_res = self.emit_var_decl('sum', size, f'{v_aug} {op} {v_add}')

    v_efl = self._emit_flag_decl()
    if (target_l):
      arg_l.emit_store(v_res, size)
    elif (target_l is False):
      arg_r.emit_store(v_res, size)
    # else do nothing.

    # Capture 'overflow' in the MSB.
    # Shift all the way to the right and then shift back into position because
    # the overflow flag is in the second byte of EFLAGS and would need a left
    # shift for 8 byte operations.  The compiler will optimize this out.
    # Integer promotion will take care of ensuring that we have enough bytes
    # to perform the right-shift (see C99 6.3.1.1).
    # x + y + c   =>  ((x + y + c) ^ x) & ((x + y + c) ^ y))
    # x - y - c   =>  ((x - y - c) ^ x) & (x ^ y)
    self.out += f'  {v_efl} |= ((({v_res} ^ {v_aug}) & ({v_aug if sub else v_res} ^ {v_add})) >> {size*8-1}) << {o.FLAG_OF};\n'
    # Capture carry/borrow.
    # Use C++ integer promotion from boolean to 0/1 to simplify the expression.
    if set_carry:
      if carry:
        carry_str = f'{v_cf} ? {v_res} {">=" if sub else "<="} {v_aug} : '
      else:
        carry_str = ''
      self.out += f'  {v_efl} |= {carry_str}{v_res} {">" if sub else "<"} {v_aug};\n'

    # Compute Z/P/S as usual.
    self._emit_zps(v_efl, v_res)
    self._emit_store_cozps(v_efl, clean_clobber_flags)

  def _emit_mul(self):
    signed = self.sign_ext
    if signed and len(self.operands) == 3:
      multiplier = self.operands[0]
      multiplicand = self.operands[1]
      dest_lo = self.operands[2]
      dest_hi = None
    elif signed and len(self.operands) == 2:
      multiplier = self.operands[0]
      multiplicand = self.operands[1]
      dest_lo = multiplicand
      dest_hi = None
    else:
      assert len(self.operands) == 1
      multiplicand = o.reg_operand(self, 'rax', self.size1)
      multiplier = self.operands[0]
      dest_lo = multiplicand
      if self.size1 == 1:
        dest_hi = o.Operand(self, reg='ah')
      else:
        dest_hi = o.reg_operand(self, 'rdx', self.size1)

    v_multiplicand = multiplicand.emit_fetch('multiplicand', self.size1)
    v_multiplier = multiplier.emit_fetch('multiplier', self.size1)
    v_product = self.emit_var_decl('product', self.size1 * 2,
                                   f'{o.icast(v_multiplicand,self.size1*2,signed)} * {o.icast(v_multiplier,self.size1*2,signed)}',
                                   signed=signed)
    # Integral demotion should preserve the bitpattern we need here.
    v_lo = self.emit_var_decl('product_lo', self.size1, o.icast(v_product, self.size1))
    dest_lo.emit_store(v_lo, self.size1)
    v_hi = self.emit_var_decl('product_hi', self.size1,
                              o.icast(f'{v_product} >> {self.size1*8}', self.size1))
    if dest_hi:
      dest_hi.emit_store(v_hi, self.size1)

    mask = 2 ** o.FLAG_OF | 2 ** o.FLAG_CF
    if signed:
      self.emit_set_flag(mask,
                      f'{o.icast(v_lo, self.size1, signed=True)} >> {self.size1*8-1} == {o.icast(v_hi, self.size1, signed=True)} ? 0 : {hex(mask)}')
    else:
      self.emit_set_flag(mask, f'{v_hi} == 0 ? 0 : {hex(mask)}')


  def _emit_div(self):
    signed = self.sign_ext
    assert len(self.operands) == 1
    dividend_lo = o.reg_operand(self, 'rax', self.size1)
    quotient = dividend_lo
    if self.size1 == 1:
      dividend_hi = o.Operand(self, {'reg': 'ah'})
    else:
      dividend_hi = o.reg_operand(self, 'rdx', self.size1)
    remainder = dividend_hi
    divisor = self.operands[0]

    v_hi = dividend_hi.emit_fetch('div_hi', self.size1)
    v_lo = dividend_lo.emit_fetch('div_lo', self.size1)
    v_dividend = self.emit_var_decl('dividend', self.size1 * 2,
                                    f'{v_lo} | ({o.icast(v_hi,self.size1*2,signed)} << {self.size1*8})',
                                    signed=signed)
    v_divisor = divisor.emit_fetch('divisor', self.size1, signed=signed)
    # My understanding is that C++ and C99 defined their division standard to
    # basically conform to the behavior of idiv to make it easier for compilers.
    v_quotient = self.emit_var_decl('quotient', self.size1, f'{v_dividend} / {v_divisor}', signed=signed)
    v_remainder = self.emit_var_decl('remainder', self.size1, f'{v_dividend} % {v_divisor}', signed=signed)
    quotient.emit_store(v_quotient, self.size1)
    remainder.emit_store(v_remainder, self.size1)

  def _emit_logical(self, operator, write_target=True, clean_clobber_flags=False):
    src = self.operands[0]
    dest = self.operands[1]
    v_src = src.emit_fetch('src', self.size1)
    v_dest = dest.emit_fetch('dest', self.size1)
    v_res = self.emit_var_decl('result', self.size1, f'{v_dest} {operator} {v_src}')
    if write_target:
      dest.emit_store(v_res, self.size1)
    v_efl = self._emit_flag_decl()
    self._emit_zps(v_efl, v_res)
    # Automatically zeros out CF and OF because we initialize v_efl to 0.
    self._emit_store_cozps(v_efl, clean_clobber_flags=True)

  def _emit_not(self):
    dest = self.operands[0]
    v_src = dest.emit_fetch('src', self.size1)
    dest.emit_store(f'~ {v_src}', self.size1)

  # Flag bit tests

  def _emit_set(self):
    dest = self.operands[0]
    dest.emit_store('0', 1)
    self._emit_return_for_cond()
    if (self.cond):
      self.out += ' else { \n'
    dest.emit_store('1', 1)
    if (self.cond):
      self.out += ' } \n'

  def _emit_bittest(self):
    src = self.operands[0]
    dest = self.operands[1]
    assert self.size1
    # Assume that the compiler doesn't emit offsets that are out of range.
    assert dest.mode == o.MODE_REG
    v_offset1 = src.emit_fetch('offset_raw', self.size1)
    v_offset = self.emit_var_decl('offset', self.size1, f'{v_offset1} & {hex(self.size1*8-1)}')
    v_orig = dest.emit_fetch('orig', self.size1)

    v_bit = self.emit_var_decl('bit', self.size1, f'{v_orig} & (0x1ull << {v_offset})')
    self.emit_set_flag(2 ** o.FLAG_CF, f'({v_bit} >> {v_offset}) << {o.FLAG_CF}')
    if self.test_bit:
      modify_exp = {'c': '^', 'r': '& ~', 's': '|'}[self.test_bit]
      v_dest = self.emit_var_decl('final', self.size1, f'{v_orig} {modify_exp} (0x1ull << {v_offset})')
      dest.emit_store(v_dest, self.size1)

  def _emit_flag(self, clear):
    flag_mask = 2 ** COND_FLAG[self.flag_bit]
    self.emit_set_flag(flag_mask, 0 if clear else hex(flag_mask))

  def _emit_cmc(self):
    v_efl = self._emit_flag_decl()
    flag_mask = 2 ** o.FLAG_CF
    self.emit_get_flag(flag_mask, v_efl)
    self.emit_set_flag(flag_mask, f'{v_efl} ^ {hex(flag_mask)}')

  # Shift instructions

  def _emit_shift(self):
    op = '<<' if self.c_left else '>>'
    anti_op = '>>' if self.c_left else '<<'
    signed = bool(self.sign_ext)
    if self.op == 'sh_d':
      assert len(self.operands) == 3
      dest = self.operands[2]
      src = dest
    else:
      # The other 3 operand BMI instructions read from the middle and write
      # to the last register.
      assert len(self.operands) >= 2
      dest = self.operands[-1]
      src = self.operands[1]

    v_amt1 = self.operands[0].emit_fetch('amt_raw', self.size1)
    v_amt = self.emit_var_decl('amt', self.size1, f'{v_amt1} & {hex(63) if self.size2==8 else hex(31)}')
    v_src = src.emit_fetch('src', self.size2, signed=signed)
    v_shift = self.emit_var_decl('shift', self.size2, f'{v_src} {op} {v_amt}', signed=signed)

    if self.op in ['rc', 'ro', 'sh_d']:
      # Do not used signed fetched for v_bit_exp because we depend on
      # unsigned right shifts to truncate our value to only the fragment of
      # the original operand we wish to move back into the result.
      if self.op == 'sh_d':
        v_bit_exp = self.operands[1].emit_fetch('bit_exp', self.size2)
      else:
        v_bit_exp = dest.emit_fetch('bit_exp', self.size2)
        if self.op == 'rc':
          # Inject the carry bit into the shift bit source field.
          v_cf = self._make_var('cf')
          self.emit_get_flag(2 ** o.FLAG_CF, v_cf)
          self.out += f'  {v_bit_exp} = ({v_bit_exp} {anti_op} 1) | (({v_cf} >> {o.FLAG_CF}) << {self.size2*8-1 if self.c_left else 0});\n'
      self.out += f'  {v_shift} |= {v_bit_exp} {anti_op} ({self.size2*8} - {v_amt});\n'

    dest.emit_store(v_shift, self.size2)
    # Only compute flags when a shift occurs.
    # While some of this might look shady if you are only looking at the
    # intel documentation for certain instruction groups, they do apply
    # uniformly to all the shift instruction *in every situation where the
    # OF and CF bits are defined*.
    if not self.c_noflag:
      self.out += f' if ({v_amt} == 0) {{}}\n'
      self.out += ' else { \n'
      v_efl = self._emit_flag_decl()
      self._emit_zps(v_efl, v_shift)
      self.out += f'  {v_efl} |= ((({v_shift} ^ {v_src}) >> {self.size2*8-1}) & 0x1) << {o.FLAG_OF};\n'
      if self.c_left:
        shift_amt = f'({self.size2*8} - {v_amt})'
      else:
        shift_amt = f'({v_amt} - 1)'
      self.out += f'  {v_efl} |= (({v_src} >> {shift_amt}) & 0x1) << {o.FLAG_CF};\n'
      self._emit_store_cozps(v_efl)
      self.out += ' } \n'

  # Control Flow instructions

  def _emit_return_for_cond(self):
    if not self.cond:
      return None

    assert self.cond == 'l' or self.cond in COND_FLAG
    v_efl = self._make_var('efl')
    self.emit_get_flag(0xffff, v_efl)
    if self.cond == 'l':
      j_exp = f'(({v_efl} >> {o.FLAG_SF}) ^ ({v_efl} >> {o.FLAG_OF})) & 0x1'
    else:
      j_exp = f'{v_efl} & {hex(2**COND_FLAG[self.cond])}'
    if self.c_eq and self.cond != 'z':
      j_exp = f'({v_efl} & {hex(2**o.FLAG_ZF)}) || ({j_exp})'
    if not self.c_neg:
      # Yes this looks upside down.  But we use the condition to return early and
      # skip the branching logic.  So this expression is the 'failure condition'
      # for the branch.
      j_exp = f'!({j_exp})'
    #self.out += '  if (%s) return;\n' % j_exp
    self.out += f'  if ({j_exp}) {{}}\n'
    return v_efl

  def _emit_call(self):
    assert self.size1 == 8
    # We manually read the operand instad of just moving it because
    # our compiler is a crafty little bugger and gave us "call %rsp"
    # to deal with.
    v_target = self.operands[0].emit_fetch('target', self.size1)
    rip = o.Operand(self, {'reg': 'rip'})
    self._emit_push(src=rip, size=8)
    rip.emit_store(v_target, self.size1)

  def _emit_ret(self):
    assert self.size1 == 8
    self._emit_pop(dest=o.Operand(self, {'reg': 'rip'}), size=8)

  def _emit_loop(self):
    # I have no idea what this looks like in objdump.  This is a guess.
    assert self.operands[0].mode == o.MODE_MEM
    size = self.size1 or 8
    ctr = o.reg_operand(self, 'rcx', size)
    v_ctr = ctr.emit_fetch('ctr', size)
    self.out += f'  {v_ctr}--;\n'
    ctr.emit_store(v_ctr, size)

    self.out += f'  if ({v_ctr} == 0) return;\n'
    self._emit_jump()

  def _emit_jump(self):
    self._emit_return_for_cond()
    if (self.cond):
      self.out += ' else { \n'
    self._emit_mov(dest=o.Operand(self, {'reg': 'rip'}))
    if (self.cond):
      self.out += ' } \n'
  # Data instructions

  def _emit_mov(self, src=None, dest=None, size1=None, size2=None):
    src = src or self.operands[0]
    dest = dest or self.operands[1]
    size2 = size2 or size1 or self.size2 or self.size1
    size1 = size1 or self.size1

    v_in = src.emit_fetch('in', size1, signed=bool(self.sign_ext))
    if size1 != size2:
      v_conv = self.emit_var_decl('converted', size2, v_in, signed=bool(self.sign_ext))
    else:
      v_conv = v_in
    dest.emit_store(v_conv, size2)

  def _emit_lea(self, src=None, dest=None, size=None):
    # Technically we are not handling a default address size prefix (addr32)
    # but that is almost never used.
    src = src or self.operands[0]
    dest = dest or self.operands[1]
    size = size or self.size1
    assert (src.mode == o.MODE_MEM)
    dest.emit_store(o.icast(src.addr, size), size)

  def _emit_ctd(self):
    v_src = self.operands[0].emit_fetch('in', self.size1, signed=True)
    v_shift = self.emit_var_decl('shift', self.size2, f'{v_src} >> {self.size1*8-1}', signed=True)
    self.operands[1].emit_store(v_shift, self.size2)

  def _emit_bswap(self):
    reg = self.operands[0]
    self.size1 = reg.size
    assert (self.size1 == 4 or self.size1 == 8)
    v_reg = reg.emit_fetch('src', self.size1)
    byte_masks = ['0xff', '0xff00', '0xff0000', '0xff000000']
    exprs = []
    for i in range(self.size1 // 2):
      # Think of a qword byte swap.
      # The bytes need to shift by 7, 5, 3, 1 byte each symmetrically.
      shift_amt = (self.size1 - 2 * i - 1) * 8
      exprs.append(f'(({v_reg} >> {shift_amt}) & {byte_masks[i]})')
      exprs.append(f'(({v_reg} & {byte_masks[i]}) << {shift_amt})')

    v_swapped = self.emit_var_decl('swapped', self.size1, str.join(' | ', exprs))
    reg.emit_store(v_swapped, self.size1)

  def _emit_cmov(self):
    # CMOV forces truncation of the destination register even if the move fails
    # for x86-64 because YOLO!
    self._emit_mov(src=self.operands[1])
    self._emit_return_for_cond()
    if (self.cond):
      self.out += 'else { \n'
    self._emit_mov()
    if (self.cond):
      self.out += ' } \n'

  def _emit_push(self, src=None, size=None):
    src = src or self.operands[0]
    size = size or self.size1
    self._emit_lea(
        src=o.Operand(self, {'offset': f'-{hex(size)}', 'base' :'rsp'}),
        dest=o.Operand(self, {'reg': 'rsp'}),
        size=8)
    self._emit_mov(
        src=src,
        dest=o.Operand(self, {'base': 'rsp'}),
        size1=size)

  def _emit_pop(self, dest=None, size=None):
    dest = dest or self.operands[0]
    size = size or self.size1
    self._emit_mov(
        src=o.Operand(self, {'base': 'rsp'}),
        dest=dest,
        size1=size)
    self._emit_lea(
        src=o.Operand(self, {'offset': f'{hex(size)}', 'base': 'rsp'}),
        dest=o.Operand(self, {'reg': 'rsp'}),
        size=8)

  def _emit_enter(self):
    # Don't implement nested entry variant.
    assert (self.operands[0].mode == o.MODE_IMM and
            self.operands[1].mode == o.MODE_IMM and
            self.operands[1].imm == 0)
    alloc = self.operands[0].imm
    self._emit_push(
        src=o.Operand(self, {'reg': 'rbp'}),
        size=8)
    self._emit_mov(
        src=o.Operand(self, {'reg': 'rsp'}),
        dest=o.Operand(self, {'reg': 'rbp'}),
        size1=8)
    self._emit_lea(
        src=o.Operand(self, {'offset': f'-{hex(alloc)}', 'base': 'rsp'}),
        dest=o.Operand(self, {'reg': 'rsp'}),
        size=8)

  def _emit_leave(self):
    # Don't implement nested entry variant.
    self._emit_mov(
        src=o.Operand(self, {'reg': 'rbp'}),
        dest=o.Operand(self, {'reg': 'rsp'}),
        size1=8)
    self._emit_pop(
        dest=o.Operand(self, {'reg': 'rbp'}),
        size=8)

  def _emit_bsf(self):
    src = self.operands[0]
    dest = o.reg_operand(self, 'rax', 8)
    v_efl = self._emit_flag_decl()
    v = src.emit_fetch('v', 8)

    self.out += f'static const int DeBruijnPos[64] = {{{dblookup64}}};\n'

    # if src == 0
    # clear ZF, return
    self.out += f'if ({v} == 0) {{\n'
    self.out += f'{v_efl} &= ~(1<<{o.FLAG_ZF});\n'
    self._emit_store_cozps(v_efl)
    self.out += '} else { \n'

    # else
    final = self.emit_var_decl('final', 8, f'DeBruijnPos[(uint64_t)(({v}&-{v}) * {db64})>>58]', signed=True)
    dest.emit_store(final, 8)

    # set ZF
    self.out += f'{v_efl} &= 1<<{o.FLAG_ZF};\n'
    self._emit_store_cozps(v_efl)
    self.out += '}\n'
    
  def _emit_bsr(self):
    src = self.operands[0]
    dest = o.reg_operand(self, 'rax', 8)
    v_efl = self._emit_flag_decl()
    v = src.emit_fetch('v', 8)

    # src == 0 -> clear ZF, return
    self.out += f'if(!{v}) {{\n'
    self.out += f'{v_efl} &= ~(1<<{o.FLAG_ZF});\n'
    self._emit_store_cozps(v_efl)
    self.out += 'return;\n'
    self.out += '}\n'

    # count leading zeroes, subtract from size, store in register. Set ZF
    y=self.emit_var_decl('y', 4, '0', signed=False)
    r=self.emit_var_decl('r', 4, '0', signed=True)
    self.out += f'if({v}>>32) {y}={v}>>32, {r}=0; else {y}={v}, {r}=32;\n'
    self.out += f'if({y}>>16) {y}={y}>>16; else {r} |= 16;\n'
    self.out += f'if({y}>>8) {y}={y}>>8; else {r} |= 8;\n'
    self.out += f'if({y}>>4) {y}={y}>>4; else {r} |= 4;\n'
    self.out += f'if({y}>>2) {y}={y}>>2; else {r} |= 2;\n'
    final = self.emit_var_decl('final', 8, f'63 - ({r} | !({y}>>1))', signed=False)    
    self.out += f'{v_efl} |= (1<<{o.FLAG_ZF});\n'
    dest.emit_store(final, 8)
    self._emit_store_cozps(v_efl)
