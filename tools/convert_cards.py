#!/usr/bin/py -3

import csv
import re
import requests

SHEET_LINK = 'https://docs.google.com/spreadsheets/d/1Phsnvq1xxomWa2HczMHFQZFKJmTKcUxro_WYmSAH5k4/export?format=csv'

print("Downloading cards...")

with requests.get(SHEET_LINK) as response:
  if response.status_code == 200:
    with open('cards.csv', 'wb') as f:
      f.write(response.content)
    print("Downloaded cards successfully!")
  else:
    print("Couldn't download cards sheet: ", response.status_code)


head = []
cards = []
lines = []

with open('cards.csv', newline='') as csvfile:
  reader = csv.reader(csvfile, delimiter=',', quotechar='"')
  cards = []
  
  for row in reader:
    cards += [row]
  
  head = cards[0]
  cards = cards[1:]
  
  lines += [ 'return {' ]
  
  for card in cards:
    lines += [ '  {' ]
    
    for idx, value in enumerate(card):
      if value:
        try:
          int(value)
        except:
          value = "'" + value.replace("'", "\\'") + "'"
        
        if head[idx] == 'title':
          # filter out html tags
          filtered = re.sub(r'<.+?>', '', value)
          
          if filtered != value:
            lines += [ f'    title_html = {value},' ]
            value = filtered
        
        lines += [ f'    {head[idx]} = {value},' ]
    
    lines += [ '  },' ]
  
  
  lines += [ '}' ]

with open('../lua/monopoly/generated_cards.lua', 'w') as luafile:
  luafile.write('\n'.join(lines))
