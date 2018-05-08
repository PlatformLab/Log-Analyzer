#! /bin/bash

if [ -f SOURCE_DIRECTORY ]; then
  ROOT_SRC_DIR="$(cat SOURCE_DIRECTORY)"
else
  ROOT_SRC_DIR="./"
fi

mkdir results 2> /dev/null
SPARK_REPO="${ROOT_SRC_DIR}/spark"
MEMCACHED_REPO="${ROOT_SRC_DIR}/memcached/"
RAMCLOUD_REPO="${ROOT_SRC_DIR}/RAMCloud/"
APACHE_REPO="${ROOT_SRC_DIR}/httpd"
LINUX_PP_REPO="${ROOT_SRC_DIR}/linux-preprocessed"

SPARK_LOG_FNS="logTrace logDebug logInfo logWarning logError"

echo "" > results/spark.txt
for LOG_FN in $SPARK_LOG_FNS
do
 python sparkParser.py $LOG_FN ${SPARK_REPO} > results/${LOG_FN}.txt
 cat results/${LOG_FN}.txt >> results/spark.txt
done

## Memcached
python logParserForC.py printf 0 $MEMCACHED_REPO > results/mem_printf.txt
python logParserForC.py fprintf 1 $MEMCACHED_REPO > results/mem_fprintf.txt
python logParserForC.py snprintf 2 $MEMCACHED_REPO > results/mem_snprintf.txt
python logParserForC.py L_DEBUG 0 $MEMCACHED_REPO > results/mem_L_DEBUG.txt
python logParserForC.py E_DEBUG 0 $MEMCACHED_REPO > results/mem_E_DEBUG.txt

## RAMCloud
python logParserForC.py --serverIdFix RAMCLOUD_LOG 1  $RAMCLOUD_REPO > results/ramcloud_ramcloud_log.txt
python logParserForC.py --serverIdFix LOG 1           $RAMCLOUD_REPO > results/ramcloud_log.txt
python logParserForC.py --serverIdFix RAMCLOUD_DIE 0  $RAMCLOUD_REPO > results/ramcloud_ramcloud_die.txt
python logParserForC.py --serverIdFix DIE 0           $RAMCLOUD_REPO > results/ramcloud_die.txt
python logParserForC.py --serverIdFix RAMCLOUD_CLOG 1 $RAMCLOUD_REPO > results/ramcloud_ramcloud_clog.txt
python logParserForC.py --serverIdFix RAMCLOUD_TEST_LOG 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test_log.txt
python logParserForC.py --serverIdFix RAMCLOUD_TEST 0 $RAMCLOUD_REPO > results/ramcloud_ramcloud_test.txt

## Apache
python logParserForC.py --apacheApLogNoFix ap_log_error 4 $APACHE_REPO > results/apache_ap_log_error.txt
python logParserForC.py --apacheApLogNoFix ap_log_rerror 4 $APACHE_REPO > results/apache_ap_log_rerror.txt
python logParserForC.py --apacheApLogNoFix ap_log_cerror 4 $APACHE_REPO > results/apache_ap_log_cerror.txt
python logParserForC.py --apacheApLogNoFix ap_log_perror 4 $APACHE_REPO > results/apache_ap_log_perror.txt

# # ## These log messsages shouldn't really be counted since they're used by utilities/tests
# # python logParserForC.py --apacheApLogNoFix printf 0 $APACHE_REPO > results/apache_printf.txt
# # python logParserForC.py --apacheApLogNoFix fprintf 1 $APACHE_REPO > results/apache_fprintf.txt

## Linux
echo "Starting linux jobs... This could take a while..."
python logParserForC.py --preprocessed printk 0 ${LINUX_PP_REPO} > results/linux_printk.txt &
python logParserForC.py --preprocessed dev_printk 2 ${LINUX_PP_REPO} > results/linux_dev_printk.txt &
python logParserForC.py --preprocessed WARN_ONCE 1 ${LINUX_PP_REPO} > results/linux_warn_once.txt &

wait
echo "Linux parsing done!"