Market = {}

-- Try to load protocol from sandbox, fallback to global
local protocol = runinsandbox('marketprotocol')
if not protocol then
  print('[Market] ⚠️ runinsandbox failed, trying global...')
  protocol = _G.MarketProtocol
end

print('[Market] Protocol loaded: ' .. tostring(protocol))
if protocol then
  print('[Market] ✅ Protocol type: ' .. type(protocol))
  if type(protocol) == 'table' then
    print('[Market] ✅ sendMarketBrowse: ' .. tostring(protocol.sendMarketBrowse ~= nil))
  end
else
  print('[Market] ❌ ERROR: Protocol is nil!')
end

-- UI Components
local marketWindow
local offersList
local offersTitle
local slotsLabel
local goldLabel
local pointsLabel
local categoryFilter
local buyFilter
local sellFilter
local directFilter
local auctionFilter
local yourselfFilter
local othersFilter
local searchEdit
local pageLabel
local offersTab
local historyTab

-- State
local currentTab = "offers" -- "offers" or "history"
local selectedCategory = "All"
local selectedOfferType = "buy" -- "buy" or "sell"
local selectedTransactionType = "direct" -- "direct" or "auction"
local selectedCreator = "all" -- "all", "yourself", "others"
local searchText = ""
local currentPage = 1
local itemsPerPage = 6
local totalPages = 1
local allOffers = {}
local filteredOffers = {}
local selectedOfferWidget = nil

-- Player data
local playerSlots = 0
local playerMaxSlots = 50
local playerGold = 99
local playerPoints = 0

-- Categories
local categories = {
  "All",
  "Ammunition (39)",
  "Weapons",
  "Armors",
  "Shields",
  "Helmets",
  "Legs",
  "Boots",
  "Rings",
  "Amulets",
  "Runes",
  "Potions",
  "Tools",
  "Special Items"
}

function init()
  print('[Market] Initializing Rarity Market...')
  
  -- Initialize protocol
  if protocol then
    print('[Market] Protocol loaded successfully')
  else
    print('[Market] ⚠️ WARNING: Protocol not loaded, using demo mode only')
  end
  
  connect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })

  marketWindow = g_ui.displayUI('market')
  
  if not marketWindow then
    print('[Market] ❌ ERROR: Failed to load market.otui')
    return
  end
  
  marketWindow:hide()

  -- Get components
  offersList = marketWindow:recursiveGetChildById('offersList')
  offersTitle = marketWindow:recursiveGetChildById('offersTitle')
  slotsLabel = marketWindow:recursiveGetChildById('slotsLabel')
  goldLabel = marketWindow:recursiveGetChildById('goldLabel')
  pointsLabel = marketWindow:recursiveGetChildById('pointsLabel')
  categoryFilter = marketWindow:recursiveGetChildById('categoryFilter')
  buyFilter = marketWindow:recursiveGetChildById('buyFilter')
  sellFilter = marketWindow:recursiveGetChildById('sellFilter')
  directFilter = marketWindow:recursiveGetChildById('directFilter')
  auctionFilter = marketWindow:recursiveGetChildById('auctionFilter')
  yourselfFilter = marketWindow:recursiveGetChildById('yourselfFilter')
  othersFilter = marketWindow:recursiveGetChildById('othersFilter')
  searchEdit = marketWindow:recursiveGetChildById('searchEdit')
  pageLabel = marketWindow:recursiveGetChildById('pageLabel')
  offersTab = marketWindow:recursiveGetChildById('offersTab')
  historyTab = marketWindow:recursiveGetChildById('historyTab')
  
  -- Setup category filter
  if categoryFilter then
    for _, cat in ipairs(categories) do
      categoryFilter:addOption(cat)
    end
    categoryFilter.onOptionChange = Market.onCategoryChange
  end
  
  -- Setup buttons
  if buyFilter then
    buyFilter.onClick = function() Market.setOfferType('buy') end
    Market.setButtonActive(buyFilter, true)
  end
  
  if sellFilter then
    sellFilter.onClick = function() Market.setOfferType('sell') end
  end
  
  if directFilter then
    directFilter.onClick = function() Market.setTransactionType('direct') end
    Market.setButtonActive(directFilter, true)
  end
  
  if auctionFilter then
    auctionFilter.onClick = function() Market.setTransactionType('auction') end
  end
  
  if yourselfFilter then
    yourselfFilter.onClick = function() Market.setCreator('yourself') end
  end
  
  if othersFilter then
    othersFilter.onClick = function() Market.setCreator('others') end
    Market.setButtonActive(othersFilter, true)
  end
  
  local applyButton = marketWindow:recursiveGetChildById('applySearchButton')
  if applyButton then
    applyButton.onClick = Market.applyFilters
  end
  
  local refreshButton = marketWindow:recursiveGetChildById('refreshButton')
  if refreshButton then
    refreshButton.onClick = Market.refresh
  end
  
  -- Pagination
  local firstPageButton = marketWindow:recursiveGetChildById('firstPageButton')
  if firstPageButton then
    firstPageButton.onClick = function() Market.goToPage(1) end
  end
  
  local prevPageButton = marketWindow:recursiveGetChildById('prevPageButton')
  if prevPageButton then
    prevPageButton.onClick = function() Market.goToPage(currentPage - 1) end
  end
  
  local nextPageButton = marketWindow:recursiveGetChildById('nextPageButton')
  if nextPageButton then
    nextPageButton.onClick = function() Market.goToPage(currentPage + 1) end
  end
  
  local lastPageButton = marketWindow:recursiveGetChildById('lastPageButton')
  if lastPageButton then
    lastPageButton.onClick = function() Market.goToPage(totalPages) end
  end
  
  -- Tabs
  if offersTab then
    offersTab.onClick = function() Market.switchTab('offers') end
    Market.setButtonActive(offersTab, true)
  end
  
  if historyTab then
    historyTab.onClick = function() Market.switchTab('history') end
  end
  
  -- Bottom buttons
  local sellItemButton = marketWindow:recursiveGetChildById('sellItemButton')
  if sellItemButton then
    sellItemButton.onClick = Market.onSellItem
  end
  
  local buyItemButton = marketWindow:recursiveGetChildById('buyItemButton')
  if buyItemButton then
    buyItemButton.onClick = Market.onBuyItem
  end
  
  local closeButton = marketWindow:recursiveGetChildById('closeButton')
  if closeButton then
    closeButton.onClick = function() marketWindow:hide() end
  end
  
  -- Generate demo offers
  Market.generateDemoOffers()
  
  -- Register hotkey
  g_keyboard.bindKeyDown('Ctrl+M', Market.toggle)
  
  print('[Market] ✅ Rarity Market initialized!')
