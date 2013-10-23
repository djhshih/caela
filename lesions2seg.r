#!/usr/bin/env Rscript

# ==============================================================================
# PURPOSE
# To compare convert (annotated) lesions file to segmentation file
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2011-10-07
# @Input:    GISTIC all lesions output files (annotated)
# @Output:   segmentation file

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2011-10-07
# Comment:   Initial write
#
# Version:   0.2
# Date:      2011-10-26
# Comment:   Parameterized some variables

# ==============================================================================
# PREAMBLE
#
library(bioinf);

pr <- arg.parser("Convert GISTIC lesions file to segmentation file");
pr <- add.argument(pr, "input", "input file");
pr <- add.argument(pr, "--output", "output file [default: <original stem>.ref.seg]");
pr <- add.argument(pr, "--name", "name field", default="Unique.Name");
pr <- add.argument(pr, "--region", "region field name", default="Wide.Peak.Limits");
pr <- add.argument(pr, "--state", "state field name", default="Status");
pr <- add.argument(pr, "--levels", "state field levels (comma delimited)", default="Remove,Keep");
pr <- add.argument(pr, "--filter", "state field filter value (level index)");
pr <- add.argument(pr, "--noduplicate", "remove duplicates?", flag=TRUE);
pr <- add.argument(pr, "--norename", "simplify region names?", flag=TRUE);

# ==============================================================================
# FUNCTIONS
# 

get.coords <- function(input) {
	tokens <- strsplit(input[, region.field], "[ :\\(\\)-]");
	d <- data.frame(
		chromosome = gsub("chr", "", sapply(tokens, function(x) x[1])),
		start = sapply(tokens, function(x) as.numeric(x[2])),
		end = sapply(tokens, function(x) as.numeric(x[3])),
		count = sapply(tokens, function(x) as.numeric(x[6]) - as.numeric(x[5]) + 1)
	);
	#d$length <- d$end - d$start + 1;
	return (d);
}

# ==============================================================================
# INPUT
# 
argv <- parse.args(pr);

name.field <- argv$name;
region.field <- argv$region;
state.field <- argv$state;
state.levels <- strsplit(argv$levels, ",")[[1]];
state.filter <- argv$filter;

input <- read.delim(argv$input, header=TRUE, stringsAsFactors=FALSE);


# ==============================================================================
# PROCESS
# 

if (argv$noduplicate) {
	region.names <- sapply(strsplit(input[, name.field], " +"), function(x) paste(x[1:3], collapse=" "));
	input <- input[ !duplicated(region.names), ];
}

output <- get.coords(input);

if (argv$norename) {
	output$name <- input[, name.field];
} else {
	output$name <- sapply(strsplit(input[, name.field], " "), function(x) x[1]);
}

# fill in state with zeros
output$state <- 0;

# populate status, if lesions file is annotated
if (!is.na(state.field)) {
	if (state.field %in% names(input)) {
		for (i in 1:length(state.levels)) {
			output$state[ input[, state.field] == state.levels[i] ] <- i;
		}
	}

	if (!is.na(state.filter)) {
		output <- output[ output$state == state.filter, ];
	}
}

# re-order fields
output <- output[, c("name", "chromosome", "start", "end", "count", "state")];

# ==============================================================================
# OUTPUT
# 

if (is.na(argv$output)) {
	output.fname <- as.file.name(argv$input);
	output.fname$ext <- c("ref", "seg");
} else {
	output.fname <- argv$output;
}

write.table(output, as.character(output.fname),
	row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE);

