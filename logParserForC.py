#! /usr/bin/python

# Copyright (c) 2016-2018 Stanford University
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR(S) DISCLAIM ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL AUTHORS BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""
C/C++ Parser

Usage:
    parser.py [-h]  [ --strictFmt ] [ --preprocessed ]
                    [ --serverIdFix ] [ --apacheApLogNoFix ]
                    LOG_FN FMT_INDEX ROOT_DIR

Options:
  -h --help             Show this help messages

  --serverIdFix         If enabled, attempts to replace all the RAMCloud "%s"
                        ServerId::toString().c_str() invocations with "%u.%u"
                        formatting instead.

  --strictFmt           Applies a stricter set of rules to the format string.
                        Without it, the parser will happily ignore unexpanded
                        macros and extraneous characters in the format string.

  --preprocessed        Indicates that the sources have been preprocessed by
                        the GNU Preprocessor and thus log messages should be
                        de-duplicated according to origin filename and line
                        number.

  --apacheApLogNoFix    If enabled, attempts to replace all Apache's statically
                        defined log markers (i.e. APLOGNO(0001)) to be apart of
                        the static strings

  LOG_FN                Log function to search for in the Java/Scala sources

  FMT_INDEX             Argument index for the format string in the LOG_FN
                        (starts at 0). For example, printf("%s", ...) would
                        have FMT_INDEX=0, fprintf(stderr, "%s", ...) would
                        have FMT_INDEX=1

  ROOT_DIR              Root directory of sources to scan for *scala and *java
                        source files and parse their LOG_FN's
"""


from parser import *
from functools import partial
from docopt import docopt
import re, os



def processCLog(serverIdReplacement, apacheLogNoFix, strictFmt, logStatement, format_index):
  fmtArg = logStatement['arguments'][format_index].source

  if apacheLogNoFix:
    fmtArg = re.sub("APLOGNO\(([\d]+)\)", "\"AH\\1: \"", fmtArg)

  # Fix all the PRIu64 references to "d". It's true this is a heuristic,
  # but it will pretty much catch all cases.
  fmtArg = re.sub("\" PRIu64 \"", "d", fmtArg)

  if strictFmt:
    fmtString = extractCString(fmtArg)
  else:
    fmtString = extractStaticPortionInQuotes(fmtArg)

  formatSpecifierRegex = "%" \
                         "(?P<flags>[-+ #0]+)?" \
                         "(?P<width>[\\d]+|\\*)?" \
                         "(\\.(?P<precision>\\d+|\\*))?" \
                         "(?P<length>hh|h|l|ll|j|z|Z|t|L)?" \
                         "(?P<specifier>[diuoxXfFeEgGaAcspn])"

  if not fmtString:
    return "# Error: Could not process %s" % fmtArg.replace("\n", "")

  numInts = 0
  numFloats = 0
  numString = 0
  numSpecial = 0

  dynaVars = re.findall(formatSpecifierRegex, fmtString)
  for specifier in dynaVars:
    if specifier[-1] in "diuoxX":
      numInts += 1
    elif specifier[-1] in "fFeEgGaA":
      numFloats += 1
    elif specifier[-1] in "s":
      numString += 1
    else:
      numSpecial += 1

  numDynaVars = len(dynaVars)
  numStaticChars = len(re.sub(formatSpecifierRegex, '', fmtString))

  if serverIdReplacement:
    numServerIds = 0
    serverIdRegex = ".*Id.*\.toString\(\)\.c_str\(\)"
    for argument in logStatement['arguments']:
      if re.match(serverIdRegex, argument.source,
                  re.IGNORECASE | re.MULTILINE | re.DOTALL):
        numServerIds = numServerIds + 1

    # Adjust for serverIds
    numStaticChars += numServerIds  # accounts for . in %u.%u
    numDynaVars += numServerIds  # Original %s plus 1 for %u

    assert (numString >= numServerIds)
    numString -= numServerIds  # Remove the %s count
    numInts += 2 * numServerIds  # Add 2 ints in their place

  return "%-4d %-4d %-4d %-4d %-4d %-4d %s" % (
    numStaticChars, numDynaVars,
    numInts, numFloats, numString, numSpecial,
    fmtString)


if __name__ == "__main__":
  arguments = docopt(__doc__, version='NanoLog Preprocesor v1.0')

  sourceFiles = []
  for dirpath, dirs, files in os.walk(arguments['ROOT_DIR']):
    for file in files:
      if file.endswith("c") or file.endswith("h") or file.endswith("cpp"):
        sourceFiles.append(os.path.join(dirpath, file))


  replaceServerIds = True if arguments["--serverIdFix"] else False
  apacheLogNoFix = True if arguments["--apacheApLogNoFix"] else False
  strictFmt = True if arguments["--strictFmt"] else False
  previouslyEncountered = {} if arguments["--preprocessed"] else None

  parseLogFn = partial(processCLog, replaceServerIds, apacheLogNoFix, strictFmt)
  print "# Static Dynamic Ints Floats String Special Filename:line: Format"
  for sourceFile in sourceFiles:
    processFile(sourceFile,
                arguments["LOG_FN"],
                int(arguments["FMT_INDEX"]),
                parseLogFn,
                previouslyEncountered)


