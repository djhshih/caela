#!/usr/bin/env python3

import argparse

pr = argparse.ArgumentParser('To convert class association into CLS format')
pr.add_argument('input', help='input file')
pr.add_argument('gct', help='GCT file')
pr.add_argument('-d', '--delimiter', help='delimiting character', default='\t')
pr.add_argument('-o', '--output', help='output file [default: <original stem>.cls]')
pr.add_argument('-k', '--key', help='key (sample) column index', type=int, default=0)
pr.add_argument('-c', '--cl', help='class column index', type=int, default=1)


argv = pr.parse_args()


cl = {}


levels = {}
nlevels = 0 
# set up class dict
with open(argv.input, 'r') as inf:

	# ignore header line
	inf.readline()

	for line in inf:
		parts = line.rstrip().split(argv.delimiter)
		key = parts[argv.key]
		value = parts[argv.cl]
		cl[ key ] = value
		
		# store level
		if not value in levels:
			levels[ value ] = nlevels
			nlevels += 1


# get the sample order from the GCT file
samples = None
with open(argv.gct, 'r') as gct:
	# ignore the first two lines
	gct.readline()
	gct.readline()

	line = gct.readline().rstrip()
	samples = line.split(argv.delimiter)[2:]


# assign class labels
labels = []
for sample in samples:
	# assume all samples in GCT have known class
	labels.append( levels[cl[sample]] )


# write CLS file
if argv.output:
	output = argv.output
else:
	i = argv.input.rindex('.')
	if i == -1:
		i = len(argv.input)
	output = argv.input[:i] + '.cls'

with open(output, 'w') as outf:
	outf.write( ' '.join( [str(x) for x in [len(samples), nlevels, 1]] ) + '\n' )
	# output class levels in the order of the assigned index
	outf.write('# ' + ' '.join( sorted(levels, key=levels.get) ) + '\n')
	outf.write(' '.join( [str(x) for x in labels] ) + '\n')

