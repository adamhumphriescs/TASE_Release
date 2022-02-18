import logging
import operator
import sys
from translator import elffile
from argparse import ArgumentParser

def main(args):
  logging.basicConfig(level=logging.INFO)


  # Required argument 1 - path to binary to analyze
  target_binary = args['target_binary']
  # Optional argument 2 - path to archive/library file with symbols that we want to extract.
  # If this is not provided, a ".a" file at the target binary's location is chosen.
  filter_file = args['filter_file'] if args['filter_file'] else target_binary + '.a'

  filter_elf = elffile.ELFFile(filter_file)
  bin_elf = elffile.ELFFile(target_binary)

  extents = []

  # TODO: Ensure experiment integrity by logging time of run and
  # md5/size/time-of-modification of input binaries.
  for name in filter_elf.vars_loc():
    if name in bin_elf.vars_loc():
      for addr, size in bin_elf.vars_loc()[name]:
        logging.info(f'{name} : {hex(addr)} + {size}')
        assert size
        extents.append((addr, size))

  for addr, size in sorted(extents, key=operator.itemgetter(0)):
    print('{hex(addr)} {hex(size)}')

parser = ArgumentParser()
parser.add_argument('target_binary')
parser.add_argument('-f,--filter_file', dest='filter_file', type=str, help='filter file')
if __name__ == '__main__':
  main(vars(parser.parse_args()))
