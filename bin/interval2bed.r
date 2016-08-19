#!/usr/bin/env Rscript

library(io);
library(argparser);
library(dplyr);

pr <- arg_parser("Convert interval_list to BED") %>%
	add_argument("input", help="input interval list file name") %>%
	add_argument("--output", help="output BED file name") %>%
	add_argument("--outdir", help="output directory")

argv <- parse_args(pr);

input <- read.table(argv$input, comment.char="@", sep="\t", header=FALSE);
colnames(input) <- c("chromosome", "start", "end", "strand", "name");

# interval list coordinate is 1-based
# BED coorindate is 0-based
output <- input %>% transmute(
	chromosome = chromosome,
	start = start - 1,
	end = end,
	name = name
);

stopifnot(min(output$end - output$start) >= 1)

if (is.na(argv$output)) {
	out.fname <- set_fext(as.filename(argv$input), "bed");
	print(out.fname);
	if (!is.na(argv$outdir)) {
		out.fname <- set_fpath(out.fname, argv$outdir);
	}
	out.fname <- tag(out.fname);
} else {
	if (!is.na(argv$outdir)) {
		out.fname <- file.path(argv$outdir, argv$output);
	} else {
		out.fname <- argv$output;
	}
}

write.table(output, out.fname, sep="\t", row.names=FALSE, col.names=FALSE, quote=FALSE);

