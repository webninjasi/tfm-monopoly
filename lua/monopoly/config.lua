--- monopoly.config

local config = {}

config.bgcolor = "#515d5a"
config.mapXML = [[
<C>
  <P H="1000" MEDATA=";;;;-0;0:::1-"/>
  <Z>
    <S>
      <S T="12" X="400" Y="0" L="800" H="10" P="0,0,0.3,0,0,0,0,0" o="324650" m=""/>
      <S T="12" X="0" Y="500" L="1000" H="10" P="0,0,0.3,0,90,0,0,0" o="324650" m=""/>
      <S T="12" X="400" Y="810" L="800" H="10" P="0,0,0.3,0,0,0,0,0" o="324650" m=""/>
      <S T="12" X="800" Y="500" L="1000" H="10" P="0,0,0,0,90,0,0,0" o="324650" m=""/>
      <S T="12" X="400" Y="800" L="800" H="10" P="0,0,0.3,0,0,0,0,0" o="324650" c="3" m=""/>
      <S T="12" X="400" Y="855" L="800" H="10" P="0,0,0.3,0,0,0,0,0" o="324650" m=""/>
      <S T="12" X="400" Y="210" L="800" H="10" P="0,0,0.3,0,0,0,0,0" o="324650" c="3" m=""/>
      <S T="12" X="115" Y="500" L="1000" H="10" P="0,0,0.3,0,90,0,0,0" o="324650" c="3" m=""/>
      <S T="12" X="685" Y="500" L="1000" H="10" P="0,0,0,0,90,0,0,0" o="324650" c="3" m=""/>
    </S>
    <D>
      <DS X="400" Y="455"/>
    </D>
    <O/>
    <L/>
  </Z>
</C>
]]


-- dice spawn offsets
config.dice = {
  off1 = { x = -40, y = 0 },
  off2 = { x = 40, y = 0 },

  x1 = 110, x2 = 690,
  y1 = 110, y2 = 690,
  offset = 70,

  delay = 2000, -- duration of the dice roll animation
}

config.tokenColors = {
  0xff00ff,
  0x00ffff,
  0xff0000,
  0x00ff00,
  0x0000ff,
  0xffff00,
  0xFFA500,
  0xC0C0C0,
  0xA52A2A,
  0x99737a,
}

config.playersUI = {
  x = 210,
  y = 175,
  offx = -10,
  offy = 36,
  inity = 27,
}

config.logsUI = {
  x = 135,
  y = 500,
  width = 380,
  lines = 10, -- 2000/10 = ~200 chars per line
}

config.auctionUI = {
  x = 234 + 50,
  y = 100 + 200,
}

config.tradeUI = {
  x = 234,
  y = 100 + 200,
}

config.gameTime = {
  dice = 10,
  property = 20,
  play = 60,
  auction = 30,
  auctionBid = 5,
  trading = 30,
}

