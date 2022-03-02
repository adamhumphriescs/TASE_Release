import re

MODE_IMM = 0
MODE_REG = 1
MODE_MEM = 2
MODE_ADDR = 3

modes = {'addr': MODE_ADDR, 'reg': MODE_REG, 'imm': MODE_IMM, 'offset': MODE_MEM, 'base': MODE_MEM}

REG_64 = ['rax', 'rbx', 'rcx', 'rdx', 'rsi', 'rdi', 'rsp', 'rbp',
          'r8', 'r9', 'r10', 'r11', 'r12', 'r13', 'r14', 'r15',
          'rip', 'efl']

REG_32 = ([r.replace('r', 'e') for r in REG_64[:8]] +
          [r + 'd' for r in REG_64[8:16]])

REG_16 = ([r.replace('r', '') for r in REG_64[:8]] +
          [r + 'w' for r in REG_64[8:16]])

REG_8L = ([r.replace('x', 'l') for r in REG_16[:4]] +
          [r + 'l' for r in REG_16[4:8]] +
          [r + 'b' for r in REG_64[8:16]])

REG_8H = [r.replace('l', 'h') for r in REG_8L[:8]]

REG_SIZE_MAP = {8: REG_64, 4: REG_32, 2: REG_16, 1: REG_8L}

BASE_REG = {}
for lst in [REG_64, REG_32, REG_16, REG_8L, REG_8H]:
  for idx, x in enumerate(lst):
    BASE_REG[x] = REG_64[idx]

REG_SIZE = {}
REG_SIZE.update({x:8 for x in REG_64})
REG_SIZE.update({x:4 for x in REG_32})
REG_SIZE.update({x:2 for x in REG_16})
REG_SIZE.update({x:1 for x in REG_8L + REG_8H})


#Array that holds registers assigned during basic block.
#We use this to know which registers to "write back" into
#the register file at the end of a basic block's worth of
#interpretation.
BB_ASSIGNED_REGS = set(['rip'])

FLAG_BITS = 16
FLAG_CF = 0
FLAG_PF = 2
# We don't support BCD.
# FLAG_AF = 4
FLAG_ZF = 6
FLAG_SF = 7
FLAG_DF = 10
FLAG_OF = 11

def add_bb_reg_ref(reg):
  if reg not in REG_64:
    assert False, f'Error: attempting to pass invalid register {reg} to add_bb_reg_ref'
  BB_ASSIGNED_REGS.add(reg)

def clear_bb_reg_refs():
  BB_ASSIGNED_REGS = set(['rip'])

# def tmp_reg_name(reg):
#   if reg in REG_64:
#     return  reg + '_tmp'
#   assert False, f'Error: called tmp_reg_name on reg {reg}'

def icast(exp, size, signed=False):
  assert size in [1, 2, 4, 8, 16]
  return f'static_cast<{"__" if size == 16 else ""}{"int" if signed else "uint"}{size*8}_t>({exp})'


def _reg_exp_r(reg, size=None):
  """
  rvalue expression for register.  Takes an objdump style register
  name "%rax" and produces an rvalue.
  """
  size = size if size else REG_SIZE.get(reg, 1)
  return f'(uint8_t) ({BASE_REG[reg]}_tmp >> 8)' if reg in REG_8H else f'(uint{size*8}_t) {BASE_REG[reg]}_tmp'

def _reg_exp_l(reg, size=None):
  """
  lvalue expression for register.  Takes an objdump style register 
  name "%rax" and produces an lvalue.
  Throws an error if size is not 8 bytes, since we've switched
  to using temp vars (e.g., tmp_rax) instead of pointer expressions.
  """
  size = size if size else REG_SIZE.get(reg, 1)
  assert size == 8, f'Error: Invalid size {size} passed to reg_exp_l'

  reg_name = BASE_REG[reg]
  add_bb_reg_ref(reg_name)
  return f'{reg_name}_tmp'
  

  
def _reg_exp(reg, size=None):
  """
  Encapsulates all our accesses to the C++ register file structure.
  Takes an objdump style register name "%rax" and produces an
  lvalue (which in our case also trivially converts to an rvalue).
  """
  reg_name = BASE_REG[reg].upper()
  #Special case
  if reg_name == 'RIP':
    return 'rip_tmp'

  size = size if size else REG_SIZE.get(reg, 1)
  cast_str = f'reinterpret_cast<uint{size*8}_t*>(gregs + GREG_{reg_name})'
  # Stupid unaligned access case.
  return f'({cast_str})[1]' if reg in REG_8H else f'*{cast_str}'


def reg_operand(instr, base_reg, size):
  return Operand(instr, {'reg': REG_SIZE_MAP[size][REG_64.index(base_reg)]})


