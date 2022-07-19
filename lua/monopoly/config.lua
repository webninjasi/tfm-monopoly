--- monopoly.config

monopoly = monopoly or {}

if monopoly.config then
  return
end

monopoly.config = {}
monopoly.config.mapXML = [[
<C>
  <P H="820" L="1000" D="181f07394f8.png,0,20" MEDATA=";;;;0,4-0;0:::1-"/>
  <Z>
    <S>
      <S T="12" X="400" Y="18" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="400" Y="128" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="400" Y="712" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="400" Y="828" L="800" H="10" P="0,0,0.3,0.2,0,0,0,0"/>
      <S T="12" X="0" Y="422" L="800" H="10" P="0,0,0.3,0.2,90,0,0,0"/>
      <S T="12" X="805" Y="422" L="800" H="10" P="0,0,0.3,0.2,90,0,0,0"/>
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
      <S T="12" X="5" Y="25" L="10" H="10" P="0,0,0.3,0.2,0,0,0,0" o="324650"/>
      <S T="12" X="325" Y="375" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="465" Y="375" L="10" H="60" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="395" Y="445" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="395" Y="305" L="60" H="10" P="0,0,0.3,0.5,0,0,0,0" o="6A7495" m=""/>
      <S T="12" X="345" Y="325" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="445" Y="425" L="10" H="60" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="445" Y="325" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
      <S T="12" X="345" Y="425" L="60" H="10" P="0,0,0.3,0.5,45,0,0,0" o="6A7495" m=""/>
    </S>
    <D/>
    <O/>
    <L/>
  </Z>
</C>
]]

