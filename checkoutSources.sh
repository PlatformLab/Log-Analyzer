#! /bin/bash

# $1 should be source location
if [ -z "$1" ]
then
  echo ""
  echo "Error: Please specify a checkout directory (ex: $0 /tmp/)"
  exit -1
fi

CHECKOUT_DIR="$1"
OPTIONS="--depth 1"

mkdir -p $CHECKOUT_DIR
git clone https://github.com/apache/spark.git         ${OPTIONS} ${CHECKOUT_DIR}/spark
git clone https://github.com/memcached/memcached.git  ${OPTIONS} ${CHECKOUT_DIR}/memcached
git clone https://github.com/apache/httpd.git         ${OPTIONS} ${CHECKOUT_DIR}/httpd
git clone https://github.com/PlatformLab/RAMCloud.git ${OPTIONS} ${CHECKOUT_DIR}/RAMCloud
git clone https://github.com/torvalds/linux.git       ${OPTIONS} ${CHECKOUT_DIR}/linux

echo "$1" > SOURCE_DIRECTORY

./parallelPreprocess.sh