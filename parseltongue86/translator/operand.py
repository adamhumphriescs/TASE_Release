import re

MODE_IMM = 0
MODE_REG = 1
MODE_MEM = 2
MODE_ADDR = 3

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

#Array that holds registers assigned during basic block.
#We use this to know which registers to "write back" into
#the register file at the end of a basic block's worth of
#interpretation.
BB_ASSIGNED_REGS = ['rip']

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
  if reg in BB_ASSIGNED_REGS:
    return
  else:
    BB_ASSIGNED_REGS.append(reg)

def clear_bb_reg_refs():
  BB_ASSIGNED_REGS.clear()
  add_bb_reg_ref('rip')

def tmp_reg_name(reg):
  if reg in REG_64:
    return  reg + '_tmp'
  else:
    assert False, f'Error: called tmp_reg_name on reg {reg}'
    
def base_reg(reg):
  for rlist in [REG_64, REG_32, REG_16, REG_8L, REG_8H]:
    if reg in rlist:
      return REG_64[rlist.index(reg)]
  return None


def scast(exp, size):
  return icast(exp, size, True)


def ucast(exp, size):
  return icast(exp, size, False)


def icast(exp, size, signed):
  assert size in [1, 2, 4, 8, 16]
  if signed:
    itype = 'int'
  else:
    itype = 'uint'
  if size == 16:
    itype = '__' + itype
  return f'static_cast<{itype}{size*8}_t>({exp})'


def reg_size(reg):
  if reg in REG_64:
    return 8
  elif reg in REG_32:
    return 4
  elif reg in REG_16:
    return 2
  else:
    return 1


def _reg_exp_r(reg, size=None):
  """
  rvalue expression for register.  Takes an objdump style register
  name "%rax" and produces an rvalue.
  """
  reg_name = base_reg(reg)
  if not size:
    size = reg_size(reg)
  if reg in REG_8H:
    return f'(uint8_t) ({tmp_reg_name(reg_name)} >> 8)'
  else:
    cast_str = f'(uint{size*8}_t) '
    return cast_str + tmp_reg_name(reg_name)

def _reg_exp_l(reg, size=None):
  """
  lvalue expression for register.  Takes an objdump style register 
  name "%rax" and produces an lvalue.
  Throws an error if size is not 8 bytes, since we've switched
  to using temp vars (e.g., tmp_rax) instead of pointer expressions.
  """
  reg_name = base_reg(reg)
  add_bb_reg_ref(reg_name)
  if not size:
    size = reg_size(reg)
  if not (size == 8):
    assert False, f'Error: Invalid size {size} passed to reg_exp_l'
  return tmp_reg_name(reg_name)
  

  
def _reg_exp(reg, size=None):
  """
  Encapsulates all our accesses to the C++ register file structure.
  Takes an objdump style register name "%rax" and produces an
  lvalue (which in our case also trivially converts to an rvalue).
  """
  reg_name = base_reg(reg).upper()
  #Special case
  if reg_name == 'RIP':
    return 'rip_tmp'
  
  if not size:
    size = reg_size(reg)
  cast_str = f'reinterpret_cast<uint{size*8}_t*>(gregs + GREG_{reg_name})'
  # Stupid unaligned access case.
  if reg in REG_8H:
    return f'({cast_str})[1]'
  else:
    return '*' + cast_str


def reg_operand(instr, base_reg, size):
  idx = REG_64.index(base_reg)
  reg = '%' + REG_SIZE_MAP[size][idx]
  return Operand(instr, reg)

