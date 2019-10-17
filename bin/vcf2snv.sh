#!/bin/bash
# Extract SNV information from VCF file.

set -euo pipefail

if (( $# < 1 )) ; then
	echo "usage: $0 <vcf | vcf.gz>"
	exit 1
fi

infile=$1

fname=${infile##*/}
fstem=${fname%.*}
outfile=${fstem}.snv

if [[ ${infile##*.} == "gz" ]]; then
	reader="gunzip -c"
else
	reader="cat"
fi

printf "chrom\tpos\tref\talt\n" > $outfile
$reader $infile | grep -v '^#' | cut -f 1,2,4,5 >> $outfile
