#!/usr/bin/env python3

import csv
import sys
from post_process import gen_new_url

date_title_csv = sys.argv[1]
output_csv = sys.argv[2]

old_base_url = "/blog/"

date_title_dict = {}
with open(date_title_csv) as f:
    reader = csv.reader(f)
    for row in reader:
        date_title_dict[row[0]] = row[1]

with open(output_csv, 'w') as f:
    writer = csv.writer(f)
    for date in date_title_dict.keys():
        old_url = old_base_url + '?date=' + date
        new_url = gen_new_url(old_url, date_title_dict)
        writer.writerow([old_url, new_url])

