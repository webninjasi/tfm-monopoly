#!/usr/bin/py -3

import csv
import re
import requests

SHEET_LINK = 'https://docs.google.com/spreadsheets/d/1r7qHDy_qu1DBxr3t48Ml0nnztrI89EiBTeRImLTWY84/export?format=csv'
OUTPUT_FILE = '../lua/monopoly/generated_translations.lua'

lines = []


print("Downloading new translations...")

with requests.get(SHEET_LINK) as response:
  if response.status_code == 200:
    with open('translations.csv', 'wb') as f:
      f.write(response.content)
    print("Downloaded translations successfully!")
  else:
    print("Couldn't download translations sheet: ", response.status_code)


def replace_param(match):
  param = match.group(1)

  if param[0] == '$':
    return f'", _translate({param[1:]}, _target), "'

  elif param[0] == '#':
    return f'######{param[1:]}######'

  elif param[0] == '!':
    return f'", _translate("{param[1:]}", _target, {param[1:]}), "'

  return f'", {param}, "'

def replace_param2(match):
  param = match.group(1)

  if param[0] == '#':
    param = f'######{param[1:]}######'

  return param

def replace_trans(translations):
  def replacer(match):
    param = match.group(1)

    if param in translations:
      return translations[param][1:-1]

    return f'######{param}######'
    
  return replacer


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
        if i == 1:
          tvars = value.split('|')

        elif i != 0:
          if value:
            value = value.replace('"', '\\"').replace('\t', '\\t').replace('\n', '\\n')

            if len(tvars) > 0 and tvars[0]:
              # create a function that generates a translation with parameters
              fvalue = 'function(_translate, _target, '
              fvalue += ', '.join(tvars)
              fvalue += ') return _concat({ "'
              fvalue += re.sub(r'\{(.+?)\}', replace_param, value)
              fvalue += '" }) end'
              value = fvalue

            elif '{' in value and '}' in value:
              value = re.sub(r'\{(.+?)\}', replace_param2, value)
              value = f'"{value}"'

            else:
              value = f'"{value}"'

            languages[head[i]][row[0]] = value

          elif i != 2:
            # fill in empty cells with english
            languages[head[i]][row[0]] = languages[head[2]][row[0]]

    else:
      # save language names (first row)
      head = row

      for i, lang in enumerate(row):
        if i > 1:
          languages[lang] = {}
  
  # convert to lua
  lines += [ 'local _concat = table.concat' ]
  lines += [ 'return {' ]
  
  for lang, translations in languages.items():
    lines += [ f'  ["{lang.strip()}"] = {{' ]
    replacer = replace_trans(translations)
    
    for key, value in translations.items():
      if value:
        value = re.sub(r'\#\#\#\#\#\#(.+?)\#\#\#\#\#\#', replacer, value)
        lines += [ f'    ["{key.strip()}"] = {value},' ]
    
    lines += [ '  },' ]
  
  lines += [ '}' ]

with open(OUTPUT_FILE, 'w', encoding="utf8") as luafile:
  luafile.write('\n'.join(lines))
  print("Generated translations file successfully!")
