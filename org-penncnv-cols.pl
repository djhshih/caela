#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;

# Organize column files split from a CN file
# Rename column files to either annotation labels, or sample names and types

my $rootpath = shift or die("Argument missing: root directory\n");

my $stem;
if ("./$rootpath" =~ m|.*/([^/]+)\.d$|) {
	$stem = $1;
} else {
	die("Error while deriving stem from root path: $rootpath");
}

my $datasubpath = "data";
my $datapath = "$rootpath/$datasubpath";

my $suffixrex = "cn";

my $lrrstr = "Log R Ratio";
my $bafstr = "B Allele Freq";

my $outext = "txt";
my $lrrext = "lrr.txt";
my $bafext = "baf.txt";

my $dryrun = shift;

my %annotcols = (
	markers => 0,
	chromosomes => 1,
	positions => 2,
);

my $samplefilename = "samples.$outext";

mkdir $datapath if (!$dryrun);

opendir(my $rootdir, $rootpath) or die("Error: cannot open $rootpath");
# Retrieve file names without preceding path
my @filenames = grep {/\.($suffixrex)\.\d+$/} readdir($rootdir);

closedir($rootdir);

my %samples = ();

foreach my $filename (@filenames) {
	my $fullfilepath = "$rootpath/$filename";
	my $isNotAnnot = 1;
	for my $key (keys %annotcols) {
		my $value = $annotcols{$key};
		if ($filename eq "$stem.$value") {
			# file stores an annotation column
			print("$filename -> $key.$outext\n");
			move($fullfilepath, "$rootpath/$key.txt") if (!$dryrun);
			$isNotAnnot = 0;
			last;
		}
	}
	if ($isNotAnnot) {
		# peek the first line of file to determine sample name and data type
		open(my $file, $fullfilepath);
		my $line = <$file>;
		close($file);
		chomp($line);
		my @tokens = split(/\./, $line);
		# assume the first token is the sample name, and the last the sample type
		my $sample = $tokens[0];
		my $type = $tokens[$#tokens];
		my $newfilename;
		if ($type eq $lrrstr) {
			$newfilename = "$sample.$lrrext";
		} elsif ($type eq $bafstr) {
			$newfilename = "$sample.$bafext";
		} else {
			die("Invalid type: $type in file $filename (line: $line)\n");
		}
		# register sample
		$samples{$sample} = 1;
		# move the file
		print("$filename -> $datasubpath/$newfilename\n");
		move($fullfilepath, "$datapath/$newfilename") if (!$dryrun);
	}
}

if (!$dryrun) {
	# print sample names
	open(my $samplesfile, ">$rootpath/$samplefilename");
	for my $sample (keys %samples) {
		print $samplesfile "$sample\n" if ($sample);
	}
	close($samplesfile);
}