class Operand:

  _regex_operand = re.compile(
      r'%(?P<reg>\w+)(?=,|$)|'
      r'(?P<addr>[0-9a-f]+)\s+<(?P<symbol>\S+)>|'
      r'\$(?P<imm>(0x)?[0-9a-f]+)|'
      r'(%(?P<seg>\w+):)?'
      r'(?P<offset>-?(0x)?[0-9a-f]+)?'
      r'(\((%(?P<base>\w+))?(,%(?P<index>\w+)(,(?P<scale>[1248]))?)?\))?')

  def __init__(self, instr, all_operands):
    """
    instr:         Instruction  the parent this operand is tied to.
    all_operands:  str          one or more unparsed operands (AT&T syntax).
    """
    self.instr = instr
    self.mode = None
    self.reg = None
    self.imm = None
    self.symbol = None
    self.seg = None
    self.offset = 0
    self.base = None
    self.index = None
    self.scale = 1
    self.operand = None

    assert all_operands
    self._parse_operand(all_operands)

  def _parse_operand(self, all_operands):
    # We don't need any special hint about a dereference for jmp/call
    if all_operands[0] == '*':
      prefix = '*'
      all_operands = all_operands[1:]
    else:
      prefix = ''

    match = self._regex_operand.match(all_operands)
    assert match, f'Unknown operand format {all_operands}'
    self.operand = prefix + match.group(0)

    if match.group('reg'):
      self.mode = MODE_REG
      self.reg = match.group('reg')
    elif match.group('addr'):
      # Consider jump addresses immediates as well.
      self.mode = MODE_ADDR
      # For ease of use, set imm to the numeric value of the address.
      self.imm = int(match.group('addr'), 16)
      self.symbol = match.group('symbol')
    elif match.group('imm'):
      self.mode = MODE_IMM
      # Immediates are signed (imm8, imm16, imm32 and imm64).
      # Cast them to appropriate unsigned values only when needed.
      self.imm = int(match.group('imm'), 16)
    elif match.group('offset') or match.group('base'):
      self.mode = MODE_MEM
      self.seg = match.group('seg')
      if match.group('offset'):
        self.offset = int(match.group('offset'), 16)
      self.base = match.group('base')
      self.index = match.group('index')
      if match.group('scale'):
        self.scale = int(match.group('scale'))
    else:
      assert False, f'Unknown operand format {all_operands}'

  def addr(self):
    if self.base and self.index:
      size = reg_size(self.base)
      assert size == reg_size(self.index)
    elif self.base:
      size = reg_size(self.base)
    elif self.index:
      size = reg_size(self.index)
    else:
      size = 8

    assert size in [4, 8]
    if size == 4:
      addr_str = ucast('%s', 4)
    else:
      addr_str = '%s'

    exp = []
    if self.offset:
      exp.append(addr_str % hex(self.offset))
    if self.base:
      exp.append(addr_str % _reg_exp_r(self.base))
    if self.index:
      exp.append((addr_str % _reg_exp_r(self.index)) + ' * ' + str(self.scale))

    if not exp:
      # An address with no elements can be reached if we had statements
      # explicitly loading from address 0x0. It's weird - but we can support it.
      exp.append('0')

    return ' + '.join(exp)

  def is_instrumentation(self):
    return self.uses_r14() or self.uses_r15d()
  
  def uses_r14(self):
    return self.mode == MODE_REG and base_reg(self.reg) in ['r14']

  def uses_r15d(self):
    return self.mode == MODE_REG and base_reg(self.reg) in ['r15'] and reg_size(self.reg) == 4
  
  def deref(self, size):
    assert size in [1, 2, 4, 8, 16]
    return f"*reinterpret_cast<{'__' if size==16 else ''}uint{size*8}_t*>({self.addr()})"

  def emit_fetch(self, prefix, size, signed=False):
    # TODO: handle segments
    if self.mode == MODE_REG:
      assert size == reg_size(self.reg)
      exp = _reg_exp_r(self.reg)
    elif self.mode in [MODE_IMM, MODE_ADDR]:
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
    if self.mode == MODE_REG:
      assert size == reg_size(self.reg)
      whole_reg = _reg_exp_l(base_reg(self.reg), 8)
      if   size ==1:
        if self.reg in REG_8H:
          #High byte case
          self.instr.out += f'{whole_reg} = {whole_reg} & 0xFFFFFFFFFFFF00FF;\n'
          self.instr.out += f'{whole_reg} += (uint16_t) ({var_name} << 8); \n'
          return
        else:
          self.instr.out += f'{whole_reg} = {whole_reg} & 0xFFFFFFFFFFFFFF00;\n'
          self.instr.out += f'{whole_reg} += {var_name}; \n'
          return
      elif   size == 2:
        #drop bottom two bytes
        self.instr.out += f' {whole_reg} = {whole_reg} & 0xFFFFFFFFFFFF0000;\n'
        #add in two bytes.  Should we OR these in instead?
        self.instr.out += f' {whole_reg} = {whole_reg} + {var_name}; \n'
        return
      # Only for 32-bit register writes, the top 32-bits get cleared as well.
      elif size == 4:
        # Only for 32-bit register writes, the top 32-bits get cleared as well.
        exp = _reg_exp_l(self.reg, size=8)
        var_name = ucast(ucast(var_name, 4), 8)
      else:
        exp = _reg_exp_l(self.reg)
    else:
      exp = self.deref(size)
    self.instr.out += '  {exp} = {var_name};\n'