end

function terminate()
  disconnect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })

  g_keyboard.unbindKeyDown('Ctrl+M')

  if marketWindow then
    marketWindow:destroy()
    marketWindow = nil
  end
  
  -- Cleanup protocol
  if protocol and protocol.unregisterProtocol then
    protocol.unregisterProtocol()
  end

  Market = nil
end

function Market.online()
  Market.updatePlayerInfo()
end

function Market.offline()
  if marketWindow then
    marketWindow:hide()
  end
end

function Market.toggle()
  if not marketWindow then return end
  
  if marketWindow:isVisible() then
    marketWindow:hide()
  else
    marketWindow:show()
    marketWindow:raise()
    marketWindow:focus()
    Market.updatePlayerInfo()
    
    -- Solicitar ofertas reais do servidor
    if g_game.isOnline() then
      print('[Market] Requesting offers from server...')
      if protocol and protocol.sendMarketBrowse then
        protocol.sendMarketBrowse(2) -- 2 = all offers
      else
        print('[Market] ERROR: protocol not initialized, showing demo offers')
        Market.applyFilters()
      end
    else
      print('[Market] Not online, showing demo offers')
      Market.applyFilters() -- Usa ofertas demo
    end
  end
end

function Market.updatePlayerInfo()
  if slotsLabel then
    slotsLabel:setText('Slots: ' .. playerSlots .. ' / ' .. playerMaxSlots)
  end
  
  if goldLabel then
    goldLabel:setText('Gold: ' .. playerGold)
  end
  
  if pointsLabel then
    pointsLabel:setText('Points: ' .. playerPoints)
  end
end

function Market.setButtonActive(button, active)
  if not button then return end
  
  if active then
    button:setBackgroundColor('#4d4d4d')
  else
    button:setBackgroundColor('#2d2d2d')
  end
end

function Market.setOfferType(type)
  selectedOfferType = type
  
  Market.setButtonActive(buyFilter, type == 'buy')
  Market.setButtonActive(sellFilter, type == 'sell')
  
  Market.applyFilters()
