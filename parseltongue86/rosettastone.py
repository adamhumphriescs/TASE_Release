import logging
import operator
import sys
from translator import elffile


def main():
  logging.basicConfig(level=logging.INFO)
  assert(len(sys.argv) > 1)

  # Required argument 1 - path to binary to analyze
  target_binary = sys.argv[1]
  # Optional argument 2 - path to archive/library file with symbols that we want to extract.
  # If this is not provided, a ".a" file at the target binary's location is chosen.
  filter_file = sys.argv[2] if len(sys.argv) > 2 else target_binary + '.a'

  filter_elf = elffile.ELFFile(sys.stderr, filter_file)
  bin_elf = elffile.ELFFile(sys.stderr, target_binary)

  extents = []

  # TODO: Ensure experiment integrity by logging time of run and
  # md5/size/time-of-modification of input binaries.
  for name in filter_elf.vars_loc():
    if name in bin_elf.vars_loc():
      for addr, size in bin_elf.vars_loc()[name]:
        logging.info('%s : %s + %d', name, hex(addr), size)
        assert size
        extents.append((addr, size))

  for addr, size in sorted(extents, key=operator.itemgetter(0)):
    print('%s %s' % (hex(addr), hex(size)))


if __name__ == '__main__':
  sys.exit(main())
