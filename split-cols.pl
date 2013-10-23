#!/usr/bin/perl -w
use strict;
use warnings;

my $delimiter = '\t';
my $infilename = $ARGV[0];

open(my $infile, $infilename) or die "Error: could not open input file $infilename";

# read first line
my $line = <$infile>;
my @headers = split($delimiter, $line);
my $ncols = scalar(@headers);

my $outdir = "$infilename.d";
mkdir $outdir;

printf "Creating output files...\n";

my @outfilenames;
for (my $i = 0; $i < $ncols; ++$i) {
	# open one output file at a time
	my $outfilename = "$ARGV[0].$i";
	push(@outfilenames, $outfilename);
	open(my $outfile, ">$outdir/$outfilenames[$i]") or die "Error: could not open output file $outfilenames[$i]";
	# print header
	print $outfile "$headers[$i]\n";
	close($outfile);
}

printf("Processing...\n");

my $k = 0;
while (<$infile>) {
	#print "Processing row $k\n";
	my $line = $_;
	chomp $line;
	my @elems = split($delimiter, $line);
	for (my $i = 0; $i < scalar(@elems); ++$i) {
		# re-open output file for appending data
		open(my $outfile, ">>$outdir/$outfilenames[$i]") or die "Error: could not open output file $outfilenames[$i]";
		print $outfile "$elems[$i]\n";
		close($outfile);
	}
	++$k;
}


close($infile);

print "Input file $infilename was split into $ncols files and stored in $outdir.\n";