end

function Market.setTransactionType(type)
  selectedTransactionType = type
  
  Market.setButtonActive(directFilter, type == 'direct')
  Market.setButtonActive(auctionFilter, type == 'auction')
  
  Market.applyFilters()
end

function Market.setCreator(creator)
  selectedCreator = creator
  
  Market.setButtonActive(yourselfFilter, creator == 'yourself')
  Market.setButtonActive(othersFilter, creator == 'others')
  
  Market.applyFilters()
end

function Market.onCategoryChange(combobox, option)
  selectedCategory = option
  Market.applyFilters()
end

function Market.switchTab(tab)
  currentTab = tab
  
  Market.setButtonActive(offersTab, tab == 'offers')
  Market.setButtonActive(historyTab, tab == 'history')
  
  if tab == 'offers' then
    Market.applyFilters()
  else
    Market.showHistory()
  end
end

function Market.generateDemoOffers()
  -- ✅ IDs CORRETOS extraídos do servidor Nostalrius items.srv
  local demoOffers = {
    -- Ammunition
    {name = "120x Bolt", itemId = 3446, amount = 120, expire = "Expires in 4 days 18h", price = 240, currency = "2 Gold Coins ea", type = "buy", seller = "Demo Trader"},
    {name = "95x Bolt", itemId = 3446, amount = 95, expire = "Expires in 2 days 7h", price = 190, currency = "2 Gold Coins ea", type = "buy", seller = "Demo Trader"},
    {name = "958x Bolt", itemId = 3446, amount = 958, expire = "Expires in 2 days 7h", price = 1916, currency = "2 Gold Coins ea", type = "buy", seller = "Demo Trader"},
    {name = "1000x Bolt", itemId = 3446, amount = 1000, expire = "Expires in 4 days 18h", price = 2000, currency = "2 Gold Coins ea", type = "buy", seller = "Demo Trader"},
    {name = "2000x Bolt", itemId = 3446, amount = 2000, expire = "Expires in 6 days 15h", price = 4000, currency = "2 Gold Coins ea", type = "sell", seller = "Demo Trader"},
    {name = "500x Arrow", itemId = 3447, amount = 500, expire = "Expires in 5 days 22h", price = 500, currency = "1 Gold Coin ea", type = "sell", seller = "Demo Trader"},
    {name = "200x Poison Arrow", itemId = 3448, amount = 200, expire = "Expires in 6 days 22h", price = 1000, currency = "5 Gold Coins ea", type = "sell", seller = "Demo Trader"},
    {name = "854x Power Bolt", itemId = 3450, amount = 854, expire = "Expires in 17h 46min", price = 7686, currency = "9 Gold Coins ea", type = "sell", seller = "Demo Trader"},
    {name = "100x Burst Arrow", itemId = 3449, amount = 100, expire = "Expires in 3 days 12h", price = 600, currency = "6 Gold Coins ea", type = "buy", seller = "Demo Trader"},
    {name = "50x Crystal Arrow", itemId = 3239, amount = 50, expire = "Expires in 1 day 8h", price = 1000, currency = "20 Gold Coins ea", type = "sell", seller = "Demo Trader"},
    
    -- Weapons
    {name = "Axe", itemId = 3274, amount = 1, expire = "Expires in 4 days", price = 500, currency = "500 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Sword", itemId = 3264, amount = 1, expire = "Expires in 5 days", price = 600, currency = "600 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Club", itemId = 3270, amount = 1, expire = "Expires in 2 days", price = 450, currency = "450 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Two Handed Sword", itemId = 3265, amount = 1, expire = "Expires in 3 days", price = 950, currency = "950 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Spike Sword", itemId = 3271, amount = 1, expire = "Expires in 5 days 12h", price = 8000, currency = "8000 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Longsword", itemId = 3285, amount = 1, expire = "Expires in 2 days 6h", price = 1200, currency = "1200 Gold Coins", type = "sell", seller = "Demo Trader"},
    
    -- Armors
    {name = "Plate Armor", itemId = 3357, amount = 1, expire = "Expires in 6 days", price = 4000, currency = "4000 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Chain Armor", itemId = 3358, amount = 1, expire = "Expires in 1 day", price = 700, currency = "700 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Brass Armor", itemId = 3359, amount = 1, expire = "Expires in 4 days 3h", price = 2500, currency = "2500 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Leather Armor", itemId = 3361, amount = 1, expire = "Expires in 3 days", price = 300, currency = "300 Gold Coins", type = "buy", seller = "Demo Trader"},
    
    -- Shields
    {name = "Wooden Shield", itemId = 3412, amount = 1, expire = "Expires in 3 days", price = 150, currency = "150 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Steel Shield", itemId = 3409, amount = 1, expire = "Expires in 5 days", price = 800, currency = "800 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Plate Shield", itemId = 3410, amount = 1, expire = "Expires in 2 days 18h", price = 1200, currency = "1200 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Brass Shield", itemId = 3411, amount = 1, expire = "Expires in 4 days 9h", price = 900, currency = "900 Gold Coins", type = "sell", seller = "Demo Trader"},
    
    -- Helmets
    {name = "Steel Helmet", itemId = 3351, amount = 1, expire = "Expires in 2 days", price = 580, currency = "580 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Chain Helmet", itemId = 3352, amount = 1, expire = "Expires in 1 day", price = 300, currency = "300 Gold Coins", type = "sell", seller = "Demo Trader"},
    {name = "Iron Helmet", itemId = 3353, amount = 1, expire = "Expires in 3 days 6h", price = 400, currency = "400 Gold Coins", type = "buy", seller = "Demo Trader"},
    {name = "Brass Helmet", itemId = 3354, amount = 1, expire = "Expires in 5 days", price = 500, currency = "500 Gold Coins", type = "sell", seller = "Demo Trader"},
  }
  
  -- Adicionar IDs fictícios para demo
  allOffers = {}
  for i, offer in ipairs(demoOffers) do
    offer.id = 9000 + i  -- IDs fictícios começando em 9001
    table.insert(allOffers, offer)
  end
  
  print('[Market] Generated ' .. #allOffers .. ' DEMO offers (not from server)')
end

function Market.applyFilters()
  if not searchEdit then return end
  
  searchText = searchEdit:getText():lower()
  
  -- Filter offers
  filteredOffers = {}
  for _, offer in ipairs(allOffers) do
    local matchesSearch = searchText == "" or offer.name:lower():find(searchText, 1, true)
    local matchesType = offer.type == selectedOfferType
    
    if matchesSearch and matchesType then
      table.insert(filteredOffers, offer)
    end
  end
  
  -- Update pagination
  totalPages = math.max(1, math.ceil(#filteredOffers / itemsPerPage))
  currentPage = math.min(currentPage, totalPages)
  
  -- Update UI
  Market.updateOffersList()
  Market.updatePagination()
  
  if offersTitle then
    offersTitle:setText('Offers List (' .. #filteredOffers .. ' items)')
  end
end

function Market.updateOffersList()
  if not offersList then return end
  
  offersList:destroyChildren()
  
  local startIdx = (currentPage - 1) * itemsPerPage + 1
  local endIdx = math.min(startIdx + itemsPerPage - 1, #filteredOffers)
  
  for i = startIdx, endIdx do
    local offer = filteredOffers[i]
    if offer then
      Market.createOfferWidget(offer)
    end
  end
end

function Market.createOfferWidget(offer)
  local widget = g_ui.createWidget('MarketOffer', offersList)
  
  local itemIcon = widget:getChildById('itemIcon')
  if itemIcon then
    itemIcon:setItemId(offer.itemId)
  end
  
  local itemName = widget:getChildById('itemName')
  if itemName then
    itemName:setText(offer.name)
  end
  
  local itemExpire = widget:getChildById('itemExpire')
  if itemExpire then
    itemExpire:setText(offer.expire)
  end
  
  -- Use itemCurrency (OTUI usa esse ID agora)
  local itemCurrency = widget:getChildById('itemCurrency')
  if itemCurrency then
    itemCurrency:setText(offer.currency)
  end
  
  -- Fallback para itemPrice se existir
  local itemPrice = widget:getChildById('itemPrice')
  if itemPrice then
    itemPrice:setText(offer.currency)
  end
  
  local actionButton = widget:getChildById('actionButton')
  if actionButton then
    if offer.type == 'sell' then
      actionButton:setText('Sell')
      actionButton:setBackgroundColor('#006600')
    else
      actionButton:setText('Buy')
      actionButton:setBackgroundColor('#cc6600')
    end
    
    actionButton.onClick = function()
      Market.onOfferClick(offer, widget)
    end
  end
  
  widget:setPhantom(false)
  widget:setFocusable(true)
  
  -- Armazenar referência do widget na oferta
  offer.widget = widget
  
  widget.onClick = function()
    if selectedOfferWidget then
      selectedOfferWidget:setBackgroundColor('#1a1a1a')
      selectedOfferWidget:setBorderColor('#404040')
    end
    
    widget:setBackgroundColor('#2d2d2d')
    widget:setBorderColor('#ff9900')
    selectedOfferWidget = widget
  end
end

function Market.updatePagination()
  if pageLabel then
    pageLabel:setText('Page ' .. currentPage .. ' of ' .. totalPages)
  end
end

function Market.goToPage(page)
  if page < 1 or page > totalPages then return end
  
  currentPage = page
  Market.updateOffersList()
  Market.updatePagination()
end

function Market.onOfferClick(offer, widget)
  print('[Market] Offer clicked: ' .. offer.name .. ' (ID: ' .. offer.id .. ')')
  
  if offer.type == 'sell' then
    -- Oferta de VENDA no mercado = jogador quer COMPRAR
    local message = string.format(
      'Buy %s?\n\nAmount: %d\nPrice: %d Gold Coins\nTotal: %d Gold Coins\n\nSeller: %s\nExpires: %s',
      offer.name,
      offer.amount,
      offer.price,
      offer.price * offer.amount,
      offer.seller or 'Unknown',
      offer.expire
    )
    
    displayGeneralBox('Confirm Purchase', message, {
      {text='Buy', callback = function()
        Market.buyOffer(offer)
      end},
      {text='Cancel', callback = function() end}
    }, function() end, function() end)
  else
    -- Oferta de COMPRA no mercado = jogador quer VENDER
    local message = string.format(
      'Sell %s to this buyer?\n\nAmount: %d\nPrice per unit: %d Gold Coins\nTotal: %d Gold Coins\n\nBuyer: %s\nExpires: %s',
      offer.name,
      offer.amount,
      offer.price,
      offer.price * offer.amount,
      offer.seller or 'Unknown',
      offer.expire
    )
    
    displayGeneralBox('Confirm Sale', message, {
      {text='Sell', callback = function()
        Market.sellToOffer(offer)
      end},
      {text='Cancel', callback = function() end}
    }, function() end, function() end)
  end
end

function Market.buyOffer(offer)
  local offerId = offer.id or 0
  print('[Market] Buying offer ID ' .. tostring(offerId))
  
  -- Verificar se é oferta DEMO (IDs fictícios >= 9000)
  if offerId >= 9000 then
    displayErrorBox('Demo Offer', 'This is a DEMO offer!\n\nTo see REAL offers from the server:\n1. Make sure you are logged in\n2. Click "Refresh" button\n\nDemo offers cannot be purchased.')
    return
  end
  
  -- Verificar se o jogador tem gold suficiente
  local playerGold = g_game.getMoney() or 0
  local totalCost = offer.price * (offer.amount or 1)
  
  if playerGold < totalCost then
    displayErrorBox('Insufficient Gold', 'You need ' .. totalCost .. ' Gold Coins to buy this offer.\nYou have: ' .. playerGold .. ' Gold Coins.')
    return
  end
  
  -- Enviar ao servidor
  if protocol and protocol.sendMarketAccept then
    protocol.sendMarketAccept(offerId, offer.amount or 1)
    
    -- Aguardar resposta do servidor
    displayInfoBox('Market', 'Processing your purchase...')
    
    -- Atualizar lista após 2 segundos
    scheduleEvent(function()
      if protocol and protocol.sendMarketBrowse then
        protocol.sendMarketBrowse(selectedOfferType or 2)
      end
    end, 2000)
  else
    displayErrorBox('Error', 'Market protocol not initialized. Please reconnect.')
  end
end

function Market.sellToOffer(offer)
  local offerId = offer.id or 0
  print('[Market] Selling to offer ID ' .. tostring(offerId))
  
  -- Verificar se é oferta DEMO (IDs fictícios >= 9000)
  if offerId >= 9000 then
    displayErrorBox('Demo Offer', 'This is a DEMO offer!\n\nTo see REAL offers from the server:\n1. Make sure you are logged in\n2. Click "Refresh" button\n\nDemo offers cannot be used for trading.')
    return
  end
  
  -- Verificar se o jogador tem o item
  -- TODO: Implementar verificação de inventário
  
  -- Enviar ao servidor
  if protocol and protocol.sendMarketAccept then
    protocol.sendMarketAccept(offerId, offer.amount or 1)
    
    -- Aguardar resposta do servidor
    displayInfoBox('Market', 'Processing your sale...')
    
    -- Atualizar lista após 2 segundos
    scheduleEvent(function()
      if protocol and protocol.sendMarketBrowse then
        protocol.sendMarketBrowse(selectedOfferType or 2)
      end
    end, 2000)
  else
    displayErrorBox('Error', 'Market protocol not initialized. Please reconnect.')
  end
end

function Market.createSellOffer()
  print('[Market] Opening sell dialog')
  
  displayInfoBox('Sell Item', 'Select an item from your inventory, then use /market sell <amount> <price>')
end

function Market.showHistory()
  if not offersList then return end
  
  offersList:destroyChildren()
  
  if offersTitle then
    offersTitle:setText('History')
  end
  
  local label = g_ui.createWidget('Label', offersList)
  label:setText('No transaction history yet.')
  label:setTextAlign(AlignCenter)
  label:setColor('#ffffff')
  label:setMarginTop(100)
end

function Market.onSellItem()
  displayInfoBox('Rarity Market', 'To sell an item:\n\n1. Right-click the item in your inventory\n2. Select "Offer on Market"\n\nOr use command:\n/market sell <item_id> <amount> <price>')
end

function Market.onBuyItem()
  if not selectedOfferWidget then
    displayErrorBox('No Offer Selected', 'Please select an offer from the list first.')
    return
  end
  
  -- Encontrar a oferta selecionada
  local selectedOffer = nil
  for _, offer in ipairs(allOffers) do
    if offer.widget == selectedOfferWidget then
      selectedOffer = offer
      break
    end
  end
  
  if not selectedOffer then
    displayErrorBox('Error', 'Could not find the selected offer.')
    return
  end
  
  if selectedOffer.type == 'sell' then
    -- É uma oferta de venda, então o jogador vai comprar
    Market.buyOffer(selectedOffer)
  else
    displayInfoBox('Info', 'This is a buy order. To sell to this buyer, use /market sell <item_id> <amount>')
  end
end

function Market.refresh()
  Market.updatePlayerInfo()
  
  -- Solicitar ofertas do servidor se estiver online
  if g_game.isOnline() then
    print('[Market] Requesting fresh offers from server...')
    if protocol and protocol.sendMarketBrowse then
      protocol.sendMarketBrowse(2)
      displayInfoBox('Rarity Market', 'Refreshing offers from server...')
    else
      displayErrorBox('Error', 'Market protocol not initialized. Please close and reopen the Market.')
    end
  else
    Market.applyFilters()
    displayInfoBox('Rarity Market', 'Showing demo offers (offline mode)')
  end
end

-- Callback quando recebe ofertas do servidor
function Market.onOffersReceived(serverOffers)
  print('[Market] ✅ Received ' .. #serverOffers .. ' offers from server!')
  
  -- Limpar ofertas antigas
  allOffers = {}
  
  -- Processar ofertas do servidor
  for _, offer in ipairs(serverOffers) do
    local formattedOffer = {
      id = offer.id,
      name = string.format("%dx Item #%d", offer.amount, offer.itemId),
      itemId = offer.itemId,
      amount = offer.amount,
      expire = offer.expireText or "No expiry",
      price = offer.price,
      currency = offer.currencyText or string.format("%d Gold Coins", offer.price),
      type = (offer.type == 1) and "sell" or "buy",
      playerName = offer.playerName,
      seller = offer.playerName  -- Adicionar seller também
    }
    
    table.insert(allOffers, formattedOffer)
    print(string.format('[Market] - Offer %d: %s by %s (%d gp)', offer.id, formattedOffer.name, offer.playerName, offer.price))
  end
  
  -- Atualizar interface
  Market.applyFilters()
  
  if #serverOffers > 0 then
    displayInfoBox('Rarity Market', string.format('Loaded %d offers from server!', #serverOffers))
  else
    displayInfoBox('Rarity Market', 'No offers available at the moment.')
  end
end

print('[Market 7.72] Rarity Market module loaded')

-- UI Components
