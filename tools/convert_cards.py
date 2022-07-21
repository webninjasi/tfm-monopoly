#!/usr/bin/py -3

import csv

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
  
  lines += [ 'monopoly.config.board.cells = {' ]
  
  for card in cards:
    lines += [ '  {' ]
    
    for idx, value in enumerate(card):
      if value:
        try:
          int(value)
          lines += [ f'    {head[idx]} = {value},' ]
        except:
          lines += [ f'    {head[idx]} = \'{value}\',' ]
    
    lines += [ '  },' ]
  
  
  lines += [ '}' ]

with open('../lua/monopoly/generated_cards.lua', 'w') as luafile:
  luafile.write('\n'.join(lines))
