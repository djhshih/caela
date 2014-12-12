#!/usr/bin/env python3

import os, argparse

pr = argparse.ArgumentParser('Convert VCF files into input files compatible with EMu')
pr.add_argument('input', help='input vcf file')
pr.add_argument('output', help='output file')

argv = pr.parse_args()

input_fname = argv.input
output_fname = argv.output

base_fname = os.path.basename(input_fname)
sample_name = base_fname[:base_fname.index('.')]

delim = '\t'

def to_chrom(x):
	# strip off 'chr' prefix, if any
	if len(x) > 3 and x[:3] == 'chr':
		x = x[3:]

	# special chromosomes
	if x == 'X': return '23'
	if x == 'Y': return '24'
	#if x == 'MT': return '25'

	# test if x is numeric
	try:
		y = int(x)
		# return x as is
		return x
	except:
		# use '' to denote error
		return ''


with open(input_fname, 'r') as inf, open(output_fname, 'w') as outf:

	# skip header lines
	header = None
	for line in inf:
		if line[:2] == '##':
			continue
		elif line[0] == '#':
			header = line[1:]
			break
	
	# construct column map
	colnames = header.split(delim)
	colmap = { colnames[i]:i for i in range(len(colnames)) }

	# process data
	for line in inf:
		items = line.rstrip().split(delim)

		# ignore indels
		ref = items[colmap['REF']]
		alt = items[colmap['ALT']]
		if len(ref) != 1 or len(alt) != 1:
			continue

		# ignore unknown references
		if ref == 'N':
			continue

		# ignore invalid chromosomes
		chrom = to_chrom(items[colmap['CHROM']])
		if not chrom:
			continue

		# construct output
		out_items = [
			sample_name,
			chrom,
			items[colmap['POS']],
			'>'.join([ref, alt]),
		]
		outf.write(delim.join(out_items) + '\n')
		
