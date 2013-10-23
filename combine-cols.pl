#!/usr/bin/perl -w
use strict;
use warnings;

die "Usage: combine-cols.pl <indir> <outfile>" if (scalar(@ARGV) < 2);

my $indir  = shift;
my $outfilename = shift;
my $delimiter;
$delimiter = shift or $delimiter = '\t';


open(my $outfile, ">$outfilename");

my @infilenames = glob "$indir/*";
my @infiles;
foreach my $infilename (@infilenames) {
	open(my $infile, $infilename) or die "Error: could not open input file $infilename";
	push(@infiles, $infile);
}
my $ninfiles = scalar(@infiles);

while (1) {
	my $outline = "";
	foreach my $infile (@infiles) {
			my $line = <$infile>;
			if ($line) {
				chomp($line);
				if ($outline) {
					$outline .= "\t$line";
				} else {
					$outline = $line;
				}
			}
	}
	last if (!$outline);
	print $outfile "$outline\n";
}

foreach my $infile (@infiles) {
	close($infile);
}

print "Input files ($ninfiles) in $indir combined and stored in $outfilename.\n";
