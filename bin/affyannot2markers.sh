#!/bin/sh

USAGE="usage: `basename $0` <input> <output>"

# Parse command line options
while getopts hv OPT; do
	case "$OPT" in
		h)
			echo $USAGE
			exit 0
			;;
		v)
			echo "`basename $0` v0.1"
			exit 0
			;;
		\?)
			# getopts issues an error message
			echo $USAGE >&2
			exit 1
			;;
	esac
done

# Remove the switches parsed above
shift `expr $OPTIND - 1`

# Positional arguments
argc=2
if [ $# -lt $argc ]; then

	echo $USAGE >&2
	echo "Error: expected $argc required arguments; given $# arguments";
	exit 1

else

	INPUT=$1
	OUTPUT=$2

	# pipe non-comment lines
	grep -v '^[[:space:]]*#' $INPUT | 
		# extract columns: SNP, chromosome, position
		cut --fields=1,3,4 --delimiter=',' --output-delimiter='	' |
		# remove lines with blank coordinates, strip quotes, and remove first line
		sed -e '/---/d' -e 's/"//g' -e 1d > $OUTPUT

fi

