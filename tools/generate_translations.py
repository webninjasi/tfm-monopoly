#!/usr/bin/py -3

import csv
import re
import requests

SHEET_LINK = 'https://docs.google.com/spreadsheets/d/1r7qHDy_qu1DBxr3t48Ml0nnztrI89EiBTeRImLTWY84/export?format=csv'

lines = []


print("Downloading new translations...")

with requests.get(SHEET_LINK) as response:
  if response.status_code == 200:
    with open('translations.csv', 'wb') as f:
      f.write(response.content)
    print("Downloaded translations successfully!")
  else:
    print("Couldn't download translations sheet: ", response.status_code)


print("Generating new translations file for lua...")
with open('translations.csv', newline='', encoding="utf8") as csvfile:
  reader = csv.reader(csvfile, delimiter=',', quotechar='"')
  head = None
  languages = {}
  
  # read csv row by row
  for row in reader:
    if head:
      tvars = []
      
      # read translated strings
      for i, value in enumerate(row):
        if i != 0:
          if value:
            value = value.replace('"', '\\"').replace('\t', '\\t"').replace('\n', '\\n"')
            
            if '{' in value and '}' in value:
              # save parameters from english translations
              if i == 1:
                tvars = re.findall(r'\{(.+?)\}', value)
              
              # create a function that generates a translation with parameters
              value = 'function(' + ', '.join(tvars) + ') return _concat({ "' + re.sub(r'\{(.+?)\}', r'", \1, "', value) + '" }) end'
            else:
              value = f'"{value}"'
            
            languages[head[i]][row[0]] = value
          elif i != 1:
            # fill in empty cells with english
            languages[head[i]][row[0]] = languages[head[1]][row[0]]
    else:
      # save language names (first row)
      head = row
      
      for i, lang in enumerate(row):
        if i != 0:
          languages[lang] = {}
  
  # convert to lua
  lines += [ 'local _concat = table.concat' ]
  lines += [ 'return {' ]
  
  for lang, translations in languages.items():
    lines += [ f'  ["{lang.strip()}"] = {{' ]
    
    for key, value in translations.items():
      if value:
        lines += [ f'    ["{key.strip()}"] = {value},' ]
    
    lines += [ '  },' ]
  
  lines += [ '}' ]

with open('../lua/monopoly/generated_translations.lua', 'w', encoding="utf8") as luafile:
  luafile.write('\n'.join(lines))
  print("Generated translations file successfully!")
