#!/usr/bin/env Rscript

library(io);
library(argparser);

options(filenamer.timestamp=0, filenamer.path.timestamp=0);

pr <- arg_parser("Get ensemble ids");
pr <- add_argument(pr, "species", "query species (e.g. hsapiens, mmusculus)")

argv <- parse_args(pr);

species <- argv$species;

library(biomaRt);

mart <- useMart(biomart = "ensembl",
	dataset = sprintf("%s_gene_ensembl", species));
release <- sub("[^0-9]*([0-9]+)", "\\1", listEnsembl()$version[1]);

results <- getBM(attributes = c(
	"ensembl_gene_id",
	"ensembl_transcript_id",
	"ensembl_peptide_id",
	"symbol"
), mart = mart);

output.fname <- filename("ensembl_ids", tag = species, path = sprintf("release-%s", release))

qwrite(results, tag(output.fname, ext="rds"));
qwrite(results, tag(output.fname, ext="tsv"));

