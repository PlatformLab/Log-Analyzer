#! /usr/bin/python

"""
PDF Generator
Usage:
    parser.py [-h] FILE OUTPUT_FILE

Options:
  -h --help             Show this help messages

  FILE                  File to use

  OUTPUT_FILE           Output file to store results to
"""

import re
from docopt import docopt

if __name__ == "__main__":
  arguments = docopt(__doc__, version='PDF/CDF Generator v1')
  filename = arguments['FILE']
  outputFile = arguments['OUTPUT_FILE']

  numLogs = 0
  totalInts = 0
  totalFloats = 0
  totalStrings = 0
  totalSpecials = 0
  totalStaticChars = 0

  pattern = re.compile("(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.+)")
  with open(filename) as iFile, open(outputFile, 'w') as oFile:

    staticChars2Count = {}

    dnyaVarsCount = {}
    dynaVars2staticTotal = {}
    dynaVars2Ints = {}
    dynaVars2Floats = {}
    dynaVars2Strings = {}
    dynaVars2Special = {}

    for line in iFile.readlines():
      if line[0] == '#':
        continue

      match = pattern.match(line)
      if match:
        staticChars = int(match.group(1))
        dynaVars    = int(match.group(2))
        numInts     = int(match.group(3))
        numFloats   = int(match.group(4))
        numStrings  = int(match.group(5))
        numSpecial  = int(match.group(6))
        logStr      = match.group(7)

        if not staticChars2Count.get(staticChars):
          staticChars2Count[staticChars] = 0

        if not dnyaVarsCount.get(dynaVars):
          dnyaVarsCount[dynaVars] = 0
          dynaVars2staticTotal[dynaVars] = 0
          dynaVars2Ints[dynaVars] = 0
          dynaVars2Floats[dynaVars] = 0
          dynaVars2Strings[dynaVars] = 0
          dynaVars2Special[dynaVars] = 0

        staticChars2Count[staticChars] += 1
        dnyaVarsCount[dynaVars] += 1
        dynaVars2staticTotal[dynaVars] += staticChars
        dynaVars2Ints[dynaVars] += numInts
        dynaVars2Floats[dynaVars] += numFloats
        dynaVars2Strings[dynaVars] += numStrings
        dynaVars2Special[dynaVars] += numSpecial

        numLogs += 1
        totalInts += numInts
        totalFloats += numFloats
        totalStrings += numStrings
        totalSpecials += numSpecial
        totalStaticChars += staticChars



    oFile.write("# %-8s%-10s%-10s\r\n" % ("Key", "PDF", "CDF"))

    totalCount = 0
    totalBytes = 0

    numStaticChars = staticChars2Count.keys()
    numStaticChars.sort(key=int)
    for staticChars in numStaticChars:
      count = staticChars2Count[staticChars]
      totalCount += int(count)
      totalBytes += int(staticChars)*int(count)
      oFile.write("%-10s%-10s%-10d\r\n" % (staticChars, count, totalCount))

    print ""
    print "%-30s: Average log length was %.2lf characters per message" % (filename, totalBytes*1.0/totalCount)
    for dynaVars in dnyaVarsCount.keys():
      totalStatic = dynaVars2staticTotal[dynaVars]
      count = 1.0*dnyaVarsCount[dynaVars]

      totalDynaTypes = 0.01*(dynaVars2Ints[dynaVars] + dynaVars2Floats[dynaVars] + dynaVars2Strings[dynaVars] + dynaVars2Special[dynaVars])
      if totalDynaTypes == 0:
        totalDynaTypes = 0.01 # Avoids division by 0
      print "\t For %-2d dynamic variables, average static was %5.1lf (%4d/%4d) " \
            "=> %3.0lf%% %3d Ints %3.0lf%% %3d Floats %3.0lf%% %3d Strings %3.0lf%% %3d Others" % (
        dynaVars, totalStatic/count, totalStatic, count,
        dynaVars2Ints[dynaVars] / totalDynaTypes,
        dynaVars2Ints[dynaVars],
        dynaVars2Floats[dynaVars] / totalDynaTypes,
        dynaVars2Floats[dynaVars],
        dynaVars2Strings[dynaVars] / totalDynaTypes,
        dynaVars2Strings[dynaVars],
        dynaVars2Special[dynaVars] / totalDynaTypes,
        dynaVars2Special[dynaVars])
    print "Total number of log statements processed is %u" % numLogs
    print "Average log message has %.2lf static characters/message, %5.2lf ints %5.2lf floats %5.2lf strings and %5.2lf specials" % (
        totalStaticChars*1.0/numLogs,
        totalInts*1.0/numLogs,
        totalFloats*1.0/numLogs,
        totalStrings*1.0/numLogs,
        totalSpecials*1.0/numLogs,
        )