class Operand:

  def __init__(self, instr, vals):
    """
    instr:         Instruction  the parent this operand is tied to.
    all_operands:  str          one or more unparsed operands (AT&T syntax).
    """
    self.instr = instr
    self.mode = None
    self.reg = vals.get('reg')
    self.imm = int(vals.get('imm'), 16) if vals.get('imm') else int(vals.get('addr'), 16) if vals.get('addr') else None
    self.symbol = vals.get('symbol')
    self.seg = vals.get('seg')
    self.offset = int(vals.get('offset'), 16) if vals.get('offset') else None
    self.base = vals.get('base')
    self.index = vals.get('index')
    self.scale = int(vals.get('scale')) if vals.get('scale') else None
      
    try:
      op = next(filter(lambda x: (x[0] in modes.keys()) and x[1], vals.items()))
    except:
      print(f'Error creating Operand from values: {vals}')
      raise

    self.mode = modes[op[0]]
    self.operand = (vals['pre'] if vals.get('pre') else '') + op[1]
    self.size = next(filter(lambda x: x, map(lambda x: REG_SIZE.get(x, False), (self.reg, self.base, self.index))), None)
    if self.base and self.index:
      assert self.size == REG_SIZE[self.index]

    self.instrumentation = self.mode == MODE_REG and (BASE_REG[self.reg] == 'r14' or (BASE_REG[self.reg] == 'r15' and REG_SIZE.get(self.reg, 1) == 4))

    if self.mode == MODE_MEM:
      if not self.base and not self.index:
        self.addr = hex(self.offset) if self.offset else '0'
      else:
        assert self.size in [4, 8], f'Bad size for addr: (base {self.base} index {self.index} offset {self.offset} size {self.size})'
        exp = []
        if self.offset:
          exp.append(hex(self.offset))
        if self.base:
          exp.append(_reg_exp_r(self.base))
        if self.index:
          exp.append(f'{_reg_exp_r(self.index)} * {self.scale}')
        self.addr = ' + '.join(map(lambda x: icast(x, 4), exp) if self.size == 4 else exp)

  def __str__(self):
    return f'(mode: {self.mode}, instrumentation: {self.instrumentation}, reg:{self.reg}, imm:{self.imm}, symbol:{self.symbol}, seg:{self.seg}, offset:{self.offset}, base:{self.base}, index:{self.index}, scale:{self.scale})'

  def __repr__(self):
    return self.__str__()

  def deref(self, size):
    assert size in [1, 2, 4, 8, 16], f'Bad size in deref call: {size}'
    return f"*reinterpret_cast<{'__' if size==16 else ''}uint{size*8}_t*>({self.addr})"

  def emit_fetch(self, prefix, size, signed=False):
    # TODO: handle segments
    if self.mode == MODE_REG:
      assert size == self.size, f'Bad fetch size: {size} for register {self.reg} size: {self.size}'
      exp = _reg_exp_r(self.reg)
    elif self.mode in (MODE_IMM, MODE_ADDR):
      # This automatically sign-extends all immediates to the target size.
      # Ignore the signed flag.  Immediates in x86 are *always* signed.
      # objdump *shouldn't* emit any negative addresses - so we should
      # be fine treating addresses as immediates.

      exp = hex(self.imm)
    else:
      exp = self.deref(size)
    return self.instr.emit_var_decl(prefix, size, exp, signed=signed)


  #TODO: What if var_name isn't the right size for the dest register?
  def emit_store(self, var_name, size):
    # TODO: handle segments
    assert self.mode not in [MODE_IMM, MODE_ADDR], "Cannot store to an immediate"

    exp = None
    if self.mode == MODE_REG:
      assert size == self.size, f'Bad size in emit_store: {size}'

      if size in (1, 2):
        whole_reg = _reg_exp_l(BASE_REG[self.reg], 8)
        high = self.reg in REG_8H
        bits = "0000" if size == 2 else "00FF" if high else "FF00"
        post = f"(uint16_t) ({var_name} << 8)" if high and size == 1 else f"{whole_reg} += {var_name}"
        self.instr.out += f'{whole_reg} = {whole_reg} & 0xFFFFFFFFFFFF{bits};\n {post}; \n'
        return
      elif size == 4:
        # Only for 32-bit register writes, the top 32-bits get cleared as well.
        exp = _reg_exp_l(self.reg, size=8)
        var_name = icast(icast(var_name, 4), 8)
      else:
        exp = _reg_exp_l(self.reg)
    else: # MODE_MEM
      exp = self.deref(size)
    self.instr.out += f'  {exp} = {var_name};\n'
