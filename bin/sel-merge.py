#!/usr/bin/env python3

import argparse
import sys

pr = argparse.ArgumentParser('Select columns and merge results')
#pr.add_argument('fields', help='range of fields to select (start..end)')
pr.add_argument('field', help='field name to select')
pr.add_argument('files', nargs='+', help='input files')
pr.add_argument('-d', '--delim', default='\t', help='delimiting character')
pr.add_argument('-o', '--output', default='-', help='output file')

argv = pr.parse_args()

field = argv.field
delim = argv.delim
filenames = argv.files
# TODO expose simplify_name
simplify_name = True
outfname = argv.output

# nrows will be determined later
nrows = -1
ncols = len(filenames)

# list of lists
output = []

# select columns from inputs

for fn in filenames:
    with open(fn) as inf:
        header = inf.readline().split(delim)
        try:
            i = header.index(field)
        except:
            sys.stderr.write('Error: field "{}" is not found in {}\n'.format(field, fn))
        else:
            selected = []
            for line in inf:
                tokens = line.rstrip().split(delim)
                selected.append(tokens[i])
            # merge selected column with output
            output.append(selected)
            if nrows == -1:
                nrows = len(selected)
            elif nrows != len(selected):
                sys.stderr.write('Error: {} has {} rows; expected {}\n'.format(
                    fn, len(selected), nrows))

# write output

if outfname == '-':
    outf = sys.stdout
else:
    outf = open(outfname, 'w')

if simplify_name:
    colnames = []
    # simplify name to a substr between '/' and '.'
    for f in filenames:
        i = f.rindex('/')+1
        j = f.index('.', i)
        colnames.append(f[i:j])
else:
    colnames = filenames


# write header
outf.write(delim.join(colnames) + '\n')
# write data
for i in range(nrows):
    for j in range(ncols):
        if j == ncols - 1:
            outf.write(output[j][i])
        else:
            outf.write(output[j][i] + delim)
    outf.write('\n')
outf.close()

