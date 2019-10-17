#!/bin/bash
# Extract position list from VCF file.

set -euo pipefail

if (( $# < 1 )) ; then
	echo "usage: $0 <vcf | vcf.gz>"
	exit 1
fi

infile=$1

fname=${infile##*/}
fstem=${fname%.*}
outfile=${fstem}.pos

if [[ ${infile##*.} == "gz" ]]; then
	reader="gunzip -c"
else
	reader="cat"
fi

$reader $infile | grep -v '^#' | cut -f 1,2 > $outfile
