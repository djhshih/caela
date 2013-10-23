#!/usr/bin/env python2

import os, argparse
import numpy as np
import h5py


def get_file_part(fn, index=0):
	return fn.split('.')[index]


pr = argparse.ArgumentParser(description='To convert format of files from text into HDF5')
pr.add_argument('inputs', help='input text files', nargs='+')
pr.add_argument('-o', '--outdir', help='output directory', default='hdf5')
pr.add_argument('-a', '--attributes', help='attribute names (comma separated) for each sample', default='')
pr.add_argument('--noheader', help='input text files do not have headers', action='store_const', dest='header', default=True, const=False)
pr.add_argument('-x', '--outext', help='output file extention', default='hdf5')
pr.add_argument('-t', '--dtype', help='datum type', default='float32')
pr.add_argument('-v', '--verbose', help='verbose output', action='store_const', dest='verbose', default=False, const=True)

argv = pr.parse_args()


attributes = argv.attributes.split(',')

samples = {}


if not os.path.exists(argv.outdir):
	os.makedirs(argv.outdir)

# group files by samples
for x in argv.inputs:
	name = get_file_part(x, 0)
	if name not in samples:
		samples[name] = [x]
	else:
		samples[name].append(x)

# process samples
for name in samples.keys():

	# sort file names
	samples[name].sort()

	f = h5py.File(os.path.join(argv.outdir, '{}.{}'.format(name, argv.outext)), 'w')

	i = 0
	for fn in samples[name]:

		with open(fn, 'r') as inf:

			header = None
			if argv.header:
				header = inf.readline().strip()
			if attributes[0]:
				header = attributes[i]
			if not header:
				header = fn
			i += 1

			# assume one datum for line
			data = np.array( [ float(z) for z in inf ], dtype=argv.dtype )

			f.create_dataset(header, data=data)

	f.close()
	
	if argv.verbose:
		print('Wrote {}.'.format(name))

