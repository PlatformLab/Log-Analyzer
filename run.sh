#! /bin/bash

mkdir results 2> /dev/null
SPARK_REPO="/Users/syang0/Desktop/staging/LogAnalysis/spark"
MEMCACHED_REPO="/Users/syang0/Desktop/staging/LogAnalysis/memcached/"
RAMCLOUD_REPO="/Users/syang0/Desktop/staging/LogAnalysis/RAMCloud/"
APACHE_REPO="/Users/syang0/Desktop/staging/LogAnalysis/httpd"
LINUX_PP_REPO="/Users/syang0/Desktop/staging/LogAnalysis/linux-preprocessed"

echo "" > stats.txt
echo "" > graphable_stats.txt

## Spark Logging

SPARK_LOG_FNS="logTrace logDebug logInfo logWarning logError"

echo "" > results/spark.txt
for LOG_FN in $SPARK_LOG_FNS
do
 python sparkParser.py $LOG_FN ${SPARK_REPO} > results/${LOG_FN}.txt
 cat results/${LOG_FN}.txt >> results/spark.txt
 ./genDist2.py results/${LOG_FN}.txt results/${LOG_FN}-pdf.txt >> stats.txt
done

./genDist2.py results/spark.txt results/spark-pdf.txt >> stats.txt

## Memcached
python logParserForC.py printf 0 $MEMCACHED_REPO > results/mem_printf.txt
python logParserForC.py fprintf 1 $MEMCACHED_REPO > results/mem_fprintf.txt
python logParserForC.py snprintf 2 $MEMCACHED_REPO > results/mem_snprintf.txt
python logParserForC.py L_DEBUG 0 $MEMCACHED_REPO > results/mem_L_DEBUG.txt
python logParserForC.py E_DEBUG 0 $MEMCACHED_REPO > results/mem_E_DEBUG.txt

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

## RAMCloud
python logParserForC.py --serverIdFix RAMCLOUD_LOG 1  $RAMCLOUD_REPO > results/ramcloud_ramcloud_log.txt
python logParserForC.py --serverIdFix LOG 1           $RAMCLOUD_REPO > results/ramcloud_log.txt
python logParserForC.py --serverIdFix RAMCLOUD_DIE 0  $RAMCLOUD_REPO > results/ramcloud_ramcloud_die.txt
python logParserForC.py --serverIdFix DIE 0           $RAMCLOUD_REPO > results/ramcloud_die.txt
python logParserForC.py --serverIdFix RAMCLOUD_CLOG 1 $RAMCLOUD_REPO > results/ramcloud_ramcloud_clog.txt
python logParserForC.py --serverIdFix RAMCLOUD_TEST_LOG 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test_log.txt
python logParserForC.py --serverIdFix RAMCLOUD_TEST 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test.txt

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

## Apache
python logParserForC.py --apacheApLogNoFix ap_log_error 4 $APACHE_REPO > results/apache_ap_log_error.txt
python logParserForC.py --apacheApLogNoFix ap_log_rerror 4 $APACHE_REPO > results/apache_ap_log_rerror.txt
python logParserForC.py --apacheApLogNoFix ap_log_cerror 4 $APACHE_REPO > results/apache_ap_log_cerror.txt
python logParserForC.py --apacheApLogNoFix ap_log_perror 4 $APACHE_REPO > results/apache_ap_log_perror.txt

# # ## These log messsages shouldn't really be counted since they're used by utilities/tests
# # python logParserForC.py --apacheApLogNoFix printf 0 $APACHE_REPO > results/apache_printf.txt
# # python logParserForC.py --apacheApLogNoFix fprintf 1 $APACHE_REPO > results/apache_fprintf.txt

# Build apache metalogs
cat results/apache_ap_log_error.txt > results/apache.txt
cat results/apache_ap_log_rerror.txt >> results/apache.txt
cat results/apache_ap_log_cerror.txt >> results/apache.txt
cat results/apache_ap_log_perror.txt >> results/apache.txt

./genDist2.py results/apache.txt  results/apache-pdf.txt   >> stats.txt

## Linux
echo "Starting linux jobs... This could take a while..."
python logParserForC.py printk 0 ${LINUX_PP_REPO} > results/linux_printk.txt &
python logParserForC.py dev_printk 2 ${LINUX_PP_REPO} > results/linux_dev_printk.txt &
python logParserForC.py WARN_ONCE 1 ${LINUX_PP_REPO} > results/linux_warn_once.txt &

wait
echo "Linux parsing done!"

./genDist2.py results/linux_printk.txt results/linux_printk-pdf.txt >> stats.txt
./genDist2.py results/linux_dev_printk.txt results/linux_dev_printk-pdf.txt >> stats.txt
./genDist2.py results/linux_warn_once.txt results/linux_warn_once-pdf.txt >> stats.txt

# Build aggregate
cat results/linux_printk.txt > results/linux.txt
cat results/linux_dev_printk.txt >> results/linux.txt
cat results/linux_warn_once.txt >> results/linux.txt

./genDist2.py results/linux.txt results/linux-pdf.txt >> stats.txt

./genDist2.py --graphable results/linux.txt > graphable_stats.txt
./genDist2.py --graphable results/apache.txt >> graphable_stats.txt
./genDist2.py --graphable results/ramcloud.txt >> graphable_stats.txt
./genDist2.py --graphable results/memcached.txt >> graphable_stats.txt
./genDist2.py --graphable results/spark.txt >> graphable_stats.txt

## Graphing
./pivot.py 1 2 4 "graphable_stats.txt" > clusteredStats.txt
gnuplot gnuplot.gnuplot

python genDist2.py --tabularSummary results/memcached.txt \
                                    results/apache.txt \
                                    results/linux.txt \
                                    results/apache.txt \
                                    results/ramcloud.txt > tbl-logStats-raw.tex

./genDist2.py --tabularSummary results/memcached.txt > logStats-raw.tex
./genDist2.py --tabularSummary results/apache.txt >> logStats-raw.tex
./genDist2.py --tabularSummary results/linux.txt >> logStats-raw.tex
./genDist2.py --tabularSummary results/ramcloud.txt >> logStats-raw.tex
./genDist2.py --tabularSummary results/apache.txt >> logStats-raw.tex
./genDist2.py --tabularSummary results/spark.txt >> logStats-raw.tex
