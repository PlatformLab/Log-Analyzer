set terminal svg size 1920, 1080 fname 'Verdana, 24'
set ylabel "Dynamic Args" font 'Verdana,24'
set xlabel "Static Characters" font 'Verdana,24'

set output 'spark_scatter.svg'
plot  'results/logTrace.txt', \
      'results/logDebug.txt', \
      'results/logInfo.txt', \
      'results/logWarning.txt', \
      'results/logError.txt'


set output 'spark_scatter_zoomed.svg'
set xrange[0:350]
plot  'results/logTrace.txt', \
      'results/logDebug.txt', \
      'results/logInfo.txt', \
      'results/logWarning.txt', \
      'results/logError.txt'


set ylabel "Count" font 'Verdana,24'
set title "Spark Static Log Characters PDF"
set output 'spark_staticPDF.svg'
set xrange[0:150]
plot  'results/logTrace-pdf.txt'    using 1:2 with lines lw 4 title "logTrace", \
      'results/logDebug-pdf.txt'    using 1:2 with lines lw 4 title "logDebug", \
      'results/logInfo-pdf.txt'     using 1:2 with lines lw 4 title "logInfo", \
      'results/logWarning-pdf.txt'  using 1:2 with lines lw 4 title "logWarning", \
      'results/logError-pdf.txt'    using 1:2 with lines lw 4 title "logError"

set title "Spark Static Log Characters CDF"
set output 'spark_staticCDF.svg'
set xrange[0:400]
plot  'results/logTrace-pdf.txt'    using 1:3 with lines lw 4 title "logTrace", \
      'results/logDebug-pdf.txt'    using 1:3 with lines lw 4 title "logDebug", \
      'results/logInfo-pdf.txt'     using 1:3 with lines lw 4 title "logInfo", \
      'results/logWarning-pdf.txt'  using 1:3 with lines lw 4 title "logWarning", \
      'results/logError-pdf.txt'    using 1:3 with lines lw 4 title "logError"

set title "Memcached Static Log Characters PDF"
set output 'mem_staticPDF.svg'
set xrange[0:400]
plot  'results/mem_printf-pdf.txt'      using 1:2 with lines lw 4 title "printf", \
      'results/mem_fprintf-pdf.txt'     using 1:2 with lines lw 4 title "fprintf", \
      'results/mem_snprintf-pdf.txt'    using 1:2 with lines lw 4 title "snprintf", \
      'results/mem_L_DEBUG-pdf.txt'     using 1:2 with lines lw 4 title "L_DEBUG", \
      'results/mem_E_DEBUG-pdf.txt'     using 1:2 with lines lw 4 title "E_DEBUG"

set title "Memcached Static Log Characters CDF"
set output 'mem_staticCDF.svg'
set xrange[0:400]
plot  'results/mem_printf-pdf.txt'      using 1:3 with lines lw 4 title "printf", \
      'results/mem_fprintf-pdf.txt'     using 1:3 with lines lw 4 title "fprintf", \
      'results/mem_snprintf-pdf.txt'    using 1:3 with lines lw 4 title "snprintf", \
      'results/mem_L_DEBUG-pdf.txt'     using 1:3 with lines lw 4 title "L_DEBUG", \
      'results/mem_E_DEBUG-pdf.txt'     using 1:3 with lines lw 4 title "E_DEBUG"

set title "RAMCloud Static Log Characters PDF"
set output 'ram_staticPDF.svg'
set xrange[0:400]
plot  'results/ramcloud_ramcloud_log-pdf.txt'      using 1:2 with lines lw 4 title "RAMCLOUD_LOG", \
      'results/ramcloud_log-pdf.txt'               using 1:2 with lines lw 4 title "LOG", \
      'results/ramcloud_ramcloud_die-pdf.txt'      using 1:2 with lines lw 4 title "RAMCLOUD_DIE", \
      'results/ramcloud_die-pdf.txt'               using 1:2 with lines lw 4 title "DIE", \
      'results/ramcloud_ramcloud_clog-pdf.txt'     using 1:2 with lines lw 4 title "RAMCLOUD_CLOG", \
      'results/ramcloud_ramcloud_test_log-pdf.txt' using 1:2 with lines lw 4 title "RACLOUD_TEST_LOG"

set title "RAMCloud Static Log Characters CDF"
set output 'ram_staticCDF.svg'
set xrange[0:400]
plot  'results/ramcloud_ramcloud_log-pdf.txt'      using 1:3 with lines lw 4 title "RAMCLOUD_LOG", \
      'results/ramcloud_log-pdf.txt'               using 1:3 with lines lw 4 title "LOG", \
      'results/ramcloud_ramcloud_die-pdf.txt'      using 1:3 with lines lw 4 title "RAMCLOUD_DIE", \
      'results/ramcloud_die-pdf.txt'               using 1:3 with lines lw 4 title "DIE", \
      'results/ramcloud_ramcloud_clog-pdf.txt'     using 1:3 with lines lw 4 title "RAMCLOUD_CLOG", \
      'results/ramcloud_ramcloud_test_log-pdf.txt' using 1:3 with lines lw 4 title "RACLOUD_TEST_LOG"