#! /bin/bash

if [ ! -f SOURCE_DIRECTORY ]; then
  echo ""
  echo "Sources not yet checked out! Please run ./checkoutSources.sh first!"
fi

ROOT_DIR="$(cat SOURCE_DIRECTORY)"

THREADS=32
INPUT_DIR="${ROOT_DIR}/linux"
OUTPUT_DIR="${ROOT_DIR}/linux-preprocessed"


echo "Processing $INPUT_DIR to $OUTPUT_DIR with $THREADS threads..."
mkdir -p "${OUTPUT_DIR}"
FILES=$(find $INPUT_DIR -name '*.c')
xargs -L1 -P $THREADS -I{} ./preprocessFile.sh ${INPUT_DIR}/include $OUTPUT_DIR "{}" <<< "$FILES"
echo "Done!"