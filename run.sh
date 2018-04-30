#! /bin/bash

mkdir results
SPARK_REPO="/Users/syang0/Desktop/staging/LogAnalysis/spark"
MEMCACHED_REPO="/Users/syang0/Desktop/staging/LogAnalysis/memcached/"
RAMCLOUD_REPO="/Users/syang0/Desktop/staging/LogAnalysis/RAMCloud/"

echo "" > stats.txt

SPARK_LOG_FNS="logTrace logDebug logInfo logWarning logError"

echo "" > results/spark.txt
for LOG_FN in $SPARK_LOG_FNS
do
  python sparkParser.py $LOG_FN ${SPARK_REPO} > results/${LOG_FN}.txt
  cat results/${LOG_FN}.txt >> results/spark.txt
  ./genDist2.py results/${LOG_FN}.txt results/${LOG_FN}-pdf.txt >> stats.txt
done

./genDist2.py results/spark.txt results/spark-pdf.txt >> stats.txt

python memcachedParser.py printf 0 $MEMCACHED_REPO > results/mem_printf.txt
python memcachedParser.py fprintf 1 $MEMCACHED_REPO > results/mem_fprintf.txt
python memcachedParser.py snprintf 2 $MEMCACHED_REPO > results/mem_snprintf.txt
python memcachedParser.py L_DEBUG 0 $MEMCACHED_REPO > results/mem_L_DEBUG.txt
python memcachedParser.py E_DEBUG 0 $MEMCACHED_REPO > results/mem_E_DEBUG.txt

# Build meta Memcached numbers
cp  results/mem_printf.txt  results/memcached.txt
cat results/mem_fprintf.txt >> results/memcached.txt
cat results/mem_snprintf.txt >> results/memcached.txt
cat results/mem_L_DEBUG.txt >> results/memcached.txt
cat results/mem_E_DEBUG.txt >> results/memcached.txt

./genDist2.py results/mem_printf.txt    results/mem_printf-pdf.txt    >> stats.txt
./genDist2.py results/mem_fprintf.txt   results/mem_fprintf-pdf.txt   >> stats.txt
./genDist2.py results/mem_snprintf.txt  results/mem_snprintf-pdf.txt  >> stats.txt
./genDist2.py results/mem_L_DEBUG.txt   results/mem_L_DEBUG-pdf.txt   >> stats.txt
./genDist2.py results/mem_E_DEBUG.txt   results/mem_E_DEBUG-pdf.txt   >> stats.txt
./genDist2.py results/memcached.txt   results/memcached-pdf.txt   >> stats.txt


python memcachedParser.py --serverIdFix RAMCLOUD_LOG 1  $RAMCLOUD_REPO > results/ramcloud_ramcloud_log.txt
python memcachedParser.py --serverIdFix LOG 1           $RAMCLOUD_REPO > results/ramcloud_log.txt
python memcachedParser.py --serverIdFix RAMCLOUD_DIE 0  $RAMCLOUD_REPO > results/ramcloud_ramcloud_die.txt
python memcachedParser.py --serverIdFix DIE 0           $RAMCLOUD_REPO > results/ramcloud_die.txt
python memcachedParser.py --serverIdFix RAMCLOUD_CLOG 1 $RAMCLOUD_REPO > results/ramcloud_ramcloud_clog.txt
python memcachedParser.py --serverIdFix RAMCLOUD_TEST_LOG 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test_log.txt
python memcachedParser.py --serverIdFix RAMCLOUD_TEST 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test.txt

# Build meta RAMCloud numbers
cp  results/ramcloud_ramcloud_log.txt results/ramcloud.txt
cat results/ramcloud_log.txt >> results/ramcloud.txt
cat results/ramcloud_ramcloud_die.txt >> results/ramcloud.txt
cat results/ramcloud_die.txt >> results/ramcloud.txt
cat results/ramcloud_ramcloud_clog.txt >> results/ramcloud.txt
cat results/ramcloud_ramcloud_test_log.txt >> results/ramcloud.txt
cat results/ramcloud_ramcloud_test.txt >> results/ramcloud.txt



./genDist2.py results/ramcloud_ramcloud_log.txt    results/ramcloud_ramcloud_log-pdf.txt    >> stats.txt
./genDist2.py results/ramcloud_log.txt   results/ramcloud_log-pdf.txt   >> stats.txt
./genDist2.py results/ramcloud_ramcloud_die.txt  results/ramcloud_ramcloud_die-pdf.txt  >> stats.txt
./genDist2.py results/ramcloud_die.txt   results/ramcloud_die-pdf.txt   >> stats.txt
./genDist2.py results/ramcloud_ramcloud_clog.txt   results/ramcloud_ramcloud_clog-pdf.txt   >> stats.txt
./genDist2.py results/ramcloud_ramcloud_test_log.txt   results/ramcloud_ramcloud_test_log-pdf.txt   >> stats.txt
# ./genDist2.py results/ramcloud_ramcloud_test.txt   results/ramcloud_ramcloud_test-pdf.txt   >> stats.txt
./genDist2.py results/ramcloud.txt   results/ramcloud-pdf.txt   >> stats.txt


gnuplot gnuplot.gnuplot