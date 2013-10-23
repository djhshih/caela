#!/usr/bin/env python2

import os, argparse
import h5py


def rm_file_ext(fn):
	i = fn.rfind('.')
	if i == -1:
		return fn
	else:
		return fn[:i]


def main():

	pr = argparse.ArgumentParser(description='To convert format of files from delimited format into HDF5')
	pr.add_argument('inputs', help='input text files', nargs='+')
	pr.add_argument('-o', '--outdir', help='output directory', default='hdf5')
	pr.add_argument('-a', '--attributes', help='attribute names (comma separated) for each sample', default='')
	pr.add_argument('--noheader', help='input text files do not have headers', action='store_const', dest='header', default=True, const=False)
	pr.add_argument('-x', '--outext', help='output file extention', default='hdf5')
	pr.add_argument('-t', '--dtypes', help='datum type', default='float32')
	pr.add_argument('-d', '--delimiter', help='delimiting character', default='\t')
	pr.add_argument('-v', '--verbose', help='verbose output', action='store_const', dest='verbose', default=False, const=True)

	argv = pr.parse_args()

	dtypes = argv.dtypes.split(',')
	attributes = argv.attributes.split(',')
	if attributes == ['']:
		attributes = None

	samples = {}

	if not os.path.exists(argv.outdir):
		os.makedirs(argv.outdir)

	# process samples
	for name in argv.inputs:

		f = h5py.File(os.path.join(argv.outdir, '{}.{}'.format(rm_file_ext(name), argv.outext)), 'w')

		with open(name, 'r') as inf:

			# determine the number of attributes from the first row
			nelems = len(inf.readline().strip().split(argv.delimiter))
			# rewind
			inf.seek(0)

			headers = None
			if argv.header:
				headers = inf.readline().strip().split(argv.delimiter)
			else:
				headers = range(nelems)

			if attributes:
				if len(attributes) != nelems:
					raise ValueError('Number of attributes should equal to the number of columns in the input data tables')
				headers = attributes

			if len(dtypes) == 1:
				# expand dtypes list, assume all data types are the same
				dtypes = dtypes * nelems

			# set up table
			data = []
			for i in range(nelems):
				data.append([])
			
			# read in table
			for line in inf:
				items = line.split('\t')
				for i in range(nelems):
					if dtypes[i][:3] == 'int':
						item = int(items[i])
					elif dtypes[i][:5] == 'float':
						item = float(items[i])
					else:
						item = items[i].encode()
					data[i].append(item)

			# write table
			for i in range(nelems):
				f.create_dataset(headers[i], data=data[i], dtype=dtypes[i])

		f.close()
		
		if argv.verbose:
			print('Wrote {}.'.format(name))


if __name__ == '__main__':
	main()

