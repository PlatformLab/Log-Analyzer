echo "" > stats.txt
echo "" > graphable_stats.txt

## Spark Logging
SPARK_LOG_FNS="logTrace logDebug logInfo logWarning logError"

echo "" > results/Spark.txt
for LOG_FN in $SPARK_LOG_FNS
do
 cat results/${LOG_FN}.txt >> results/Spark.txt
 ./genDist2.py results/${LOG_FN}.txt results/${LOG_FN}-pdf.txt >> stats.txt
done

./genDist2.py results/Spark.txt results/Spark-pdf.txt >> stats.txt

## Memcached
cp  results/mem_printf.txt  results/Memcached.txt
cat results/mem_fprintf.txt >> results/Memcached.txt
cat results/mem_snprintf.txt >> results/Memcached.txt
cat results/mem_L_DEBUG.txt >> results/Memcached.txt
cat results/mem_E_DEBUG.txt >> results/Memcached.txt

./genDist2.py results/mem_printf.txt    results/mem_printf-pdf.txt    >> stats.txt
./genDist2.py results/mem_fprintf.txt   results/mem_fprintf-pdf.txt   >> stats.txt
./genDist2.py results/mem_snprintf.txt  results/mem_snprintf-pdf.txt  >> stats.txt
./genDist2.py results/mem_L_DEBUG.txt   results/mem_L_DEBUG-pdf.txt   >> stats.txt
./genDist2.py results/mem_E_DEBUG.txt   results/mem_E_DEBUG-pdf.txt   >> stats.txt
./genDist2.py results/Memcached.txt     results/Memcached-pdf.txt     >> stats.txt

## RAMCloud
cp  results/ramcloud_ramcloud_log.txt          results/RAMCloud.txt
cat results/ramcloud_log.txt                >> results/RAMCloud.txt
cat results/ramcloud_ramcloud_die.txt       >> results/RAMCloud.txt
cat results/ramcloud_die.txt                >> results/RAMCloud.txt
cat results/ramcloud_ramcloud_clog.txt      >> results/RAMCloud.txt
cat results/ramcloud_ramcloud_test_log.txt  >> results/RAMCloud.txt
cat results/ramcloud_ramcloud_test.txt      >> results/RAMCloud.txt

./genDist2.py results/ramcloud_ramcloud_log.txt       results/ramcloud_ramcloud_log-pdf.txt       >> stats.txt
./genDist2.py results/ramcloud_log.txt                results/ramcloud_log-pdf.txt                >> stats.txt
./genDist2.py results/ramcloud_ramcloud_die.txt       results/ramcloud_ramcloud_die-pdf.txt       >> stats.txt
./genDist2.py results/ramcloud_die.txt                results/ramcloud_die-pdf.txt                >> stats.txt
./genDist2.py results/ramcloud_ramcloud_clog.txt      results/ramcloud_ramcloud_clog-pdf.txt      >> stats.txt
./genDist2.py results/ramcloud_ramcloud_test_log.txt  results/ramcloud_ramcloud_test_log-pdf.txt  >> stats.txt
# ./genDist2.py results/ramcloud_ramcloud_test.txt   results/ramcloud_ramcloud_test-pdf.txt   >> stats.txt
./genDist2.py results/RAMCloud.txt                    results/RAMCloud-pdf.txt                    >> stats.txt

## Apache
cat results/apache_ap_log_error.txt > results/httpd.txt
cat results/apache_ap_log_rerror.txt >> results/httpd.txt
cat results/apache_ap_log_cerror.txt >> results/httpd.txt
cat results/apache_ap_log_perror.txt >> results/httpd.txt

./genDist2.py results/httpd.txt  results/httpd-pdf.txt   >> stats.txt

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
./genDist2.py --graphable results/httpd.txt >> graphable_stats.txt
./genDist2.py --graphable results/RAMCloud.txt >> graphable_stats.txt
./genDist2.py --graphable results/Memcached.txt >> graphable_stats.txt
./genDist2.py --graphable results/Spark.txt >> graphable_stats.txt

## Graphing
./pivot.py 1 2 4 "graphable_stats.txt" > clusteredStats.txt
mkdir -p graphs 2> /dev/null
gnuplot gnuplot.gnuplot

python genDist2.py --tabularSummary results/Memcached.txt \
                                    results/httpd.txt \
                                    results/linux.txt \
                                    results/Spark.txt \
                                    results/RAMCloud.txt > tbl-logStats-raw.tex