monopoly.config.images = {
  background = "181f07394f8.png",
  circle = "182144f123d.png",
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
  },
  actionui = {
    x = 280, y = 260,
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

-- cells on the board
monopoly.config.board.cells = {
  {
    type = "win",
    title = "Go - Collect 200 as you pass",
    price = 200,
  },
  {
    type = "property",
    title = "Vanilla Avenue",
    price = 60,
    rent = 2,
    house = 10,
    house2 = 30,
    house3 = 90,
    house4 = 160,
    hotel = 250,
    house_hotel = 50,
    mortgage = 30,
  },
  {
    type = "chest",
    title = "Community chest",
    price = 0,
  },
  {
    type = "property",
    title = "Defilanti Street",
    price = 60,
    rent = 4,
    house = 20,
    house2 = 60,
    house3 = 180,
    house4 = 320,
    hotel = 450,
    house_hotel = 50,
    mortgage = 30,
  },
  {
    type = "lose",
    title = "Tax",
    price = 200,
    mortgage = 100,
  },
  {
    type = "property",
    title = "Deathmatch Station",
    price = 200,
    house = 25,
    house2 = 50,
    house3 = 100,
    house4 = 200,
  },
  {
    type = "property",
    title = "Parkour street",
    price = 100,
    rent = 6,
    house = 30,
    house2 = 90,
    house3 = 270,
    house4 = 400,
    hotel = 550,
    house_hotel = 50,
    mortgage = 50,
  },
  {
    type = "chance",
    title = "Chance",
    price = 0,
  },
  {
    type = "property",
    title = "Racing Route",
    price = 100,
    rent = 6,
    house = 30,
    house2 = 90,
    house3 = 270,
    house4 = 400,
    hotel = 550,
    house_hotel = 50,
    mortgage = 50,
  },
  {
    type = "property",
    title = "Village boulevard",
    price = 120,
    rent = 8,
    house = 40,
    house2 = 100,
    house3 = 300,
    house4 = 450,
    hotel = 600,
    house_hotel = 50,
    mortgage = 60,
  },
  {
    type = "empty",
    title = "In Jail - Just Visiting",
    price = 0,
  },
  {
    type = "property",
    title = "Transformice alley",
    price = 140,
    rent = 10,
    house = 50,
    house2 = 150,
    house3 = 450,
    house4 = 625,
    hotel = 750,
    house_hotel = 100,
    mortgage = 70,
  },
  {
    type = "utility",
    title = "Electric Utility Company",
    price = 150,
    mortgage = 75,
  },
  {
    type = "property",
    title = "Batata Avenue",
    price = 140,
    rent = 10,
    house = 50,
    house2 = 150,
    house3 = 450,
    house4 = 625,
    hotel = 750,
    house_hotel = 100,
    mortgage = 70,
  },
  {
    type = "property",
    title = "Dancefloor alley",
    price = 160,
    rent = 12,
    house = 60,
    house2 = 180,
    house3 = 500,
    house4 = 700,
    hotel = 900,
    house_hotel = 100,
    mortgage = 80,
  },
  {
    type = "property",
    title = "Trade Station",
    price = 200,
    house = 25,
    house2 = 50,
    house3 = 100,
    house4 = 200,
    mortgage = 100,
  },
  {
    type = "property",
    title = "PropHunt Avenue",
    price = 180,
    rent = 14,
    house = 70,
    house2 = 200,
    house3 = 550,
    house4 = 750,
    hotel = 950,
    house_hotel = 100,
    mortgage = 90,
  },
  {
    type = "chest",
    title = "Community chest",
    price = 0,
  },
  {
    type = "property",
    title = "Football Venue",
    price = 180,
    rent = 14,
    house = 70,
    house2 = 200,
    house3 = 550,
    house4 = 750,
    hotel = 950,
    house_hotel = 100,
    mortgage = 90,
  },
  {
    type = "property",
    title = "Unotfm Street",
    price = 200,
    rent = 16,
    house = 80,
    house2 = 220,
    house3 = 600,
    house4 = 800,
    hotel = 1000,
    house_hotel = 100,
    mortgage = 100,
  },
  {
    type = "empty",
    title = "Free Parking",
    price = 0,
  },
  {
    type = "property",
    title = "spiritual Avenue",
    price = 220,
    rent = 18,
    house = 90,
    house2 = 250,
    house3 = 700,
    house4 = 875,
    hotel = 1050,
    house_hotel = 150,
    mortgage = 110,
  },
  {
    type = "chance",
    title = "chance",
    price = 0,
  },
  {
    type = "property",
    title = "Freezertag Road",
    price = 220,
    rent = 18,
    house = 90,
    house2 = 250,
    house3 = 700,
    house4 = 875,
    hotel = 1050,
    house_hotel = 150,
    mortgage = 110,
  },
  {
    type = "property",
    title = "Towerdefense Street",
    price = 240,
    rent = 20,
    house = 100,
    house2 = 300,
    house3 = 750,
    house4 = 925,
    hotel = 1100,
    house_hotel = 150,
    mortgage = 120,
  },
  {
    type = "property",
    title = "Survivor Station",
    price = 200,
    house = 25,
    house2 = 50,
    house3 = 100,
    house4 = 200,
    mortgage = 100,
  },
  {
    type = "property",
    title = "Circuit Avenue",
    price = 260,
    rent = 22,
    house = 110,
    house2 = 330,
    house3 = 800,
    house4 = 975,
    hotel = 1150,
    house_hotel = 150,
    mortgage = 130,
  },
  {
    type = "property",
    title = "Ratapult plaza",
    price = 260,
    rent = 22,
    house = 110,
    house2 = 330,
    house3 = 800,
    house4 = 975,
    hotel = 1150,
    house_hotel = 150,
    mortgage = 130,
  },
  {
    type = "utility",
    title = "Water Cbase Company",
    price = 150,
    mortgage = 75,
  },
  {
    type = "property",
    title = "MyCity Avenue",
    price = 280,
    rent = 24,
    house = 120,
    house2 = 360,
    house3 = 850,
    house4 = 1025,
    hotel = 1200,
    house_hotel = 150,
    mortgage = 140,
  },
  {
    type = "jail",
    title = "Go To Jail",
    price = 0,
  },
  {
    type = "property",
    title = "Hardcamp Avenue",
    price = 300,
    rent = 26,
    house = 130,
    house2 = 390,
    house3 = 900,
    house4 = 1100,
    hotel = 1275,
    house_hotel = 200,
    mortgage = 150,
  },
  {
    type = "property",
    title = "Hidenseek boulevard",
    price = 300,
    rent = 26,
    house = 130,
    house2 = 390,
    house3 = 900,
    house4 = 1100,
    hotel = 1275,
    house_hotel = 200,
    mortgage = 150,
  },
  {
    type = "chest",
    title = "Community Chest",
    price = 0,
  },
  {
    type = "property",
    title = "Divinity Avenue",
    price = 320,
    rent = 28,
    house = 150,
    house2 = 450,
    house3 = 1000,
    house4 = 1200,
    hotel = 1400,
    house_hotel = 200,
    mortgage = 160,
  },
  {
    type = "property",
    title = "Cannonup Station",
    price = 200,
    house = 25,
    house2 = 50,
    house3 = 100,
    house4 = 200,
    mortgage = 100,
  },
  {
    type = "chance",
    title = "Chance",
    price = 0,
  },
  {
    type = "property",
    title = "Records plaza",
    price = 350,
    rent = 35,
    house = 175,
    house2 = 500,
    house3 = 1100,
    house4 = 1300,
    hotel = 1500,
    house_hotel = 200,
    mortgage = 175,
  },
  {
    type = "lose",
    title = "Tax",
    price = 100,
  },
  {
    type = "property",
    title = "Bootcamp Avenue",
    price = 400,
    rent = 50,
    house = 200,
    house2 = 600,
    house3 = 1400,
    house4 = 1700,
    hotel = 2000,
    house_hotel = 200,
    mortgage = 200,
  },
}
