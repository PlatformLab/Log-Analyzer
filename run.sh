
if [ ! -f SOURCE_DIRECTORY ]; then
  if [ -z "$1" ]; then
    echo "Sources not yet checked out, please invoke ./checkoutSources.sh"
    exit 2
  fi
fi

./gatherRawData.sh
./graph.sh