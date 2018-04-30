# Log Analyzer
This repository contains a series of scripts to search for all log messages in Spark, memcached, and RAMCloud and count the number of static characters in their log messages vs. the number of dynamic ones.

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