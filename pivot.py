#! /usr/bin/python


"""
Generates a PDF/CDF from the output of the parser

Usage:
    pivot.py [-h] YAXIS XAXIS VALUE FILE

Options:
  -h --help             Show this help messages

  YAXIS                 Column in the original file to use as the y-axis
                        Starts at 1

  XAXIS                 Column in the original file to use as the x-axis
                        Starts at 1

  VALUE                 Column in the original file to use as the value
                        Starts at 1

  FILE                  File to use

  OUTPUT_FILE           Output file to store results to
"""

import re
from docopt import docopt

if __name__ == "__main__":
  arguments = docopt(__doc__, version='Pivot v1')
  yaxis = int(arguments['YAXIS'])
  xaxis = int(arguments['XAXIS'])
  value = int(arguments['VALUE'])
  filename = arguments['FILE']

  maxColumns = max(yaxis, xaxis, value)
  regex = "\s*([^#][^\s]+)\s+" * maxColumns + ".*"

  rows = {}
  with open(arguments['FILE']) as iFile:
    for line in iFile.readlines():
      match = re.match(regex, line)
      if match:
        row = match.group(yaxis).strip()
        col = match.group(xaxis).strip()
        val = float(match.group(value).strip())

        if not row in rows:
          rows[row] = {}

        if not col in rows[row]:
          rows[row][col] = 0

        rows[row][col] += val

  maxLabelLength = 0
  uniqueKeys = []

  for row in rows.keys():
    uniqueKeys.extend(rows[row].keys())
    for col in rows[row].keys():
      maxLabelLength = max(maxLabelLength, len(col), len("%f" % rows[row][col]))
  uniqueKeys = sorted(set(uniqueKeys), key=int)


  output = "%-20s" % ("Label")
  fmt = (("%%%ds") % (maxLabelLength + 2))
  for key in uniqueKeys:
    output += fmt % key

  print output

  for row in rows.keys():
    output = "%-20s" % row
    for key in uniqueKeys:
      if key in rows[row]:
        output += fmt % rows[row][key]
      else:
        output += fmt % "0"
    print output




