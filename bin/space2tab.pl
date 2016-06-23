#!/usr/bin/perl -w
use strict;
use warnings;

# Convert all spaces to tabs
# Converted files reside in same directory with added .tab suffix
if (scalar(@ARGV) < 1) {
	print "Usage: ./space2tab.pl <indir>\n";
	exit;
}

my $indir = $ARGV[0];
my @files = <$indir/*>;

foreach my $file (@files) {
	open(my $in, $file) or die $!;
	open(my $out, ">$file.tab") or die $!;
	print "Converting $file...\n";
	while (<$in>) {
		s/ /\t/g;
		print $out $_;
	}
	close($in);
	close($out);
}
