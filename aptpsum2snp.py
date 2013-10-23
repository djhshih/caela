#!/usr/bin/env python2

import argparse, os
import numpy as np
import h5py


class SnpParser:

	def __init__(self, header, delim, keep_ext, blocksize, file_pattern, marker_file, labels):

		self.delim = delim
		self.blocksize = blocksize
		self.file_pattern = file_pattern
		self.marker_file = marker_file
		self.labels = labels
		self.nsignals = len(labels)
		self.marker_idx = 0
		self.signal_idx = 0
		self.nmarkers = 0
		self.data = []
		# data[sample][signal][marker]


		items = header.lstrip().split(delim)
		# all elements after the first are sample names
		if keep_ext:
			self.samples = items[1:]
		else:
			# remove file extension from sample name
			self.samples = [x[:x.rfind('.')] for x in items[1:]]

		self.nsamples = len(self.samples)

		for j in range(self.nsamples):

			# setup data list of list of arrays
			signals = []
			for k in range(self.nsignals):
				signals.append( np.zeros((blocksize,), 'float32') )
			self.data.append(signals)


			# set up extendable datatsets
			fn = file_pattern.format( self.samples[j] )
			with h5py.File(fn, 'w') as f:
				for k in range(self.nsignals):
					f.create_dataset(labels[k], (0,), maxshape=(None,), dtype='float32')
					
		# setup markers list
		self.markers = [b''] * blocksize

		# set up extendable datatsets
		with h5py.File(marker_file, 'w') as f:
			f.create_dataset('marker', (0,), maxshape=(None,), dtype='S15')


	def parse(self, line):

		if self.marker_idx >= self.blocksize:
			# buffer is full: flush the data into files before proceeding
			self.output()

		items = line.lstrip().split(self.delim)

		# first element is the marker name
		# remove last two characters
		# convert characters to bytes
		marker = items[0][:-2].encode()

		signal_idx = self.signal_idx
		marker_idx = self.marker_idx

		if signal_idx == 0:
			# add marker
			self.markers[marker_idx] = marker
		else:
			# check that marker name agrees with current entry
			if self.markers[marker_idx] != marker:
				raise ValueError('The same markers should be grouped together ({} != {})'.format(self.markers[marker_idx], marker))
		# TODO check that the labels matche the defined labels

		# copy the data
		for j in range(len(items)-1):
			self.data[j][signal_idx][marker_idx] = float(items[j+1])

		# increment indices
		self.signal_idx += 1
		if self.signal_idx >= self.nsignals:
			self.signal_idx = 0
			self.marker_idx += 1
			self.nmarkers += 1


	def output(self):

		curr_blocksize = self.marker_idx
		self.marker_idx = 0

		for j in range(self.nsamples):
			fn = self.file_pattern.format( self.samples[j] )

			with h5py.File(fn, 'a') as f:
				for k in range(self.nsignals):
					d = f[self.labels[k]]
					# extend dataset
					n = d.shape[0]
					n2 = n + curr_blocksize
					d.resize( (n2, ) )
					# copy data block
					d[n:n2] = self.data[j][k][:curr_blocksize]

		with h5py.File(self.marker_file, 'a') as f:
			d = f['marker']
			# extend the dataset
			n = d.shape[0]
			n2 = n + curr_blocksize
			d.resize( (n2, ) )
			# copy data block
			d[n:n2] = self.markers[:curr_blocksize]


def main():

	pr = argparse.ArgumentParser(description='Convert Affymetrix Power Tools probeset summary output to individual SNP files')
	pr.add_argument('input', help='summary output of apt-probeset-summarize')
	pr.add_argument('-o', '--outdir', help='output root directory', default='.')
	pr.add_argument('--datadir', help='output data directory', default='data')
	pr.add_argument('-t', '--outtype', help='output file type', default='hdf5')
	pr.add_argument('--markerfile', help='output SNP marker annotation file name', default='markers')
	pr.add_argument('-x', '--dataext', help='output data file extension prefix', default='snp')
	pr.add_argument('-b', '--blocksize', help='number of SNP markers to process in one block', type=int, default=100000)
	pr.add_argument('-d', '--delimiter', help='delimiting character in input file', default='\t')
	pr.add_argument('-l', '--signal_labels', help='signal labels', default='A,B')
	pr.add_argument('--keep_ext', help='keep file extension in sample name', action='store_const', dest='keep_ext', default=False, const=True)
	pr.add_argument('-v', '--verbose', help='verbose output', action='store_const', dest='verbose', const=True, default=False)

	argv = pr.parse_args()

	progress_interval = 100000

	if argv.blocksize < 2:
		raise ValueError('Block size must be at least 2')

	labels = argv.signal_labels.split(',')
	nsignals = len(labels)

	# ensure blocksize is divisible by the nubmer of signal types
	if argv.blocksize % nsignals != 0:
		argv.blocksize -= (argv.blocksize % nsignals)

	datadir = os.path.join(argv.outdir, argv.datadir)
	if not os.path.exists(datadir):
		os.makedirs(datadir)

	output_file_pattern = os.path.join(datadir, '{}.' + argv.dataext + '.' + argv.outtype)
	marker_file = os.path.join(argv.outdir, '{}.{}.{}'.format(argv.markerfile, argv.dataext, argv.outtype))


	with open(argv.input, 'r') as inf:


		for line in inf:

			# ignore comment lines
			if line[0] == '#':
				continue

			# first non-comment line is the header line
			parser = SnpParser(line, argv.delimiter, argv.keep_ext, argv.blocksize, output_file_pattern, marker_file, labels)
			break
		
		i = 0

		for line in inf:

			# only use SNP markers
			if line[:3] == 'SNP':
				parser.parse(line)
				i += 1
				if argv.verbose and i % progress_interval == 0:
					print('Processed {} lines...'.format(i))

	# flush buffer
	parser.output()

	if argv.verbose:
		print('Done.\nProcessed {} SNP markers.'.format(parser.nmarkers))


if __name__ == '__main__':
	main()

