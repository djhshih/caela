#!/usr/bin/env Rscript

# ==============================================================================
# PURPOSE
# To convert copy-number segmentation file into individual BED files
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2013-10-18
# @Input:    SEG
# @Output:   BED

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2013-10-18
# Comment:   Initial write

# ==============================================================================
# PREAMBLE
#
library(argparse);
library(bioinf);

p <- arg.parser("Convert segmentation file into individual BED files");
p <- add.argument(p, "input", "input file");
p <- add.argument(p, "output_dir", "output directory");
p <- add.argument(p, "--delimiter", default="\t", "delimiter in input and output file");
p <- add.argument(p, "--preext", default="cn", "file extension prefix");

# ==============================================================================
# FUNCTIONS
# 

seg2bed <- function(d){
	cols <- list(sample=1, chromosome=2, start=3, end=4, count=5, state=6);

	# append prefix to chromosome
	d[, cols$chromosome] <- paste("chr", d[, cols$chromosome], sep="");
	# convert start coordinates to 0-based
	d[, cols$start] <- d[, cols$start] - 1;
	# end coordinate is one past the ending base in 0-based index
	# therefore, end coordinate requires no conversion

	# do column removals later, since indexing changes

	# remove the sample column
	d[, cols$sample] <- NULL;

	d
}

# ==============================================================================
# INPUT
# 
argv <- parse.args(p);

input <- read.table(argv$input, sep=argv$delimiter, header=TRUE);


# ==============================================================================
# PROCESS
# 

# split by sample
inputs.split <- split(input, input$sample);

outputs <- lapply(inputs.split, seg2bed);

# ==============================================================================
# OUTPUT
#

dir.create(argv$output_dir, recursive=TRUE);
discard <- lapply(names(outputs),
	function(id) {
		write.table(outputs[[id]],
			file=file.path(argv$output_dir, paste(id, argv$preext, "bed", sep=".")),
			sep=argv$delimiter, col.names=FALSE, row.names=FALSE, quote=FALSE);
	}
);

