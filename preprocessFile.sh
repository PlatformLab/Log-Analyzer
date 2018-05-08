#! /bin/bash

# This is a helper script to ParallelPreprocess

if [ "$#" -lt 3 ]; then
  echo ""
  echo "Do not invoke this script separately! Please invoke ./parallelProcess.sh intead!"
  exit 1
fi

# $1 Should be include directory
# $2 should be output DIR
# $3 should be file location
INCLUDE="$1"
OUTPUT="$2"
FILE="$3"

OUTPUT_FILE="${OUTPUT}/${FILE}"
if [ -f "$OUTPUT_FILE" ]; then
  exit 0
fi

# Trap function that deletes the (potentially) partial
# output file if Ctrl+C is encountered.
function cancel() {
  rm -f ${OUTPUT_FILE}
}

trap cancel INT

DIR=$(dirname $FILE)
mkdir -p "${OUTPUT}/${DIR}"
# echo "Preprocessing $FILE with -I${INCLUDE} | $OUTPUT"
gcc -E -I${INCLUDE} $FILE 2> /dev/null > "${OUTPUT_FILE}"
