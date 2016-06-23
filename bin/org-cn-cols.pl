#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;

# Organize column files split from a CN file

my $rootpath = shift or die("Argument missing: root directory\n");

$rootpath = "./$rootpath";
my $stem = substr($rootpath, rindex($rootpath, '/')+1);
if ($stem =~ m|^(.+)(\.d)$|) {
	$stem = $1;
	print "stem: $stem\n";
}

my $datasubpath = "data";
my $datapath = "$rootpath/$datasubpath";

my $suffixrex = "cn";

my $outext = "txt";

my %annotcols = (
	markers => 0,
	chromosomes => 1,
	positions => 2,
);

my $dryrun = 0;

mkdir $datapath if (!$dryrun);

opendir(my $rootdir, $rootpath) or die("Error: cannot open $rootpath");
# Retrieve file names without preceding path
my @filenames = grep {/\.($suffixrex)\.\d+$/} readdir($rootdir);
closedir($rootdir);

foreach my $filename (@filenames) {
	my $fullfilepath = "$rootpath/$filename";
	my $isNotAnnot = 1;
	for my $key (keys %annotcols) {
		my $value = $annotcols{$key};
		if ($filename eq "$stem.$value") {
			# file stores an annotation column
			my $newfilename = "$key.$outext";
			print("$filename -> $newfilename\n");
			if (!$dryrun) {
				move($fullfilepath, "$rootpath/$newfilename");
			}
			$isNotAnnot = 0;
			last;
		}
	}
	if ($isNotAnnot) {
		# use the first line header as the sample name
		open(my $file, $fullfilepath);
		my $sample = <$file>;
		close($file);
		chomp($sample);
		my $newfilename = "$sample.$outext";
		printf("$filename -> $datasubpath/$newfilename\n");
		if (!$dryrun) {
			move($fullfilepath, "$datapath/$newfilename");
		}
	}
}
