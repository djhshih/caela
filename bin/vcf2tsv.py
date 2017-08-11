#!/usr/bin/env python3

import argparse

pr = argparse.ArgumentParser(description="Convert single-sample VCF file to TSV file")
pr.add_argument("input", help = "input VCF file")
pr.add_argument("output", help = "output TSV file")

argv = pr.parse_args()

in_fn = argv.input
out_fn = argv.output
info_cidx = 7 
info_fields = []
col_names = []


def get_key_values(pairs, keys):
    values = [None] * len(keys)
    for pair in pairs:
        # find first key that match
        for i, key in enumerate(keys):
            if pair[:len(key)] == key:
                # extract value
                if len(pair) > len(key):
                    values[i] = pair[(len(key)+1):]
                else:
                    # pair actually just a key flag with no value
                    values[i] = 'T'
                break
    return values


outf = open(out_fn, 'w')

with open(in_fn) as inf:

    for line in inf:
        if line[0:2] == "##":
            # copy meta data verbatim
            outf.write(line)
                
            # parse info meta data
            if line[0:11] == "##INFO=<ID=":
                start = 11
                end = line.find(',', 11)
                if not end == -1:
                    info_fields.append(line[start:end])

        elif line[0] == "#":
            tokens = line[1:].rstrip().split('\t')

            # meta data should have been parsed now:
            # contruct new column names
            col_names = [x.lower() for x in tokens[:info_cidx]]
            col_names.extend([x.lower() for x in info_fields])
            if len(tokens) > info_cidx+1:
                col_names.extend(tokens[(info_cidx+1):])

            outf.write('\t'.join(col_names) + '\n')
        else:
            # parse line
            tokens = line.rstrip().split('\t')
            # parse info field
            info_pairs = tokens[info_cidx].split(';')
            info_values = [
                str(x) if x is not None else 'F'
                for x in get_key_values(info_pairs, info_fields)
            ]

            out = tokens[:info_cidx] + info_values
            if len(tokens) > info_cidx+1:
                out.extend(tokens[(info_cidx+1):])

            outf.write('\t'.join(out) + '\n')


outf.close()

