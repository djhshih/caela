#!/usr/bin/env Rscript

# ==============================================================================
# PURPOSE
# To convert segmentation file between lienar and log2ratio scale
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2011-06-13
# @Input:    segmentation file
# @Output:   segmentation file

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2011-10-26
# Comment:   Initial write

# ==============================================================================
# PREAMBLE
#
library(bioinf);

p <- arg.parser("Convert segmentation file between linear and log2ratio scale");
p <- add.argument(p, "input", "input file");
p <- add.argument(p, "--output", "output file");
p <- add.argument(p, "--scale", "scale of copy number state", "opposite");
p <- add.argument(p, "--nocheck", "skip checking of the scale of the state", flag=TRUE);
p <- add.argument(p, "--stateref", "reference state value", default=2);
p <- add.argument(p, "--column", "state column name(s)", "state");

# ==============================================================================
# INPUT
# 
argv <- parse.args(p);
argv$column <- strsplit(argv$column, ",")[[1]];
argv$stateref <- as.numeric(argv$stateref);

input <- read.table(argv$input, sep="\t", header=TRUE);


# ==============================================================================
# PROCESS
# 

min.value <- min( input[, argv$column] );

# Convert to opposite scale
if (argv$scale == "opposite") {
	if (min.value >= 0) {
		# original scale is probably integer: convert to log2ratio
		argv$scale <- "lgr";
	} else if (min.value < 0) {
		# original scale is not integer scale: convert to integer
		argv$scale <- "lin";
	}
	argv$nocheck <- TRUE;
}

# Conversion
if (argv$scale == "lgr") {
	if (argv$nocheck || min.value >= 0) {
		# if all values are positive, values are probably not already in log scale
		input[, argv$column] <- log2(input[, argv$column] / argv$stateref);
	} else {
		warning("Original data are already in log2ratio scale");
	}
} else if (argv$scale == "lin") {
	if (argv$nocheck || min.value < 0) {
		# if at least one value is negative, values are not in linear scale
		# Convert segment means to linear scale centered around stateref
		input[, argv$column] <- (2 ^ input[, argv$column]) * argv$stateref;
	} else {
		warning("Original data are already in integer scale");
	}
}

# ==============================================================================
# OUTPUT
# 
if (is.na(argv$output)) {
	# derive output file name from input file name
	f <- insert(as.file.name(argv$input), ext=argv$scale);
	argv$output <- as.character(f);
}

write.table(input, argv$output, row.names=FALSE, quote=FALSE, sep="\t");

message("Converted ", argv$input , " to ", argv$output);

