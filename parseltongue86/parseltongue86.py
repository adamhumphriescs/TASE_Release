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


def main(args):
  filters = []
  logging.basicConfig(level=logging.INFO)

  try:
    include_path = (Path(args['tase_include_dir']) / 'tase_interp_alt.h').resolve(strict=True)
    target_binary = Path(args['target_binary']).resolve(strict=True)

    if args['functions_file']:
      with open(Path(args['functions_file']).resolve(strict=True), 'r') as f:
        filters = [l.strip() for l in f.readlines()]
    else:
      logging.error('No functions file found - falling back to disassembling all functions')
      filters = None


  logging.info(f'{target_binary} md5sum: {md5sum(target_binary)}')

  # These are TASE functions that we need the address for but don't want to process
  # IR for normally.
  springboard_functions = set(['sb_open', 'sb_modeled_return'])
  if filters is not None:
    filters.extend(springboard_functions)

  with open('cartridge_info.txt') as c:
    cartridge_pairs = {int(head) : (int(head), int(tail)) for head, tail in (line.split() for line in c)}

  with Pool(args['threads']) as pool:
    p = elffile.ELFFile(target_binary, include_path=include_path, cartridge_pairs=cartridge_pairs, filter_functions=filters, springboard_functions=springboard_functions)
    p.fasm(args['outname'], pool=pool)


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
