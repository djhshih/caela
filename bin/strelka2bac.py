#!/usr/bin/env python3

import os, argparse

pr = argparse.ArgumentParser('Convert strelka VCF files into B alleles count file (PBACG)')
pr.add_argument('input', help='input strelka vcf file')
pr.add_argument('output', help='output file')

argv = pr.parse_args()

input_fname = argv.input
output_fname = argv.output

base_fname = os.path.basename(input_fname)
sample_name = base_fname[:base_fname.index('.')]

delim = '\t'

nucleotides_map = {'A': 0, 'C': 1, 'G': 2, 'T': 3}


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
	colnames = header.rstrip().split(delim)
	colmap = { colnames[i]:i for i in range(len(colnames)) }

	outf.write(delim.join(['#chromosome', 'position', 'depth', 'alt_count', 'ref', 'alt']) + '\n')

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
		
		# extract read count information from the TUMOR field
		tumour = items[colmap['TUMOR']].split(':')

		# format: DP:FDP:SDP:SUBDP:AU:CU:GU:TU
		##FORMAT=<ID=AU,Number=2,Type=Integer,Description="Number of 'A' alleles used in tiers 1,2">
		##FORMAT=<ID=CU,Number=2,Type=Integer,Description="Number of 'C' alleles used in tiers 1,2">
		##FORMAT=<ID=GU,Number=2,Type=Integer,Description="Number of 'G' alleles used in tiers 1,2">
		##FORMAT=<ID=TU,Number=2,Type=Integer,Description="Number of 'T' alleles used in tiers 1,2">

		# extract data for tier1
		counts = [int(x.split(',')[0]) for x in tumour[4:]]
		# counts: A C G T
		depth = sum(counts)
		alt_count = counts[nucleotides_map[alt]]

		# ignore invalid counts
		if not counts:
			continue

		# construct output
		out_items = [
			chrom,
			items[colmap['POS']],
			str(depth),
			str(alt_count),
			ref,
			alt,
		]
		outf.write(delim.join(out_items) + '\n')
		
