echo "" > stats.txt
echo "" > graphable_stats.txt

## Spark Logging
SPARK_LOG_FNS="logTrace logDebug logInfo logWarning logError"

echo "" > results/spark.txt
for LOG_FN in $SPARK_LOG_FNS
do
 cat results/${LOG_FN}.txt >> results/spark.txt
 ./genDist2.py results/${LOG_FN}.txt results/${LOG_FN}-pdf.txt >> stats.txt
done

./genDist2.py results/spark.txt results/spark-pdf.txt >> stats.txt

## Memcached
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
./genDist2.py results/memcached.txt     results/memcached-pdf.txt     >> stats.txt

## RAMCloud
cp  results/ramcloud_ramcloud_log.txt          results/ramcloud.txt
cat results/ramcloud_log.txt                >> results/ramcloud.txt
cat results/ramcloud_ramcloud_die.txt       >> results/ramcloud.txt
cat results/ramcloud_die.txt                >> results/ramcloud.txt
cat results/ramcloud_ramcloud_clog.txt      >> results/ramcloud.txt
cat results/ramcloud_ramcloud_test_log.txt  >> results/ramcloud.txt
cat results/ramcloud_ramcloud_test.txt      >> results/ramcloud.txt

./genDist2.py results/ramcloud_ramcloud_log.txt       results/ramcloud_ramcloud_log-pdf.txt       >> stats.txt
./genDist2.py results/ramcloud_log.txt                results/ramcloud_log-pdf.txt                >> stats.txt
./genDist2.py results/ramcloud_ramcloud_die.txt       results/ramcloud_ramcloud_die-pdf.txt       >> stats.txt
./genDist2.py results/ramcloud_die.txt                results/ramcloud_die-pdf.txt                >> stats.txt
./genDist2.py results/ramcloud_ramcloud_clog.txt      results/ramcloud_ramcloud_clog-pdf.txt      >> stats.txt
./genDist2.py results/ramcloud_ramcloud_test_log.txt  results/ramcloud_ramcloud_test_log-pdf.txt  >> stats.txt
# ./genDist2.py results/ramcloud_ramcloud_test.txt   results/ramcloud_ramcloud_test-pdf.txt   >> stats.txt
./genDist2.py results/ramcloud.txt                    results/ramcloud-pdf.txt                    >> stats.txt

## Apache
cat results/apache_ap_log_error.txt > results/apache.txt
cat results/apache_ap_log_rerror.txt >> results/apache.txt
cat results/apache_ap_log_cerror.txt >> results/apache.txt
cat results/apache_ap_log_perror.txt >> results/apache.txt

./genDist2.py results/apache.txt  results/apache-pdf.txt   >> stats.txt

## Linux
./genDist2.py results/linux_printk.txt      results/linux_printk-pdf.txt      >> stats.txt
./genDist2.py results/linux_dev_printk.txt  results/linux_dev_printk-pdf.txt  >> stats.txt
./genDist2.py results/linux_warn_once.txt   results/linux_warn_once-pdf.txt   >> stats.txt

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
