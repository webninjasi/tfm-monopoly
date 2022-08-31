local _concat = table.concat
return {
  ["en"] = {
    ["passed_go"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>passed GO and collected <VP>$200" }) end,
    ["roll_once"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>rolled a <CH>", dice1, " <J>and <CH>", dice2, " <J>moved <CH>", dicesum, " <J>spaces!" }) end,
    ["roll_double"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>rolled double <VP>", dice1, " <J>and <VP>", dice2, " <J>moved <VP>", dicesum, " <J>spaces!" }) end,
    ["roll_lobby"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>rolled a <CH>", dice1, " <J>and <CH>", dice2, " <J>which sums up to <CH>", dicesum, "." }) end,
    ["roll_jail"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>rolled a double 3 times and went to jail." }) end,
    ["roll_jail_fail"] = function(_translate, _target, player, dice1, dice2) return _concat({ "<V>", player, " <J>rolled a <CH>", dice1, " <J>and <CH>", dice2, " <J>and failed to escape from jail!" }) end,
    ["move"] = function(_translate, _target, player, propertycolor, movedtoproperty) return _concat({ "<V>", player, " <J>moved to <font color=\"#", propertycolor, "\">", movedtoproperty, "" }) end,
    ["purchase"] = function(_translate, _target, player, propertycolor, purchaseproperty, price) return _concat({ "<V>", player, " <J>purchased <font color=\"#", propertycolor, "\">", purchaseproperty, " <J>for <VP>$", price, "" }) end,
    ["auction"] = function(_translate, _target, player, propertycolor, auctionproperty, price) return _concat({ "<V>", player, " <J>purchased <font color=\"#", propertycolor, "\">", auctionproperty, " <J>for <VP>$", price, " <J>in the auction." }) end,
    ["pay_rent"] = function(_translate, _target, player, money, playerowner) return _concat({ "<V>", player, " <J>paid <VP>$", money, " <J>in rent to <V>", playerowner, "." }) end,
    ["jail_in"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>was sent to jail!" }) end,
    ["jail_out_money"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>paid the <VP>$50 <J>fine to get out of jail." }) end,
    ["jail_out_dice"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>rolled doubles to get out of jail." }) end,
    ["jail_out_card"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>used a \"Get Out of Jail Free\" card." }) end,
    ["won"] = function(_translate, _target, player) return _concat({ "<V>", player, " <ROSE>won the game!" }) end,
    ["player_left"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>left the game!" }) end,
    ["start_roll"] = "<ROSE>Roll the dice to determine start order.",
    ["new_game"] = "<ROSE>The game has started.",
    ["player_turn"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>is playing." }) end,
    ["chance_space"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>landed on a chance space!" }) end,
    ["community_chest"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>landed on community chest!" }) end,
    ["income_tax"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>has to pay $200 in income tax from collecting too much cheese!" }) end,
    ["luxury_tax"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>has to pay $100 in luxury tax for being too noob!" }) end,
    ["bankrupt"] = function(_translate, _target, player, playerowner) return _concat({ "<V>", player, " <R>went bankrupt and has lost the game! All of their assets will be turned over to <V>", playerowner, "." }) end,
    ["mortgage_property"] = function(_translate, _target, player, propertycolor, movedtoproperty, playerowner) return _concat({ "<V>", player, " <J>landed on <font color=\"#", propertycolor, "\">", movedtoproperty, " <J>owned by <V>", playerowner, "<J>. Property is mortgaged, no rent was collected." }) end,
    ["warn_need_fullset"] = "<J>Before you can buy a house, you must own all the properties of a color-group.",
    ["warn_need_house"] = "<J>You don't have any house to sell.",
    ["warn_need_house2"] = "<J>You don't have any house to mortgage.",
    ["warn_need_house3"] = "<J>You don't have any house to unmortgage.",
    ["log_card"] = function(_translate, _target, player, type, cardtext) return _concat({ "<V>", player, " <J>drew a <ROSE>", type, " <J>card: <CH>", _translate(cardtext, _target), "" }) end,
    ["community"] = "community",
    ["chance"] = "chance",
    ["auction_title"] = "<font size=\"20\" color=\"#ffffff\"><p align=\"center\">Auction",
    ["auction_highest"] = function(_translate, _target, bid, bidder) return _concat({ "<font color=\"#000000\">Highest Bid: <VP>$", bid, "\n<font color=\"#000000\">Highest Bidder: <V>", bidder, "" }) end,
    ["ui_house_title"] = "<font size=\"19\" color=\"#ffffff\"><p align=\"center\"><a href=\"event:close_house\">Manage Properties",
    ["ui_tokens_title"] = "<font size=\"15\" color=\"#ffffff\"><b><p align=\"center\">Pick Token & Color",
    ["buy_house"] = "<p align=\"center\"><b><VP><a href=\"event:buy_house\">Buy House",
    ["sell_house"] = "<p align=\"center\"><b><R><a href=\"event:sell_house\">Sell House",
    ["auction_no_bid"] = "<R>Auction ended with no bid.",
    ["mortgage"] = "<p align=\"center\"><b><R><a href=\"event:mortgage\">Mortgage",
    ["unmortgage"] = "<p align=\"center\"><b><VP><a href=\"event:unmortgage\">Unmortgage",
    ["card_1"] = "Go - Collect 200 as you pass",
    ["card_2"] = "<N>Vanilla Avenue",
    ["card_3"] = "Community Chest",
    ["card_4"] = "<N>Defilante Street",
    ["card_5"] = "Income Tax",
    ["card_6"] = "Deathmatch Station",
    ["card_7"] = "Parkour Street",
    ["card_8"] = "Chance",
    ["card_9"] = "Racing Route",
    ["card_10"] = "Fight Boulevard",
    ["card_11"] = "In Jail - Just Visiting",
    ["card_12"] = "<font size=\"10\">Transformice Alley",
    ["card_13"] = "Electric Utility Company",
    ["card_14"] = "Batata Avenue",
    ["card_15"] = "Dancefloor Alley",
    ["card_16"] = "Trade Station",
    ["card_17"] = "<font size=\"12\">Prophunt Avenue",
    ["card_18"] = "Community Chest",
    ["card_19"] = "Football Venue",
    ["card_20"] = "Unotfm Street",
    ["card_21"] = "Village AFK",
    ["card_22"] = "Spiritual Avenue",
    ["card_23"] = "Chance",
    ["card_24"] = "Freezertag Road",
    ["card_25"] = "<font size=\"10\">Towerdefense Street",
    ["card_26"] = "Survivor Station",
    ["card_27"] = "Circuit Avenue",
    ["card_28"] = "Ratapult Plaza",
    ["card_29"] = "Water Cbase Company",
    ["card_30"] = "Mycity Avenue",
    ["card_31"] = "Go To Jail",
    ["card_32"] = "<font size=\"12\">Hardcamp Avenue",
    ["card_33"] = "<font size=\"10\">Hidenseek Boulevard",
    ["card_34"] = "Community Chest",
    ["card_35"] = "Divinity Avenue",
    ["card_36"] = "Cannonup Station",
    ["card_37"] = "Chance",
    ["card_38"] = "<N>Records Plaza",
    ["card_39"] = "Luxury Tax",
    ["card_40"] = "<N><font size=\"12\">Bootcamp Avenue",
    ["community_1"] = "Advance to Go\nCollect $200",
    ["community_2"] = "Go back to Vanilla Avenue",
    ["community_3"] = "Bank error in your favor\nCollect $200",
    ["community_4"] = "From sale of stock you get $50",
    ["community_5"] = "Income tax refund.\nCollect $20",
    ["community_6"] = "Life insurance matures\nCollect $100",
    ["community_7"] = "You have won second prize in a beauty contest.\nCollect $10",
    ["community_8"] = "It is your birthday.\nCollect $10 from every player",
    ["community_9"] = "Doctor's fees\nPay $50",
    ["community_10"] = "Hospital Fees.\nPay $50",
    ["community_11"] = "Pay school fees\nof $150",
    ["community_12"] = "Go to Jail",
    ["community_13"] = "Get out of jail free\nThis card may kept until needed",
    ["chance_1"] = "Advance to Go\nCollect $200",
    ["chance_2"] = "Advance to Bootcamp Avenue",
    ["chance_3"] = "Go back three spaces",
    ["chance_4"] = "Advance to Transformice Alley\nIf you pass GO collect $200",
    ["chance_5"] = "Take a trip to Trade Station\nIf you pass GO collect $200",
    ["chance_6"] = "Advance to Towerdefence Street\nIf you pass GO collect $200",
    ["chance_7"] = "Pay school fees\nof $150",
    ["chance_8"] = "Speeding fine $15",
    ["chance_9"] = "Make general repairs on all of your houses\nFor each house pay $25\nFor each hotel pay $100",
    ["chance_10"] = "You are assessed for street repairs\nFor each house pay $40\nFor each hotel pay $115",
    ["chance_11"] = "Bank pays you dividend Of $50",
    ["chance_12"] = "You have won a crossword competition\nCollect $100",
    ["chance_13"] = "Your Building loan matures\nReceive $150",
    ["chance_14"] = "Go to Jail",
    ["chance_15"] = "Get out of jail free\nThis card may kept until needed",
  },
  ["tr"] = {
    ["passed_go"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>BAŞLANGIÇ üzerinden geçti ve <VP>$200 <J>kazandı." }) end,
    ["roll_once"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>attığı zarlar <CH>", dice1, " <J>ile <CH>", dice2, " <J>geldi ve <CH>", dicesum, " <J>adım ilerledi!" }) end,
    ["roll_double"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>attığı zarlar çift <VP>", dice1, " <J>geldi ve <VP>", dicesum, " <J>adım ilerledi!" }) end,
    ["roll_lobby"] = function(_translate, _target, player, dice1, dice2, dicesum) return _concat({ "<V>", player, " <J>attığı zarlar toplamı <CH>", dicesum, " <J>olan <CH>", dice1, " <J>ile <CH>", dice2, " <J>geldi." }) end,
    ["roll_jail"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>üç defa çift zar attığı için hapise düştü." }) end,
    ["roll_jail_fail"] = function(_translate, _target, player, dice1, dice2) return _concat({ "<V>", player, " <J>attığı zarlar <CH>", dice1, " <J>ile <CH>", dice2, " <J>geldi ve hapisten kaçamadı!" }) end,
    ["move"] = function(_translate, _target, player, propertycolor, movedtoproperty) return _concat({ "<V>", player, " <font color=\"#", propertycolor, "\">", movedtoproperty, " <J>arazisinde." }) end,
    ["purchase"] = function(_translate, _target, player, propertycolor, purchaseproperty, price) return _concat({ "<V>", player, " <font color=\"#", propertycolor, "\">", purchaseproperty, " <J>arazisini <VP>$", price, " <J>ödeyerek satın aldı." }) end,
    ["auction"] = function(_translate, _target, player, propertycolor, auctionproperty, price) return _concat({ "<V>", player, " <J>ihaleyle <font color=\"#", propertycolor, "\">", auctionproperty, " <VP>$", price, " <J>ödeyerek arazisini satın aldı." }) end,
    ["pay_rent"] = function(_translate, _target, player, money, playerowner) return _concat({ "<V>", player, " <J>kira bedeli olarak <VP>$", money, " <J>kadar <V>", playerowner, " <J>oyuncusuna ödedi." }) end,
    ["jail_in"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>hapise düştü!" }) end,
    ["jail_out_money"] = function(_translate, _target, player) return _concat({ "<V>", player, " <VP>$50 <J>kefaret ödeyerek hapisten çıktı." }) end,
    ["jail_out_dice"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>çift zarla hapisten çıktı." }) end,
    ["jail_out_card"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>\"Kefaret Ödemeden Hapisten Çık\" kartını kullandı." }) end,
    ["won"] = function(_translate, _target, player) return _concat({ "<V>", player, " <ROSE>oyunu kazandı!" }) end,
    ["player_left"] = function(_translate, _target, player) return _concat({ "<V>", player, " <R>oyunu terk etti!" }) end,
    ["start_roll"] = "<ROSE>Zar at ve başlangıç sırasını belirle.",
    ["new_game"] = "<ROSE>Oyun başladı.",
    ["player_turn"] = function(_translate, _target, player) return _concat({ "<J>Sıra <V>", player, " <J>oyuncusunda." }) end,
    ["chance_space"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>şans bölgesinde!" }) end,
    ["community_chest"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>topluluk sandığında!" }) end,
    ["income_tax"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>çok fazla peynir topladığı için $200 gelir vergisi ödemek zorunda kaldı." }) end,
    ["luxury_tax"] = function(_translate, _target, player) return _concat({ "<V>", player, " <J>fazla noob olduğu için $100 özel tüketim vergisi ödemek zorunda kaldı." }) end,
    ["bankrupt"] = function(_translate, _target, player, playerowner) return _concat({ "<V>", player, " <R>iflas etti ve oyunu kaybetti! Tüm malvarlığı <V>", playerowner, " <R> oyuncusuna devredilecek." }) end,
    ["mortgage_property"] = function(_translate, _target, player, propertycolor, movedtoproperty, playerowner) return _concat({ "<V>", player, "<J>, sahibi <V>", playerowner, " <J>olan <font color=\"#", propertycolor, "\">", movedtoproperty, " <J>mülkünün üzerinde. Mülk ipotek edildiği için, kira ödenmedi." }) end,
    ["warn_need_fullset"] = "<J>Ev satın almadan önce bir renk grubundaki tüm mülkiyetlere sahip olmalısınız.",
    ["warn_need_house"] = "<J>Satabileceğin bir evin bulunmamakta.",
    ["warn_need_house2"] = "<J>İpotekleyebileceğin bir evin bulunmamakta.",
    ["warn_need_house3"] = "<J>İpotekeğini kaldırabileceğin bir evin bulunmamakta.",
    ["log_card"] = function(_translate, _target, player, type, cardtext) return _concat({ "<V>", player, " <J>bir <ROSE>", type, " <J>kartı çekti: <N>", _translate(cardtext, _target), "" }) end,
    ["community"] = "topluluk",
    ["chance"] = "şans",
    ["auction_title"] = "<font size=\"20\" color=\"#ffffff\"><p align=\"center\">İhale",
    ["auction_highest"] = function(_translate, _target, bid, bidder) return _concat({ "<font color=\"#000000\">En Yüksek Teklif: <VP>$", bid, "\n<font color=\"#000000\">En Yüksek Teklifi Veren: <V>", bidder, "" }) end,
    ["ui_house_title"] = "<font size=\"19\" color=\"#ffffff\"><p align=\"center\"><a href=\"event:close_house\">Mülkleri Yönet",
    ["ui_tokens_title"] = "<font size=\"15\" color=\"#ffffff\"><b><p align=\"center\">Taş & Renk Seç",
    ["buy_house"] = "<p align=\"center\"><b><VP><a href=\"event:buy_house\">Ev Satın Al",
    ["sell_house"] = "<p align=\"center\"><b><R><a href=\"event:sell_house\">Ev Sat",
    ["auction_no_bid"] = "<R>İhale teklifsiz sona erdi.",
    ["mortgage"] = "<p align=\"center\"><b><R><a href=\"event:mortgage\">İpotek",
    ["unmortgage"] = "<p align=\"center\"><b><VP><a href=\"event:unmortgage\">İpotek Kaldır",
    ["card_1"] = "Başlangıç",
    ["card_2"] = "<N>Vanilla Caddesi",
    ["card_3"] = "Topluluk Sandığı",
    ["card_4"] = "<N>Defilante Sokak",
    ["card_5"] = "Gelir Vergisi",
    ["card_6"] = "Deathmatch İstasyonu",
    ["card_7"] = "Parkour Sokak",
    ["card_8"] = "Şans",
    ["card_9"] = "Racing Yolu",
    ["card_10"] = "Fight Bulvarı",
    ["card_11"] = "Hapis - Ziyaret",
    ["card_12"] = "<font size=\"10\">Transformice Geçiti",
    ["card_13"] = "<font size=\"10\">Utility Elektrik Hizmetleri",
    ["card_14"] = "Batata Caddesi",
    ["card_15"] = "Dancefloor Geçiti",
    ["card_16"] = "Trade İstasyonu",
    ["card_17"] = "<font size=\"12\">Prophunt Caddesi",
    ["card_18"] = "Topluluk Sandığı",
    ["card_19"] = "Football Mekanı",
    ["card_20"] = "Unotfm Sokak",
    ["card_21"] = "AFK Köyü",
    ["card_22"] = "Spiritual Caddesi",
    ["card_23"] = "Şans",
    ["card_24"] = "Freezertag Road",
    ["card_25"] = "<font size=\"10\">Towerdefense Sokak",
    ["card_26"] = "Survivor İstasyonu",
    ["card_27"] = "Circuit Cadesi",
    ["card_28"] = "Ratapult Plaza",
    ["card_29"] = "<font size=\"10\">Cbase Su Hizmetleri",
    ["card_30"] = "Mycity Caddesi",
    ["card_31"] = "Hapise Git",
    ["card_32"] = "<font size=\"12\">Hardcamp Caddesi",
    ["card_33"] = "<font size=\"10\">Hidenseek Bulvarı",
    ["card_34"] = "Topluluk Sandığı",
    ["card_35"] = "Divinity Caddesi",
    ["card_36"] = "Cannonup İstasyonu",
    ["card_37"] = "Şans",
    ["card_38"] = "<N>Records Plaza",
    ["card_39"] = "Özel Tüketim Vergisi",
    ["card_40"] = "<N><font size=\"12\">Bootcamp Caddesi",
    ["community_1"] = "Başlangıça ilerle\n$200 al",
    ["community_2"] = "Vanilla Caddesine geri dön",
    ["community_3"] = "Bankada senin yararına bir hata oldu\n$200 kazandın",
    ["community_4"] = "Hisse satışından $50 aldın",
    ["community_5"] = "Gelir vergisi iadesi\n$20 al",
    ["community_6"] = "Hayat sigortası primlerin geri ödendi\n$100 al",
    ["community_7"] = "Güzellik yarışmasında ikincilik ödülü kazandın\n$10 al",
    ["community_8"] = "Bugün doğum günün\nHerkesten $10 al",
    ["community_9"] = "Doktor ücreti\n$50 öde",
    ["community_10"] = "Hastane masrafı\n$50 öde",
    ["community_11"] = "Okul harcı için\n$150 öde",
    ["community_12"] = "Hapise Git",
    ["community_13"] = "Hapisten kefaret ödemeden çık\nBu kartı lazım olana dek saklayabilirsin",
    ["chance_1"] = "Başlangıça ilerle\n$200 al",
    ["chance_2"] = "Bootcamp caddesine ilerle",
    ["chance_3"] = "Üç adım geri git",
    ["chance_4"] = "Transformice Caddesine ilerle\nBaşlangıçtan geçersen $200 al",
    ["chance_5"] = "Trade İstasyonuna git\nBaşlangıçtan geçersen $200 al",
    ["chance_6"] = "Towerdefense Sokağa git\nBaşlangıçtan geçersen $200 al",
    ["chance_7"] = "Okul harcı için\n$150 öde",
    ["chance_8"] = "Hız cezası $15 öde",
    ["chance_9"] = "Binalarının genel tadilatını yap\nHer ev için $25 öde\nHer otel için $100 öde",
    ["chance_10"] = "Sokağın tadilatı sana düştü\nHer ev için $40 öde\nHer otel için $115 öde",
    ["chance_11"] = "Banka hissenden sana $50 payını ödüyor",
    ["chance_12"] = "Kare bulmaca turnuvasını kazandın\n$100 al",
    ["chance_13"] = "İnşaat kredinin primleri geri ödendi\n$150 al",
    ["chance_14"] = "Hapise Git",
    ["chance_15"] = "Hapisten kefaret ödemeden çık\nBu kartı lazım olana dek saklayabilirsin",
  },
}