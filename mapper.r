#!/usr/bin/Rscript --vanilla

# ==============================================================================
# PURPOSE
# To create symbolic links to files with an mapped IDs
#
# @Author:   David JH Shih  (djh.shih@gmail.com)
# @License:  GNU General Public License v3 
# @Created:  2013-07-26
# @Input:    mapping table, source and destination directories
# @Output:   symbolic links

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

p <- arg.parser("Create symbolic links to files with mapped IDs")
p <- add.argument(p, "src", "source directory");
p <- add.argument(p, "dest", "destination directory");
p <- add.argument(p, "--pattern", default="(^[^.]*)", "regex pattern of ID to be substituted");
p <- add.argument(p, "--mapping", "mapping table");
p <- add.argument(p, "--name_src", "source name");
p <- add.argument(p, "--name_dest", "destination name");
p <- add.argument(p, "--delimiter", default="\t", "delimiter in mapping file");
p <- add.argument(p, "--command", default="ln -s", "mapping command");


# ==============================================================================
# INPUT
# 

argv <- parse.args(p);

map <- read.table(argv$mapping, sep=argv$delimiter, header=TRUE);

files.src <- list.files(argv$src);


# ==============================================================================
# PROCESS
# 

# determine source and destination IDs
reg.match <- regexpr(argv$pattern, files.src, perl=TRUE);
id.src <- regmatches(files.src, reg.match);
id.dest <- map[[argv$name_dest]][ match(id.src, map[[argv$name_src]]) ];

# replace matching pattern with new IDs
valid <- !is.na(id.dest);
files.src.valid <- files.src[valid];
files.dest <- files.src.valid;
reg.match.sub <- reg.match[valid];
attr(reg.match.sub, "useBytes") <- TRUE;
attr(reg.match.sub, "match.length") <- attr(reg.match, "match.length")[valid];
attr(reg.match.sub, "capture.start") <- attr(reg.match, "capture.start")[valid, , drop=FALSE];
attr(reg.match.sub, "capture.length") <- attr(reg.match, "capture.length")[valid, , drop=FALSE];
regmatches(files.dest, reg.match.sub) <- id.dest[valid];

# create symbolic links
ignore<- mapply(
	function(src, dest) {
		command <- sprintf("%s %s/%s %s/%s", argv$command, argv$src, src, argv$dest, dest);
		system(command);
	},
	files.src.valid,
	files.dest
);

