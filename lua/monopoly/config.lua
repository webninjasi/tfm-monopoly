--- monopoly.config

monopoly = monopoly or {}

if monopoly.config then
  return
end

monopoly.config = {}
monopoly.config.mapXML = [[
<C>
  <P H="820" D="181f07394f8.png,0,20" MEDATA=";;;;0,4-0;0:::1-"/>
  <Z>
    <S>
      <S T="12" X="400" Y="20" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0" o="6A7495"/>
      <S T="12" X="400" Y="128" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="400" Y="712" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="400" Y="828" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="0" Y="422" L="800" H="10" P="0,0,0.3,0.2,90,0,0,0"/>
      <S T="12" X="840" Y="420" L="800" H="80" P="0,0,0,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="692" Y="422" L="800" H="10" P="0,0,0.3,0.2,90,0,0,0"/>
      <S T="12" X="108" Y="422" L="800" H="10" P="0,0,0.3,0.2,90,0,0,0"/>
      <S T="12" X="331" Y="374" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" c="2" m=""/>
      <S T="12" X="471" Y="374" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" c="2" m=""/>
      <S T="12" X="401" Y="444" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" c="2" m=""/>
      <S T="12" X="401" Y="304" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" c="2" m=""/>
      <S T="12" X="351" Y="324" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" c="2" m=""/>
      <S T="12" X="451" Y="424" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" c="2" m=""/>
      <S T="12" X="451" Y="324" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" c="2" m=""/>
      <S T="12" X="351" Y="424" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" c="2" m=""/>
      <S T="12" X="325" Y="375" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="465" Y="375" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="395" Y="445" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="395" Y="305" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="345" Y="325" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="445" Y="425" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="445" Y="325" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="345" Y="425" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="935" Y="420" L="800" H="40" P="0,0,0,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="815" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="15" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="495" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="255" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="910" Y="415" L="220" H="820" P="0,0,0.3,0.2,0,0,0,0" o="6A7495" c="4" N=""/>
      <S T="12" X="900" Y="775" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="455" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
      <S T="12" X="900" Y="215" L="10" H="100" P="0,0,0.3,0.2,90,0,0,0" o="D84801"/>
    </S>
    <D>
      <DS X="900" Y="235"/>
    </D>
    <O/>
    <L/>
  </Z>
</C>
]]
monopoly.config.scrollPos = {
  x = 900,
  235, 475, 795,
}

monopoly.config.images = {
  background = "1823c8f747a.png",
  circle = "182144f123d.png",
  cards = {
    empty = "18220bf6da4.png",
    chance = "18220c02228.png",
    community = "18220bfcef2.png",
    water = "181f075f65a.png",
    electric = "181f076425d.png",
    train = "181f0768e5c.png",
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
    {"181f073e25d.png", 60, 28},
    {"181f0742e5c.png", 43, 28},
    {"181f0747a5b.png", 46, 28},
    {"181f074c65c.png", 50, 31},
    {"181f075125b.png", 28, 36},
    {"181f0755e5c.png", 50, 34},
    {"182072a2a0a.png", 50, 30},
    {"182072a7e6a.png", 50, 26},
    {"1820f864577.png", 50, 30},
    {"1821023e89f.png", 40, 45},
  },
  actionui = {
    x = 280, y = 680,
    w = 50, h = 50,
    sep = 10,
    taw = 40, tah = 40,
    alpha = 0.5,

    {"Dice", "181f077be5d.png", true},
    {"Cards", "181f076da5c.png"},
    {"Build", "181f077265d.png"},
    {"Trade", "181f0780a5c.png"},
    {"Stop", "181f077725b.png"},
  },
}

-- spawn locations when rolling the dices
monopoly.config.dice1 = { x = 355, y = 375 }
monopoly.config.dice2 = { x = 435, y = 375 }

-- roll config
monopoly.config.roll = {
  delay = 2000, -- length of the dice roll animation
  x = 325, -- button x
  y = 305, -- button y
  w = 140, -- button width
  h = 140, -- button height
}

-- tokens default position
monopoly.config.tokens = {
  defaultX = 130,
  defaultY = 620,
}

-- money ui
monopoly.config.money = { x = 370, y = 150 }

-- board configs
monopoly.config.board = {}

-- height of houses to place on top of properties
monopoly.config.board.houseSize = 20

-- property positions in clockwise order
monopoly.config.board.positions = {
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

-- cell rows on card
monopoly.config.cardRows = {
  {
    key = "price",
    title = "Price",
  },
  {
    key = "rent",
    title = "Rent",
  },
  {
    key = "house",
    title = "With 1 House",
  },
  {
    key = "house2",
    title = "With 2 House",
  },
  {
    key = "house3",
    title = "With 3 House",
  },
  {
    key = "house4",
    title = "With 4 House",
  },
  {
    key = "hotel",
    title = "With 1 Hotel",
  },
  {
    key = "house_hotel",
    title = "A House Costs",
  },
  {
    key = "mortgage",
    title = "Mortgage Costs",
  },
}

-- cells on the board
pshy.require('monopoly.generated_cards')
