#!/usr/bin/env python3

import argparse, os, re

def filename_split(name):
	i = name.rfind('.')
	if i != -1:
		return (name[:i], name[i:])
	return (name, '')

pr = argparse.ArgumentParser('Create symbolic links as specified by mapping')
pr.add_argument('map', help='input mapping file')
pr.add_argument('-i', '--indir', help='root input directory', default='.')
pr.add_argument('-o', '--outdir', help='root output directory', default='.')
pr.add_argument('-r', '--regex', help='regular expression pattern', default='.*')
pr.add_argument('-d', '--delim', help='delimiting character', default='\t')
pr.add_argument('-v', '--verbose', help='verbose output', action='store_const', dest='verbose', const=True, default=False)
pr.add_argument('-n', '--dryrun', help='dry run', action='store_const', dest='dryrun', const=True, default=False)
pr.add_argument('--src', help='column index of source identifier', default=0, type=int)
pr.add_argument('--dest', help='column index of destination identifier', default=1, type=int)

argv = pr.parse_args()

if argv.dryrun:
	argv.verbose = True

# create mapping
mapping = {}
with open(argv.map, 'r') as mapf:
	for line in mapf:
		items = line.strip().split(argv.delim)
		mapping[ items[argv.src].strip() ] = items[argv.dest].strip()

# create output directory
if not os.path.exists(argv.outdir):
	os.makedirs(argv.outdir)


files = os.listdir(argv.indir)

m = re.compile(argv.regex)

for f in files:

	if m.match(f):

		fstem, fext = filename_split(f)
		if fstem in mapping.keys():

			if argv.verbose:
				print('{} -> {}'.format(fstem + fext, mapping[fstem] + fext))

			if not argv.dryrun:
				os.symlink(
						os.path.join(argv.indir, f),
						os.path.join(argv.outdir, mapping[fstem] + fext),
				)

