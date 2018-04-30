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
Memcached Parser

Usage:
    parser.py [-h] [ --serverIdFix ] LOG_FN FMT_INDEX ROOT_DIR

Options:
  -h --help             Show this help messages

  --serverIdFix         If enabled, attempts to replace all the RAMCloud "%s"
                        ServerId::toString().c_str() invocations with "%u.%u"
                        formatting instead.

  LOG_FN                Log function to search for in the Java/Scala sources

  FMT_INDEX             Argument index for the format string in the LOG_FN
                        (starts at 0). For example, printf("%s", ...) would
                        have FMT_INDEX=0, fprintf(stderr, "%s", ...) would
                        have FMT_INDEX=1

  ROOT_DIR              Root directory of sources to scan for *scala and *java
                        source files and parse their LOG_FN's
"""

from docopt import docopt
from collections import namedtuple
import sys, re, os

####
# Below are configuration parameters to be toggled by the library implementer
####

# Since header files are in-lined after the GNU preprocessing step, library
# files can be unintentionally processed. This list is a set of files that
# should be ignored
ignored_files = set([
])

####
# End library implementer parameters
####

# Simple structure to identify a position within a file via a line number
# and an offset on that line
FilePosition = namedtuple('FilePosition', ['lineNum', 'offset'])

# Encapsulates a function invocation's argument as the original source text
# and start/end FilePositions.
Argument = namedtuple('Argument', ['source', 'startPos', 'endPos'])

# Given a C/C++ style string in source code (i.e. in quotes), attempt to parse
# it back as a regular string. The source passed in can be multi-line (due to C
# string concatenation), but should not contain any extraneous characters
# outside the quotations (such as commas separating invocation parameters).
#
# \param source
#         C/C++ style string to extract
#
# \return
#         contents of the C/C++ string as a python string. None if
#         the lines did not encode a C/C++ style string.
def extractCString(source):
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
      else:
        if not (c.isspace() or c == "\\"):
          return None

  if isInQuotes:
    return None

  return returnString

# Attempt to extract a single argument in a C++ function invocation given
# the argument's start position (immediately after left parenthesis or comma)
# within a file.
#
# \param lines
#         all lines of the file
#
# \param startPosition
#         FilePosition denoting the start of the argument
#
# \return
#         an Argument namedtuple. None if it was unable to find the argument
#
def parseArgumentStartingAt(lines, startPos):

  # The algorithm uses the heuristic of assuming that the argument ends
  # when it finds a terminating character (either a comma or right parenthesis)
  # in a position where the relative parenthesis/curly braces/bracket depth is 0
  # The latter constraint prevents false positives where function calls are used
  # to generate the parameter (i.e. log("number is %d", calculate(a, b)))
  parenDepth = 0
  curlyDepth = 0
  bracketDepth = 0
  inQuotes = False
  argSrcStr = ""

  offset = startPos.offset
  for lineNum in range(startPos.lineNum, len(lines)):
    line = lines[lineNum]

    prevWasEscape = False
    for i in range(offset, len(line)):
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
      elif (c == "," or c == ")") and curlyDepth == 0 \
              and parenDepth == 0 and bracketDepth == 0:
        # found it!
        endPos = FilePosition(lineNum, i)
        return Argument(argSrcStr[:-1], startPos, endPos)

    # Couldn't find it on this line, must be on the next
    offset = 0

  return None


# Given the starting position of a LOG_FUNCTION, attempt to identify
# all the syntactic components of the LOG_FUNCTION (such as arguments and
# ending semicolon) and their positions in the file
#
# \param lines
#             all the lines of the file
# \param startPosition
#             tuple containing the line number and offset where
#             the LOG_FUNCTION starts within lines
#
# \return a dictionary with the following values:
#         'startPos'        - FilePosition of the LOG_FUNCTION
#         'openParenPos'    - FilePosition of the first ( after LOG_FUNCTION
#         'closeParenPos'   - FilePosition of the closing )
#         'semiColonPos'    - FilePosition of the function's semicolon
#         'arguments'       - List of Arguments for the LOG_FUNCTION
#
# \throws ValueError
#         When parts of the LOG_FUNCTION cannot be found
#
def parseLogStatement(lines, startPosition, log_function):
  lineNum, offset = startPosition
  assert lines[lineNum].find(log_function, offset) == offset

  # Find the left parenthesis after the LOG_FUNCTION identifier
  offset += len(log_function)
  char, openParenPos = peekNextMeaningfulChar(lines, FilePosition(lineNum, offset))
  lineNum, offset = openParenPos

  # This is an assert instead of a ValueError since the caller should ensure
  # this is a valid start to a function invocation before calling us.
  assert(char == "(")

  # Identify all the argument start and end positions
  args = []
  while lines[lineNum][offset] != ")":
    offset = offset + 1
    startPos = FilePosition(lineNum, offset)
    arg = parseArgumentStartingAt(lines, startPos)
    if not arg:
      raise ValueError("Cannot find end of NANO_LOG invocation",
                       lines[startPosition[0]:startPosition[0]+5])
    args.append(arg)
    lineNum, offset = arg.endPos

  closeParenPos = FilePosition(lineNum, offset)

  # # To finish this off, find the closing semicolon
  # semiColonPeek =  peekNextMeaningfulChar(lines, FilePosition(lineNum, offset + 1))
  # if not semiColonPeek:
  #   raise ValueError("Expected ';' after NANO_LOG statement",
  #                    lines[startPosition[0]:closeParenPos.lineNum])

  # char, pos = semiColonPeek
  # if (char != ";"):
  #   raise ValueError("Expected ';' after NANO_LOG statement",
  #                  lines[startPosition[0]:pos[0]])

  logStatement = {
      'startPos': startPosition,
      'openParenPos': openParenPos,
      'closeParenPos': closeParenPos,
      'semiColonPos': closeParenPos,
      'arguments': args,
  }

  return logStatement

# Helper function to peekNextMeaningfulCharacter that determines whether
# a character is a printable character (like a-z) vs. a control code
#
# \param c - character to test
# \param codec - character type (optional)
#
# \return - true if printable, false if not
def isprintable(c, codec='utf8'):
  try: c.decode(codec)
  except UnicodeDecodeError: return False
  else: return True

# Given a start FilePosition, find the next valid character that is
# syntactically important for the C/C++ program and return both the character
# and FilePosition of that character.
#
# \param lines      - lines in the file
# \param filePos    - FilePosition of where to start looking
# \return           - a (character, FilePosition) Tuple; None if no such
#                       character exists (i.e. EOF)
#
def peekNextMeaningfulChar(lines, filePos):
  lineNum, offset = filePos

  while lineNum < len(lines):
    line = lines[lineNum]
    while offset < len(line):
      c = line[offset]
      if isprintable(c) and not c.isspace():
        return (c, FilePosition(lineNum, offset))
      offset = offset + 1
    offset = 0
    lineNum = lineNum + 1

  return None

# Given a C/C++ source file that have been preprocessed by the GNU
# preprocessor with the -E option, identify all the NanoLog log statements
# and inject code in place of the statements to interface with the NanoLog
# runtime system. The processed files will be outputted as <filename>i
# (ex: test.i -> test.ii)
#
# \param functionGenerator
#           FunctionGenerator used to generate interface code
#           and maintain mappings
#
# \param inputFiles
#           list of g++ preprocessed C/C++ files to analyze
#
def processFile(inputFile, format_index,
                log_function,
                serverIdReplacement,
                totalServerIds):
  with open(inputFile) as f:
    try:
      lines = f.readlines()
      lineIndex = -1

      lastChar = '\0'

      # Logical location in a file based on GNU Preprocessor directives
      ppFileName = inputFile
      ppLineNum = 0

      # Notes the first filename referenced by the pre-processor directives
      # which should be the name of the file being compiled.
      firstFilename = None

      # Marks at which line the preprocessor can start safely injecting
      # generated, inlined code. A value of None indicates that the NanoLog
      # header was not #include-d yet
      inlineCodeInjectionLineIndex = None

      # Scan through the lines of the file parsing the preprocessor directives,
      # identfying log statements, and replacing them with generated code.
      while lineIndex < len(lines) - 1:
        lineIndex = lineIndex + 1
        line = lines[lineIndex]

        # Keep track of of the preprocessor line number so that we can
        # put in our own line markers as we inject code into the file
        # and report errors. This line number should correspond to the
        # actual user source line number.
        ppLineNum = ppLineNum + 1

        # Parse special preprocessor directives that follows the format
        # '# lineNumber "filename" flags'
        directive = re.match("^# (\d+) \"(.*)\"(.*)", line)
        if directive:
            # -1 since the line num describes the line after it, not the
            # current one, so we decrement it here before looping
            ppLineNum = int(float(directive.group(1))) - 1

            ppFileName = directive.group(2)
            if not firstFilename:
                firstFilename = ppFileName

            flags = directive.group(3).strip()
            continue

        if ppFileName in ignored_files:
            continue

        # Scan for instances of the LOG_FUNCTION using a simple heuristic,
        # which is to search for the LOG_FUNCTION outside of quotes. This
        # works because at this point, the file should already be pre-processed
        # by the C/C++ preprocessor so all the comments have been stripped and
        # all #define's have been resolved.
        prevWasEscape = False
        inQuotes = False
        charOffset = -1

        while charOffset < len(line) - 1:
          charOffset = charOffset + 1
          c = line[charOffset]

          # If escape, we don't really care about the next char
          if c == "\\" or prevWasEscape:
            prevWasEscape = not prevWasEscape
            lastChar = c
            continue

          if c == "\"":
            inQuotes = not inQuotes

          # If we match the first character, cheat a little and scan forward
          if c == log_function[0] and not inQuotes:
            # Check if we've found the log function via the following heuristics
            #  (a) the next n-1 characters spell out the rest of LOG_FUNCTION
            #  (b) the previous character was not an alpha numeric (i.e. not
            #       a part of a longer identifier name)
            #  (c) the next syntactical character after log function is a (
            found = True
            for ii in range(len(log_function)):
              if line[charOffset + ii] != log_function[ii]:
                found = False
                break

            if not found:
              continue

            # Valid identifier characters are [a-zA-Z_][a-zA-Z0-9_]*
            if lastChar.isalnum() or lastChar == '_':
              continue

            # Check that it's a function invocation via the existence of (
            filePosAfter = FilePosition(lineIndex, charOffset + len(log_function))
            mChar, mPos = peekNextMeaningfulChar(lines, filePosAfter)
            if mChar != "(":
              continue

            # Okay at this point we are pretty sure we have a genuine
            # log statement, parse it and start modifying the code!
            logStatement = parseLogStatement(lines, (lineIndex, charOffset), log_function)
            lastLogStatementLine = logStatement['semiColonPos'].lineNum

            if len(logStatement['arguments']) < format_index + 1:
              raise ValueError("NANO_LOG statement expects at least %d arguments"
                                 ": a LogLevel and a literal format string",
                                 format_index + 1,
                                 lines[lineIndex:lastLogStatementLine + 1])

            # We expect the log invocation to have the following format:
            # LOG_FN(LogLevel, FormatString, ...), hence the magic indexes
            fmtArg = logStatement['arguments'][format_index]
            fmtString = extractCString(fmtArg.source)

            formatSpecifierRegex = "%" \
                   "(?P<flags>[-+ #0]+)?" \
                   "(?P<width>[\\d]+|\\*)?" \
                   "(\\.(?P<precision>\\d+|\\*))?" \
                   "(?P<length>hh|h|l|ll|j|z|Z|t|L)?" \
                   "(?P<specifier>[diuoxXfFeEgGaAcspn])"

            # print fmtString
            if fmtString:
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
                  numSpecial +=1

              numDynaVars = len(dynaVars)
              numStaticChars = len(re.sub(formatSpecifierRegex, '', fmtString))

              if serverIdReplacement:
                numServerIds = 0
                serverIdRegex = ".*Id.*\.toString\(\)\.c_str\(\)"
                for argument in logStatement['arguments']:
                  if re.match(serverIdRegex, argument.source, re.IGNORECASE | re.MULTILINE | re.DOTALL):
                    numServerIds = numServerIds + 1

                # Adjust for serverIds
                numStaticChars += numServerIds # accounts for . in %u.%u
                numDynaVars += numServerIds # Original %s plus 1 for %u

                assert(numString >= numServerIds)
                numString -= numServerIds # Remove the %s count
                numInts += 2*numServerIds  # Add 2 ints in their place
                totalServerIds += numServerIds

              print "%-4d %-4d %-4d %-4d %-4d %-4d %s:%d: %s" % (
                  numStaticChars, numDynaVars,
                  numInts, numFloats, numString, numSpecial,
                  inputFile, lineIndex, fmtString)
            else:
              print "# Error: Could not process %s:%d %s" % (
                inputFile, lineIndex, line)

          lastChar = c
    except ValueError as e:
        print "# Error: Could not process %s:%d %s" % (
                inputFile, lineIndex, line)

    return totalServerIds

if __name__ == "__main__":
  arguments = docopt(__doc__, version='NanoLog Preprocesor v1.0')

  sourceFiles = []
  for dirpath, dirs, files in os.walk(arguments['ROOT_DIR']):
    for file in files:
      sourceFiles.append(os.path.join(dirpath, file))


  replaceServerIds = True if arguments["--serverIdFix"] else False

  totalServerIds = 0
  print "# Static Dynamic Ints Floats String Special Filename:line: Format"
  for sourceFile in sourceFiles:
    totalServerIds = processFile(sourceFile, int(arguments["FMT_INDEX"]),
                                 arguments["LOG_FN"],
                                 replaceServerIds,
                                 totalServerIds)

  print "# Found %d serverId strings" % totalServerIds


