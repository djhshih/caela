#!/usr/bin/env Rscript

# ==============================================================================
# PURPOSE
# To convert gene expression matrix to GCT format
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2012-07-26
# @Input:    <+X+>
# @Output:   <+X+>

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2012-07-26
# Comment:   Initial write

# ==============================================================================
# PREAMBLE
#
library(bioinf);

pr <- arg.parser("Convert gene expression matrix into GCT format");
pr <- add.argument(pr, "input", "input file");
pr <- add.argument(pr, "--output", "output file [default: <original stem>.gct");



# ==============================================================================
# FUNCTIONS
# 
write.gct <- function(mat, annot, fname) {
	rownames(mat) <- NULL;
	gct <- cbind(annot, mat);
	cat(sprintf("#1.2\n%d\t%d\n", nrow(mat), ncol(mat)), file=fname);
	write.table(gct, fname, append=TRUE,
		row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t");
}

# ==============================================================================
# INPUT
# 
argv <- parse.args(pr);

mat <- read.matrix(argv$input);
annot <- data.frame(Name=rownames(mat), Description="");

if (!is.na(argv$output)) {
	output <- argv$output;
} else {
	output <- as.file.name(argv$input);
	output$ext <- "gct";
	output <- as.character(output);
}


# ==============================================================================
# OUTPUT
# 

write.gct(mat, annot, output);

