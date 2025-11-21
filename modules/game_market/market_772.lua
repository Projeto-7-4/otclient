Market = {}

local protocol = runinsandbox('marketprotocol')

-- UI Components
local marketWindow
local categoryList
local offersList
local buyButton
local sellButton
local refreshButton
local myOffersButton
local searchEdit
local itemPreview
local itemNameLabel
local priceLabel
local amountLabel
local sellerLabel

-- State
local offers = {}
local selectedOffer = nil
local selectedCategory = 0

-- Categories
local categories = {
  {id = 0, name = "All Items"},
  {id = 1, name = "Weapons"},
  {id = 2, name = "Armors"},
  {id = 3, name = "Shields"},
  {id = 4, name = "Helmets"},
  {id = 5, name = "Legs"},
  {id = 6, name = "Boots"},
  {id = 7, name = "Rings"},
  {id = 8, name = "Amulets"},
  {id = 9, name = "Runes"},
  {id = 10, name = "Potions"},
  {id = 11, name = "Others"}
}

function init()
  print('[Market] init() starting...')
  
  connect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })
  print('[Market] Connected game events')

  -- Load UI using displayUI (like Shop does)
  print('[Market] Loading market.otui with displayUI...')
  
  if marketWindow then
    print('[Market] Window already exists, skipping')
    return
  end
  
  marketWindow = g_ui.displayUI('market')
  
  if not marketWindow then
    print('[Market] ❌ ERROR: Failed to load market.otui')
    return
  end
  
  print('[Market] ✅ UI loaded successfully with displayUI!')
  
  marketWindow:hide()
  print('[Market] Window hidden')

  -- Modern OTClientV8 syntax: direct access to components
  -- No need for getChildById!
  categoryList = marketWindow.categoryList
  offersList = marketWindow.offersList
  buyButton = marketWindow.buyButton
  sellButton = marketWindow.sellButton
  refreshButton = marketWindow.refreshButton
  myOffersButton = marketWindow.myOffersButton
  searchEdit = marketWindow.searchEdit
  itemPreview = marketWindow.itemPreview
  itemNameLabel = marketWindow.itemNameLabel
  priceLabel = marketWindow.priceLabel
  amountLabel = marketWindow.amountLabel
  sellerLabel = marketWindow.sellerLabel
  
  print('[Market] Components loaded (modern syntax)')

  -- Connect events
  connect(categoryList, { onChildFocusChange = Market.onCategorySelect })
  connect(offersList, { onChildFocusChange = Market.onOfferSelect })
  connect(buyButton, { onClick = Market.onBuyClick })
  connect(sellButton, { onClick = Market.onSellClick })
  connect(refreshButton, { onClick = Market.onRefreshClick })
  connect(myOffersButton, { onClick = Market.onMyOffersClick })
  connect(searchEdit, { onTextChange = Market.onSearchChange })
  
  print('[Market] Events connected')

  -- Populate categories
  Market.populateCategories()

  -- Register hotkey
  g_keyboard.bindKeyDown('Ctrl+M', Market.toggle)
  print('[Market] Hotkey registered (Ctrl+M)')

  print('[Market] ✅ Initialization complete!')
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

  Market = nil
  print('[Market] Terminated')
end

function Market.online()
  print('[Market] Player online, ready to use market')
end

function Market.offline()
  offers = {}
  selectedOffer = nil
  if marketWindow then
    marketWindow:hide()
  end
  print('[Market] Player offline')
end

function Market.toggle()
  print('[Market] toggle() called')
  
  if not marketWindow then 
    print('[Market] ERROR: marketWindow is nil!')
    return 
  end
  
  print('[Market] marketWindow exists, checking visibility...')
  
  if marketWindow:isVisible() then
    print('[Market] Window is visible, hiding...')
    marketWindow:hide()
  else
    print('[Market] Window is hidden, showing...')
    marketWindow:show()
    marketWindow:raise()
    marketWindow:focus()
    print('[Market] ✅ Window should be visible now!')
  end
end

function Market.populateCategories()
  if not categoryList then return end
  
  categoryList:destroyChildren()
  
  for _, category in ipairs(categories) do
    local label = categoryList:addItem(category.name)
    label.categoryId = category.id
  end
  
  print('[Market] ' .. #categories .. ' categories populated')
end

function Market.onCategorySelect(categoryList, focusedChild)
  if not focusedChild then return end
  
  selectedCategory = focusedChild.categoryId or 0
  print(string.format('[Market] Category selected: %d (%s)', selectedCategory, focusedChild:getText()))
  
  -- Clear offers list (will be populated by server response)
  if offersList then
    offersList:destroyChildren()
  end
  
  -- Show demo offers for now
  Market.showDemoOffers()
end

function Market.showDemoOffers()
  if not offersList then return end
  
  offersList:destroyChildren()
  
  -- Demo offers
  local demoOffers = {
    {itemName = "Magic Sword", amount = 1, price = 10000, playerName = "Seller1", itemId = 2400},
    {itemName = "Demon Armor", amount = 1, price = 50000, playerName = "Seller2", itemId = 2494},
    {itemName = "Crusader Helmet", amount = 1, price = 8000, playerName = "Seller3", itemId = 2497},
    {itemName = "Great Health Potion", amount = 100, price = 15000, playerName = "Seller4", itemId = 239},
  }
  
  for _, offer in ipairs(demoOffers) do
    local text = string.format('%s (x%d) - %d gp - by %s', 
      offer.itemName, offer.amount, offer.price, offer.playerName)
    local label = offersList:addItem(text)
    label.offer = offer
  end
  
  print('[Market] ' .. #demoOffers .. ' demo offers displayed')
end

function Market.onOfferSelect(offersList, focusedChild)
  if not focusedChild then return end
  
  selectedOffer = focusedChild.offer
  
  if not selectedOffer then return end
  
  -- Update item preview
  if itemPreview then
    itemPreview:setItemId(selectedOffer.itemId)
  end
  
  -- Update labels
  if itemNameLabel then
    itemNameLabel:setText(selectedOffer.itemName)
  end
  
  if priceLabel then
    priceLabel:setText(string.format('Price: %d gp', selectedOffer.price))
  end
  
  if amountLabel then
    amountLabel:setText(string.format('Amount: %d', selectedOffer.amount))
  end
  
  if sellerLabel then
    sellerLabel:setText(string.format('Seller: %s', selectedOffer.playerName))
  end
  
  print(string.format('[Market] Selected: %s (%d gp)', selectedOffer.itemName, selectedOffer.price))
end

function Market.onBuyClick()
  print('[Market] Buy button clicked')
  displayInfoBox('Market', 'Buy functionality - Coming soon!')
end

function Market.onSellClick()
  print('[Market] Sell button clicked')
  displayInfoBox('Market', 'Sell functionality - Coming soon!')
end

function Market.onRefreshClick()
  print('[Market] Refresh button clicked')
  displayInfoBox('Market', 'Refresh functionality - Coming soon!')
end

function Market.onMyOffersClick()
  print('[Market] My Offers button clicked')
  displayInfoBox('Market', 'My Offers functionality - Coming soon!')
end

function Market.onSearchChange()
  print('[Market] Search changed')
end

print('[Market 7.72] Module loaded')
