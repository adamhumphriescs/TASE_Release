from setuptools import setup

from mypyc.build import mypycify

setup(
    name='translator',
    packages=['translator'],
    ext_modules=mypycify([
        'translator/__init__.py',
        'translator/elffile.py',
        'translator/instruction.py',
        'translator/operand.py',
    ]),
)
