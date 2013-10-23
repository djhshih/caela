#!/usr/bin/env python3

import os, argparse

def numeric(chrom):
	if chrom == 'X':
		return '23'
	if chrom == 'Y':
		return '24'
	if chrom == 'MT':
		return '25'

	try:
		chromi = int(chrom)
	except:
		raise Exception('Unknown chromosome name')

	return str(chromi)


def chromname(chrom):
	chrom = standard(chrom)
	return 'chr{}'.format(chrom)


def standard(chrom):
	if chrom == '23':
		return 'X'
	if chrom == '24':
		return 'Y'
	if chrom == '25':
		return 'MT'
	
	try:
		t = int(chrom)
	except:
		raise Exception('Unknown chromosome name: {}'.format(chrom))

	return chrom

pr = argparse.ArgumentParser(description='Convert chromosome names of non-autosomes in a delimited table (e.g. SEG file)')
pr.add_argument('input', help='input file')
pr.add_argument('output', help='output file')
pr.add_argument('--delimiter', help='delimiting character for fields', default='\t')
pr.add_argument('--chromosome', help='0-index of chromosome field', default=1)
pr.add_argument('--standard', help='convert to standard chromosome id (e.g. X)', dest='convert', action='store_const', const=standard, default=standard)
pr.add_argument('--numeric', help='convert to chromosome number (e.g. 23)', dest='convert', action='store_const', const=numeric)
pr.add_argument('--chromname', help='convert to chromosome name (e.g. chrX)', dest='convert', action='store_const', const=chromname)

argv = pr.parse_args()

with open(argv.input, 'r') as inputf, open(argv.output, 'w') as outputf:
	# copy header line
	outputf.write(inputf.readline())
	for line in inputf:
		fields = line.rstrip().split(argv.delimiter)
		fields[argv.chromosome] = argv.convert(fields[argv.chromosome])
		outputf.write( argv.delimiter.join(fields) + '\n' )

