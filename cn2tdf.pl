#!/usr/bin/perl -w
use strict;
use warnings;

if (scalar(@ARGV) < 2) {
	print "Usage: ./cn2tdf <indir> <outdir>\n";
	exit;
}

my $indir = $ARGV[0] or die ("Error: indir missing");
my $outdir = $ARGV[1] or die("Error: outdir missing");
my $genome; $genome = $ARGV[2] or $genome = "hg18";

mkdir $outdir;

my @files = <$indir/*>;
foreach my $file (@files) {
	my $fstem = substr($file, rindex($file, '/')+1);
	my $outfile = "$outdir/$fstem.tdf";
	if (! -e $outfile) {
		(system("igvtools", "tile", $file, $outfile, $genome) == 0) or die $!;
	}
}
