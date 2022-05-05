
import re
from .instruction import Instruction
from typing import Optional

MODE_IMM: int
MODE_REG: int
MODE_MEM: int
MODE_ADDR: int
modes: dict[str, int]
REG_64: list[str]
REG_32: list[str]
REG_16: list[str]
REG_8L: list[str]
REG_8H: list[str]
REG_SIZE_MAP: dict[int, list[str]]
BASE_REG: dict[str, str]
REG_SIZE: dict[str, int]
BB_ASSIGNED_REGS: set[str]
FLAG_BITS: int
FLAG_CF: int
FLAG_PF: int
FLAG_ZF: int
FLAG_SF: int
FLAG_DF: int
FLAG_OF: int


def add_bb_reg_ref(reg: str) -> None: ...

def clear_bb_reg_refs() -> None : ...

def icast(exp: str, size: int, signed: bool) -> str: ...

def _reg_exp_r(reg: str, size: Optional[int]) -> str: ...

def _reg_exp_l(reg: str, size: Optional[int]) -> str: ...

def _reg_exp(reg: str, size: Optional[int]) -> str: ...

def reg_operand(instr: Instruction, base_reg: str, size: int) -> Operand: ...

class Operand:
    instr: Instruction
    mode: Optional[int]
    reg: Optional[str]
    imm: Optional[int]
    symbol: Optional[str]
    seg: Optional[str]
    offset: Optional[int]
    base: Optional[str]
    index: Optional[str]
    Scale: Optional[int]
    op: str
    operand: str
    size: int
    instrumentation: bool
    addr: str

    def __init__(self, instr: Instruction, vals: dict[str, str]) -> None: ...

    def __str__(self) -> str: ...

    def __repr__(self) -> str: ...

    def deref(self, size:int) -> str: ...

    def emit_fetch(self, prefix: str, size: int, signed: bool) -> str: ...

    def emit_store(self, var_name: str, size: int) -> str: ...
