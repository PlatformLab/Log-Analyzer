set terminal svg size 640, 480 fname 'Verdana,14'
set ylabel "Dynamic Args" font 'Verdana,14'
set xlabel "Static Characters" font 'Verdana,14'

set output 'graphs/spark_scatter.svg'
plot  'results/logTrace.txt', \
      'results/logDebug.txt', \
      'results/logInfo.txt', \
      'results/logWarning.txt', \
      'results/logError.txt'


set output 'graphs/spark_scatter_zoomed.svg'
set xrange[0:350]
plot  'results/logTrace.txt', \
      'results/logDebug.txt', \
      'results/logInfo.txt', \
      'results/logWarning.txt', \
      'results/logError.txt'


set ylabel "Count" font 'Verdana,14'
set title "Spark Static Log Characters PDF"
set output 'graphs/spark_staticPDF.svg'
set xrange[0:150]
plot  'results/logTrace-pdf.txt'    using 1:2 with lines lw 4 title "logTrace", \
      'results/logDebug-pdf.txt'    using 1:2 with lines lw 4 title "logDebug", \
      'results/logInfo-pdf.txt'     using 1:2 with lines lw 4 title "logInfo", \
      'results/logWarning-pdf.txt'  using 1:2 with lines lw 4 title "logWarning", \
      'results/logError-pdf.txt'    using 1:2 with lines lw 4 title "logError"

set title "Spark Static Log Characters CDF"
set output 'graphs/spark_staticCDF.svg'
set xrange[0:400]
plot  'results/logTrace-pdf.txt'    using 1:3 with lines lw 4 title "logTrace", \
      'results/logDebug-pdf.txt'    using 1:3 with lines lw 4 title "logDebug", \
      'results/logInfo-pdf.txt'     using 1:3 with lines lw 4 title "logInfo", \
      'results/logWarning-pdf.txt'  using 1:3 with lines lw 4 title "logWarning", \
      'results/logError-pdf.txt'    using 1:3 with lines lw 4 title "logError"

set title "Memcached Static Log Characters PDF"
set output 'graphs/mem_staticPDF.svg'
set xrange[0:400]
plot  'results/mem_printf-pdf.txt'      using 1:2 with lines lw 4 title "printf", \
      'results/mem_fprintf-pdf.txt'     using 1:2 with lines lw 4 title "fprintf", \
      'results/mem_snprintf-pdf.txt'    using 1:2 with lines lw 4 title "snprintf", \
      'results/mem_L_DEBUG-pdf.txt'     using 1:2 with lines lw 4 title "L_DEBUG", \
      'results/mem_E_DEBUG-pdf.txt'     using 1:2 with lines lw 4 title "E_DEBUG"

set title "Memcached Static Log Characters CDF"
set output 'graphs/mem_staticCDF.svg'
set xrange[0:400]
plot  'results/mem_printf-pdf.txt'      using 1:3 with lines lw 4 title "printf", \
      'results/mem_fprintf-pdf.txt'     using 1:3 with lines lw 4 title "fprintf", \
      'results/mem_snprintf-pdf.txt'    using 1:3 with lines lw 4 title "snprintf", \
      'results/mem_L_DEBUG-pdf.txt'     using 1:3 with lines lw 4 title "L_DEBUG", \
      'results/mem_E_DEBUG-pdf.txt'     using 1:3 with lines lw 4 title "E_DEBUG"

set title "RAMCloud Static Log Characters PDF"
set output 'graphs/ram_staticPDF.svg'
set xrange[0:400]
plot  'results/ramcloud_ramcloud_log-pdf.txt'      using 1:2 with lines lw 4 title "RAMCLOUD_LOG", \
      'results/ramcloud_log-pdf.txt'               using 1:2 with lines lw 4 title "LOG", \
      'results/ramcloud_ramcloud_die-pdf.txt'      using 1:2 with lines lw 4 title "RAMCLOUD_DIE", \
      'results/ramcloud_die-pdf.txt'               using 1:2 with lines lw 4 title "DIE", \
      'results/ramcloud_ramcloud_clog-pdf.txt'     using 1:2 with lines lw 4 title "RAMCLOUD_CLOG", \
      'results/ramcloud_ramcloud_test_log-pdf.txt' using 1:2 with lines lw 4 title "RACLOUD_TEST_LOG"

set title "RAMCloud Static Log Characters CDF"
set output 'graphs/ram_staticCDF.svg'
set xrange[0:400]
plot  'results/ramcloud_ramcloud_log-pdf.txt'      using 1:3 with lines lw 4 title "RAMCLOUD_LOG", \
      'results/ramcloud_log-pdf.txt'               using 1:3 with lines lw 4 title "LOG", \
      'results/ramcloud_ramcloud_die-pdf.txt'      using 1:3 with lines lw 4 title "RAMCLOUD_DIE", \
      'results/ramcloud_die-pdf.txt'               using 1:3 with lines lw 4 title "DIE", \
      'results/ramcloud_ramcloud_clog-pdf.txt'     using 1:3 with lines lw 4 title "RAMCLOUD_CLOG", \
      'results/ramcloud_ramcloud_test_log-pdf.txt' using 1:3 with lines lw 4 title "RACLOUD_TEST_LOG"


set title "Static Characters vs. Number of Dynamic Variables"
set output "StaticVDynamic.svg"

set xrange [0:10]
plot 'graphable_stats.txt' using 2:4 index 0 title "Linux", \
            "" using 2:4 index 1 with linespoints title "Apache", \
            "" using 2:4 index 2 with linespoints title "RAMCloud", \
            "" using 2:4 index 3 with linespoints title "memcached", \
            "" using 2:4 index 4 with linespoints title "Spark", \


set title "Average Static Characters vs. Number of Dynamic Variables"
set output "cluster.svg"
set style data histogram
set style histogram cluster gap 1

set xlabel "System"
set ylabel "Average Static Characters"

set key maxrows 6
set style fill solid border rgb "black"
set auto x
set yrange [0:*]
plot 'clusteredStats.txt' using 2:xtic(1) title col, \
        '' using 3:xtic(1) title col, \
        '' using 4:xtic(1) title col, \
        '' using 5:xtic(1) title col, \
        '' using 6:xtic(1) title col, \
        '' using 7:xtic(1) title col, \
        '' using 8:xtic(1) title col, \
        '' using 9:xtic(1) title col, \
        '' using 10:xtic(1) title col, \
        '' using 11:xtic(1) title col, \
        '' using 12:xtic(1) title col, \
