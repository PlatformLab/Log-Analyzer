#! /usr/bin/python

"""
PDF Generator
Usage:
    parser.py [-h] FILE COLUMN OUTPUT_FILE

Options:
  -h --help             Show this help messages

  FILE                  File to use

  COLUMN                Column to generate pdf on

  OUTPUT_FILE           Output file to store results to
"""

from docopt import docopt
if __name__ == "__main__":
  arguments = docopt(__doc__, version='PDF/CDF Generator v1')
  filename = arguments['FILE']
  column = int(arguments['COLUMN'])
  outputFile = arguments['OUTPUT_FILE']

  histogram = {}
  with open(filename) as iFile, open(outputFile, 'w') as oFile:
    for line in iFile.readlines():
      if line[0] == '#':
        continue

      key = line.split()[column].strip()
      if not histogram.get(key):
        histogram[key] = 0

      histogram[key] = histogram[key] + 1

    oFile.write("# %-8s%-10s%-10s\r\n" % ("Key", "PDF", "CDF"))

    totalCount = 0
    totalBytes = 0

    keys = histogram.keys()
    keys.sort(key=int)
    for key in keys:
      value = histogram[key]
      totalCount += int(value)
      totalBytes += int(key)*int(value)
      oFile.write("%-10s%-10s%-10d\r\n" % (key, value, totalCount))

    print ""
    print "%-30s: Average log length was %.2lf characters per message" % (filename, totalBytes*1.0/totalCount)



