#!/usr/bin/env Rscript

# ==============================================================================
# PURPOSE
# To convert segmentation file from aroma format to standard format
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2011-06-13
# @Input:    aroma segmentation file
# @Output:   segmentation file

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2011-06-13
# Comment:   Initial write

# ==============================================================================
# PREAMBLE
#
library(bioinf);

p <- arg.parser("Convert segmentation file from aroma.affymetrix format to standard format");
p <- add.argument(p, "input", "input file");
p <- add.argument(p, "--output", "output file");
p <- add.argument(p, "--scale", "scale of copy number state", "original");
p <- add.argument(p, "--nocheck", "skip checking of the scale of the state", flag=TRUE);
p <- add.argument(p, "--stateref", "reference state value", 2);

# ==============================================================================
# INPUT
# 
argv <- parse.args(p);
input <- read.table(argv$input, sep="\t", header=TRUE);

# ==============================================================================
# PROCESS
# 

# Organize columns
input <- input[, c("sample", "chromosome", "start", "stop", "count", "mean")];
names(input) <- seg.df.colnames;

# Possible conversion
if (argv$scale == "log2ratio") {
	if (argv$nocheck || min(input$state) > 0) {
		# if all values are positive, values are probably not already in log scale
		input$state <- log2(input$state / argv$stateref);
	}
} else if (argv$scale == "linear") {
	if (argv$nocheck || min(input$state) < 0) {
		# if at least one value is negative, values are not in linear scale
		# Convert segment means to linear scale centered around stateref
		input$state <- (2 ^ input$state) * argv$stateref;
	}
}

# ==============================================================================
# OUTPUT
# 
if (is.na(argv$output)) {
	# derive output file name from input file name
	f <- as.file.name(argv$input);
	f$date <- Sys.Date();
	f$extensions <- f$extensions[f$extensions != "aroma"];
	argv$output <- as.character(f);
}

write.table(input, argv$output, row.names=FALSE, quote=FALSE, sep="\t");

message("Converted ", argv$input , " to ", argv$output);
