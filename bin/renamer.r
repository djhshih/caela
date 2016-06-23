#!/usr/bin/Rscript --vanilla

# ==============================================================================
# PURPOSE
# To create symbolic links to files with an mapped IDs
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2013-07-26
# @Input:    data table, mapping table
# @Output:   data table with mapped IDs

# ==============================================================================
# HISTORY
#
# Version:   0.1
# Date:      2013-07-26
# Comment:   Initial write

# ==============================================================================
# PREAMBLE
#
library(argparse);
library(bioinf);

p <- arg.parser("Map IDs within a data table")
p <- add.argument(p, "src", "source file");
p <- add.argument(p, "mapping", "mapping table");
p <- add.argument(p, "--output", "output file");
p <- add.argument(p, "--field", default="id", "name of field containing the IDs");
p <- add.argument(p, "--noheader", default=FALSE, flag=TRUE, "source data table does not containg a header row");
p <- add.argument(p, "--name_src", default="src", "source name");
p <- add.argument(p, "--name_dest", dest="dest", "destination name");
p <- add.argument(p, "--delimiter", default="\t", "delimiter in mapping file");


# ==============================================================================
# INPUT
# 

argv <- parse.args(p);

src <- read.table(argv$src, sep=argv$delimiter, header=!argv$noheader, check.names=FALSE);
map <- read.table(argv$mapping, sep=argv$delimiter, header=TRUE);

if (is.na(argv$output)) {
	output.fname <- as.file.name(argv$src)
	output.fname <- tag(output.fname, "rn");
} else {
	output.fname <- argv$output;
}


# ==============================================================================
# PROCESS
# 

# determine source and destination IDs
id.src <- src[[argv$field]];
id.dest <- map[[argv$name_dest]][ match(id.src, map[[argv$name_src]]) ];

# replace old ID with new ID
dest <- src;
dest[[argv$field]] <- id.dest;

write.table(dest, output.fname, col.names=!argv$noheader, row.names=FALSE, sep=argv$delimiter, quote=FALSE);

