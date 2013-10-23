#!/usr/bin/python

# Author:   David J. H. Shih
# Date:     2011-08-04
# License:  GPLv3 

import argparse, math

def mean(x):
	if (len(x)):
		return sum(x)/len(x)
	else:
		return float('NaN')

## Command line optiosn

parser = argparse.ArgumentParser(
	description =
		'Convert Affymetrix Annotation CSV file for CN probes into a tab-delimited'
)

parser.add_argument('input', help='input csv file')
parser.add_argument('output', help='output file')
parser.add_argument('--mean', dest='combine', action='store_const', const=mean, default=min)
parser.add_argument('--max', dest='combine', action='store_const', const=max)
parser.add_argument('--min', dest='combine', action='store_const', const=min)
parser.add_argument('--floor', dest='round', action='store_const', const=math.floor, default=round)
parser.add_argument('--ceil', dest='round', action='store_const', const=math.ceil)

args = parser.parse_args()


## Constants

(col_name, col_chr, col_start, col_end) = (0, 1, 2, 3)
delim_in = ','
delim_out = '\t'
nskippedlines = 1


## Process

inputf = open(args.input)
outputf = open(args.output, 'w')

i = 0
for line in inputf:

	i += 1

	if line[0] == '#':
		continue

	if i <= nskippedlines:
		continue

	# strip line and remove quote characters, assuming that delimiter is sufficient for splitting
	line = line.strip().replace('"', '')
	t = line.split(delim_in)

	# calculate the position of the marker
	try:
		pos = str(args.round(args.combine( (int(t[col_start]), int(t[col_end])) )))
	except Exception as e:
		print('ERROR: ' + str(e) + ', at line ' + str(i) + ':')
		print(line + '\n')
		continue

	# write to output
	line_out = delim_out.join( (t[col_name], t[col_chr], pos) )
	outputf.write(line_out + '\n')


inputf.close()
outputf.close()

