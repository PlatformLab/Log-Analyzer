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

"""Spark Parser

Scans through a directory containing Java/Scala source files and attempts to
extract statistics.

Usage:
    parser.py [-h] LOG_FN ROOT_DIR

Options:
  -h --help             Show this help messages

  LOG_FN                Log function to search for in the Java/Scala sources

  ROOT_DIR              Root directory of sources to scan for *scala and *java
                        source files and parse their LOG_FN's
"""

from parser import *
from docopt import docopt
import re, os

####
# Below are configuration parameters to be toggled by the library implementer
####

# Since header files are in-lined after the GNU preprocessing step, library
# files can be unintentionally processed. This list is a set of files that
# should be ignored
ignored_files = set([
])


# Given a Java/Scala string that is (optionally) formatted with a .format(...),
# extract the characters in the quotes before the .format(...) invocation. This
# function can handle the special case of multi-formats
# (i.e. ("s1" + "s2").format(...))
#
# \param source
#         Java/Scala string to process
# \return
#         A single string of the characters contained with the quotes
def extractJavaFmtString(source):
  returnString = ""
  isInQuotes = False
  prevWasEscape = False

  for line in source.splitlines(True):
    for c in line:
      if c == "\"" and not prevWasEscape:
        isInQuotes = not isInQuotes
      elif isInQuotes:
        returnString += c
        prevWasEscape = c == "\\"
      elif c == '.' or c == ')':
        break

  return returnString

# Separate a log statement into its constituent parts joined by +
def separateLogFragments(line):
  # The algorithm uses the heuristic of assuming that the argument ends
  # when it finds a terminating character (either a + or right parenthesis)
  # in a position where the relative parenthesis/curly braces/bracket depth is 0
  # The latter constraint prevents false positives where function calls are used
  # to generate the parameter (i.e. log("number is %d", calculate(a, b)))
  parenDepth = 0
  curlyDepth = 0
  bracketDepth = 0
  inQuotes = False
  argSrcStr = ""


  prevWasEscape = False
  fragments = []
  for i in range(len(line)):
    c = line[i]
    argSrcStr = argSrcStr + c

    # If it's an escape, we don't care what comes after it
    if c == "\\" or prevWasEscape:
      prevWasEscape = not prevWasEscape
      continue

    # Start counting depths
    if c == "\"":
      inQuotes = not inQuotes

    # Don't count curlies and parenthesis when in quotes
    if inQuotes:
      continue

    if c == "{":
      curlyDepth = curlyDepth + 1
    elif c == "}":
      curlyDepth = curlyDepth - 1
    elif c == "(":
      parenDepth = parenDepth + 1
    elif c == ")" and parenDepth > 0:
      parenDepth = parenDepth - 1
    elif c == "[":
      bracketDepth = bracketDepth + 1
    elif c == "]":
      bracketDepth = bracketDepth - 1
    elif (c == "+" or c == ")") and curlyDepth == 0 \
            and parenDepth == 0 and bracketDepth == 0:
      # found it
      fragments.append(argSrcStr[:-1].strip())
      argSrcStr = ""

  argSrcStr = argSrcStr.strip()
  if len(argSrcStr) > 0:
    fragments.append(argSrcStr)

  return fragments

def processScalaLog(logStatement, format_index):
  formatArgument = logStatement['arguments'][format_index].source
  totalStaticChars = 0
  totalDynaVars = 0

  completeLog = ""
  fmtOutput = "\t#%-4d %-4d %-15s %s" # static chars, dynaArgs, type, fragment

  inlineVarRegex = r'\$(\{[^\}]+}|[a-zA-Z0-9]+)'
  formatSpecifierRegex = "%" \
             "(?P<flags>[-+ #0]+)?" \
             "(?P<width>[\\d]+|\\*)?" \
             "(\\.(?P<precision>\\d+|\\*))?" \
             "(?P<length>hh|h|l|ll|j|z|Z|t|L)?" \
             "(?P<specifier>[diuoxXfFeEgGaAcspn])"


  for fragment in separateLogFragments(formatArgument):
    isSubstitution = fragment[0] == 's'

    # Handle the triple quote case since it's the easiest.
    if fragment.startswith("s\"\"\"") \
            or fragment.startswith("\"\"\"") \
            or fragment.startswith("(\"\"\""):

      # This is currently an unhandled case, so we just error
      assert(fragment[0] != '(')

      # Rip out the googy center of the triple quotes """
      assert(len(re.findall("\"\"\"", fragment)) == 2)
      begin = fragment.index("\"\"\"") + 3
      end = fragment.index("\"\"\"", begin)
      fragment = fragment[begin:end].replace("\n", "")

      # Count the types
      if(isSubstitution):
        numDynaVars = len(re.findall(inlineVarRegex, fragment))
        numStaticChars = len(re.sub(inlineVarRegex, '', fragment))
      else:
        numDynaVars = len(re.findall(formatSpecifierRegex, fragment))
        numStaticChars = len(re.sub(formatSpecifierRegex, '', fragment))

    # Detect substitions (i.e. s"Hello $user")
    elif isSubstitution:
      fragment = fragment[2:-1] # remove the s""
      numDynaVars = len(re.findall(inlineVarRegex, fragment))
      numStaticChars = len(re.sub(inlineVarRegex, '', fragment))
      # print fmtOutput % (numStaticChars, numDynaVars, "Substitution", fragment)

    # Detect "static string" or "Format".format(..) or ("" + "").format()
    elif fragment[0] == '\"' or fragment[0] == '(':
      fragment = extractJavaFmtString(fragment)
      numDynaVars = len(re.findall(formatSpecifierRegex, fragment))
      numStaticChars = len(re.sub(formatSpecifierRegex, '', fragment))
      # print fmtOutput % (numStaticChars, numDynaVars, "Format", fragment)

    # They are just variables, i.e. logInfo(variable)
    else:
      numDynaVars = 1
      numStaticChars = 0
      fragment = "v:{" + fragment.replace("\n", "") + "}"
      # print fmtOutput %(numStaticChars, numDynaVars, "Variable", fragment)

    completeLog += fragment
    totalStaticChars += numStaticChars
    totalDynaVars += numDynaVars

  return "%-4d %-4d %-4d %-4d %-4d %-4d %s" % (totalStaticChars, totalDynaVars,
                                              0,0,0,0,
                                              completeLog)

if __name__ == "__main__":
  arguments = docopt(__doc__, version='Scala/Java Preprocesor v0.1')

  sourceFiles = []
  for dirpath, dirs, files in os.walk(arguments['ROOT_DIR']):
    for file in files:
      if file.endswith("scala") or file.endswith("java"):
        sourceFiles.append(os.path.join(dirpath, file))

  print "# Static Dynamic Ints Floats String Special Format"
  print "# Note Int/FLoats/String/Special are always 0"
  for sourceFile in sourceFiles:
    processFile(sourceFile, arguments["LOG_FN"], 0, processScalaLog)