# Log Analyzer
This repository contains a series of scripts to search for all log messages in Spark, memcached, and RAMCloud and count the number of static characters in their log messages vs. the number of dynamic ones. These scripts should be considered "best effort" since they use a collection of heuristics to find log messages and do not compile the sources (and hence some log messages can be missed if they are re-defined or use a dynamic log string).

## Spark
Spark has 5 log functions:
 - logTrace()
 - logDebug()
 - logInfo()
 - logWarning()
 - logError()

And since Spark is written in Java/Scala, the log functions just take in 1 dynamic string string to output. This unfortunately means that we can't always get the type of the dynamic variables (unless they call .format()), so the best we can do is just count the number of static characters and exclude dynamic variables. To motivate some of the heuristics we used to detect the dynamic variables, here are some log patterns:
  - ```logInfo(s"Static Text $var1 ${var2} ${var3.value}")```
  - ```logInfo("Just static")```
  - ```logInfo("Static with a format %d".format(dynamic))```
  - ```logInfo("Concatinations " + "which " + s"are $annoying")```
  - ```logInfo( ("This is a %d" + "multi format %lf"). format)```
  - ```logInfo(completelyDynamic)```
  - ```logInfo("""Triple quotes are a thing too %s""".format(...))```

### Algorithm
The heuristic we use for Spark logs are first split the first argument string by the "+" and ")" characters when the curly/paraen/brack/quote depth is 0, since those characters indicate either a complete string the end of a multi-format. Then we detect the 4 common cases:
  1. If it begins with a "s" it's a substitution, so remove all the ```$vars``` and ```${var.vars}``` and the ```s""``` and count the remaining text.
  2. If it begins with a ```(``` or a ```"```, then then take everything inside the quotes, remove the usual ```%``` specifiers, and count the remaining within the quotes (this means the .format(...) and it's variables are excluded/ignored in this count).
  3. If it begins with any of the triple quote variations, ```"""```, ```s"""```, ```("""```, then strip the triple quotes and follow the appropriate rules for 1+2. Returns embedded inside the triple quotes are also counted.
  4. If we see NO quotes at all, it means the argument is completely dynamic.

## Memcached
For memcached there are 5 log-ish statements
  - printf(...)
  - fprintf(...)
  - snprintf(...)
  - L_DEBUG(...)
  - E_DEBUG(...)

with fprintf being the most common error logging. Ideally, we'd like to detect the verbosity of when fprintf is invoked, but it's hard to do reliably (i.e. detect the surrounding "if(verbose > 1)"). Therefore, we count all fprintf's as one class of logs.

### Algorithm
With memcached, we process them as we would process RAMCloud logs, which is
 1. Find the log function in question
 2. Extract the full format string
 3. Count the number of specifiers


## RAMCloud
Lastly, there's RAMCloud which follows the rules above, but it also have 5 different log statements
  - RAMCLOUD_LOG(...)
  - RAMCLOUD_DIE(...)
  - RAMCLOUD_TEST_LOG(...)
  - RAMCLOUD_CLOG(...)
  - LOG(...)
  - DIE(...)

where the most common log statements are LOG followed by RAMCloud_LOG. Additionally, John Ousterhout says that RAMCLOUD_TEST_LOG is used for the unit tests only (i.e. they're not real logs) and should be omitted in the counting.

### Special Case: RAMCloud Server Id's
When we collected the dynamic argument type statistics, we were surprised that, though still not the majority, there were many %s specifiers. Upon closer inspection, we found that a large portion of the %s specifiers were for printing ServerId::toString().c_str(), which is a simple "%u.%u" printf to a string and can easily be incorporated in the original format string. Thus, we developed a heuristic to search for ServerId::toString().c_str() invocations and replaced its single %s with "%u.%u".

Luckily, the RAMCloud team had a convention with naming serverId variables with id's and nearly all of the usage cases can be caught by the simple regex "id.*\.toString\(\)\.c_str\(\)". There are a few cases such as in FailureDetector::168 where the ServerId is named "pingee", but a majority are caught. And checking as best as I can, it appears all the results are valid.

As a sanity check, NetBeans 8.2's "Find Usage" feature reports 171 usages of ServerId::toString as of RAMCloud commit 1c9072961b197d9ad8d52510b9e963fe65906744 and our script detects 144 in LOG, 4 in DIE, 2 in CLOG, 2 in RAMCLOUD_DIE, 5 in RAMCLOU_DLOG, 1 in TEST_LOG, making a total of 158; pretty close, only 7% off.

## Apache Httpd
There are 4 log statements that we target in Apache Httpd
 - ap_log_error(...)
 - ap_log_rerror(...)
 - ap_log_cerror(...)
 - ap_log_perror(...)

These functions are the recommened logging functions for Apache. Some modules do other sorts of logging (i.e printf, fprintf, apr_log...), but sampling the message, they appear to be either communicating to a remote http client or used in utility applications. Thus these functions are not counted.

Additionally, some of the format strings start with "APLOGNO(12345)" which is a macro that expands to "AH12345: " and have been replaced as such in the processed log messages.

### Caveats
The format string is officially the 5th argument for each of the functions above and the scripts match on that string. Apache does provide conveniene macros to fill in the first 4 arguments, but very few logs appear to use this convenience macro so these cases are not counted.

## Linux Kernel
The Linux Kernel contains many logging facilities; luckily, most of them are macros that eventually expand to ```printk```. So to support this expansion, the linux sources must first be preprocessed with ```gcc -E -Ilinux/include``` and then processed.

However, this introduces the issue of duplicating printk's in headers that are included in multiple source files. Thus, the linuxParser.py reverts to using the preprocessor's filename/linenumber directives to dedup log messages.

The log statements we search for are
 - printk(...)
 - dev_printk(?, ?, ...)
 - WARN_ONCE(?, ....)

### Caveats
It's worth noting that a popular macro (KBUILD_MODNAME) was left unexpanded in our analysis. It appears in about 20k logs, which means it would have a pretty big impact on the mean if we knew the value.