config.images = {
  background = "182cbf83510.png",
  circle = "182144f123d.png",
  house = "182dbcf91cb.png",
  hotel = "182dbcfe6ab.png",
  mortgaged = "18227e5d7b4.png",
  mortgage = "182e69f4a5a.png",
  unmortgage = "182e69f9dc1.png",
  buy_house = "182d6e03a58.png",
  sell_house = "182d6e09428.png",
  tokensbg = "182cbf45136.png",
  ui = "182a637db2c.png",
  popup = "182ec0c077f.png",
  cards = {
    empty = "18220bf6da4.png",
    chance = "18220c02228.png",
    community = "18220bfcef2.png",
    water = "181f075f65a.png",
    electric = "181f076425d.png",
    train = "181f0768e5c.png",
    
    go = "18221958959.png",
    gojail = "1822338d615.png",
    jail = "182cbf6aa63.png",
    afkvillage = "18223387796.png",
    chance2 = "18221945952.png",
    community2 = "1822194a55a.png",

    luxury_tax = "182e5ffae83.png",
    income_tax = "182e60000d3.png",
  },
  pixels = {
    red = "17948d9ecc2.png",
    green = "17948da0435.png",
    blue = "17948da1ba8.png",
    black = "17948da3319.png",
    white = "17948da4a89.png",
  },
  dices = {
    "181d6e0712b.png",
    "181d6e0bd5c.png",
    "181d6e1095b.png",
    "181d6e1555f.png",
    "181d6e1a15b.png",
    "181d6e1ed5a.png",
  },
  tokens = {
    {"181f074c65c.png", 50, 31},
    {"181f0742e5c.png", 43, 28},
    {"181f0747a5b.png", 46, 28},
    {"181f073e25d.png", 60, 28},
    {"181f075125b.png", 28, 36},
    {"181f0755e5c.png", 50, 34},
    {"182072a2a0a.png", 50, 30},
    {"182072a7e6a.png", 50, 26},
    {"1820f864577.png", 50, 30},
    {"1821023e89f.png", 40, 50},
  },
  actionui = {
    x = 200, y = 365,
    w = 50, h = 50,
    sep = 10,
    taw = 40, tah = 40,

    {"JailCard", "182a6388113.png", true},
    {"JailPay", "182a6382f66.png", true},
    {"Dice", "181f077be5d.png"},
    {"Cards", "181f076da5c.png"},
    {"Build", "181f077265d.png"},
    {"Trade", "181f0780a5c.png"},
    {"Stop", "181f077725b.png"},
  },
  emoticons = {
    { "16f56cbc4d7.png" },
    { "16f56cdf28f.png" },
    { "17aa1491af1.png" },
    { "16f56d09dc2.png" },
    { "16f5d8c7401.png" },
    { "17088661168.png" },
    { "16f56ce925e.png" },
    { "1831d9ef9cf.png" },
    { "1831d9f465c.png" },
    { "1831d9f925d.png" },
    { "1831d9fde5e.png" },
    { "1831da02a60.png" },
    { "1831da0765e.png" },
    { "1831da0c25e.png" },
    { "1831da10e5f.png" },
  },
}

config.emoticon = {
  x = 630, y = 185,
  duration = 4500,
}

-- tokens default position
config.tokens = {
  imgX = 400,
  imgY = 215+200,
  defaultX = 400,
  defaultY = 150+200,
  rowItems = 5,
  colorsOffset = 33,
}

-- board configs
config.board = {}

-- height of houses to place on top of properties
config.board.houseSize = 20

-- upper bar height
config.board.offset = 30

-- property positions in clockwise order
config.board.positions = {
  -- bottom right corner
  {692,712,800,820}, -- GO

  -- bottom row
  {625,712,690,820},
  {565,712,625,820},
  {500,712,565,820},
  {435,712,500,820},
  {370,712,435,820},
  {305,712,370,820},
  {240,712,305,820},
  {175,712,240,820},
  {110,712,175,820},

  -- bottom left corner
  {0,712,110,820},

  -- left column
  {0,645,110,710},
  {0,585,110,645},
  {0,520,110,585},
  {0,455,110,515},
  {0,390,110,450},
  {0,325,110,385},
  {0,260,110,320},
  {0,195,110,255},
  {0,130,110,190},

  -- top left corner
  {0,20,110,130},

  -- top row
  {110,20,175,130},
  {175,20,240,130},
  {240,20,305,130},
  {305,20,370,130},
  {370,20,435,130},
  {435,20,500,130},
  {500,20,565,130},
  {565,20,625,130},
  {628,20,690,130},

  -- top right corner
  {692,20,800,130},

  -- right column
  {690,130,800,190},
  {690,195,800,255},
  {690,260,800,320},
  {690,325,800,385},
  {690,390,800,450},
  {690,455,800,515},
  {690,520,800,585},
  {690,585,800,645},
  {690,645,800,710},
}

-- chance/community cards
config.randCard = {
  x = 300, y = 150,
  width = 200, height = 100,
  communityCount = 13,
  chanceCount = 15
}

-- cells on the board
config.board.cells = pshy.require('monopoly.generated_cards')

return config
