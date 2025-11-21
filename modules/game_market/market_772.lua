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
  
  -- Debug: check which components exist
  if not categoryList then print('[Market] WARNING: categoryList not found') end
  if not offersList then print('[Market] WARNING: offersList not found') end
  if not buyButton then print('[Market] WARNING: buyButton not found') end
  if not sellButton then print('[Market] WARNING: sellButton not found') end
  if not refreshButton then print('[Market] WARNING: refreshButton not found') end
  
  print('[Market] Components loaded (modern syntax)')

  -- Connect events (only if widgets exist)
  if categoryList then
    connect(categoryList, { onChildFocusChange = Market.onCategorySelect })
  end
  
  if offersList then
    connect(offersList, { onChildFocusChange = Market.onOfferSelect })
  end
  
  if buyButton then
    connect(buyButton, { onClick = Market.onBuyClick })
  end
  
  if sellButton then
    connect(sellButton, { onClick = Market.onSellClick })
  end
  
  if refreshButton then
    connect(refreshButton, { onClick = Market.onRefreshClick })
  end
  
  if myOffersButton then
    connect(myOffersButton, { onClick = Market.onMyOffersClick })
  end
  
  if searchEdit then
    connect(searchEdit, { onTextChange = Market.onSearchChange })
  end
  
  print('[Market] Events connected')

  -- Populate categories
  print('[Market] Calling populateCategories()...')
  Market.populateCategories()
  
  -- Show demo offers on first category
  print('[Market] Calling showDemoOffers()...')
  Market.showDemoOffers()

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
  print('[Market] populateCategories() called')
  print('[Market] categoryList =', categoryList)
  
  if not categoryList then 
    print('[Market] ERROR: categoryList is nil!')
    return 
  end
  
  print('[Market] Destroying old children...')
  categoryList:destroyChildren()
  
  print('[Market] Adding ' .. #categories .. ' categories...')
  for i, category in ipairs(categories) do
    local label = categoryList:addItem(category.name)
    label.categoryId = category.id
    print('[Market] Added category: ' .. category.name .. ' (id=' .. category.id .. ')')
  end
  
  print('[Market] ✅ ' .. #categories .. ' categories populated!')
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
  
  -- Demo offers by category
  local allOffers = {
    -- Weapons
    {itemName = "Magic Sword", amount = 1, price = 10000, playerName = "Warrior99", itemId = 2400, category = 1},
    {itemName = "Bright Sword", amount = 1, price = 8000, playerName = "Knight_Pro", itemId = 2407, category = 1},
    {itemName = "Fire Axe", amount = 1, price = 12000, playerName = "Axe_Master", itemId = 2432, category = 1},
    
    -- Armors
    {itemName = "Demon Armor", amount = 1, price = 50000, playerName = "Rich_Player", itemId = 2494, category = 2},
    {itemName = "Golden Armor", amount = 1, price = 25000, playerName = "Gold_Seller", itemId = 2466, category = 2},
    {itemName = "Magic Plate Armor", amount = 1, price = 35000, playerName = "Mage_Shop", itemId = 2472, category = 2},
    
    -- Shields
    {itemName = "Vampire Shield", amount = 1, price = 18000, playerName = "Shield_Guy", itemId = 2534, category = 3},
    {itemName = "Demon Shield", amount = 1, price = 30000, playerName = "Tank_Pro", itemId = 2520, category = 3},
    
    -- Helmets
    {itemName = "Crusader Helmet", amount = 1, price = 8000, playerName = "Helmet_Shop", itemId = 2497, category = 4},
    {itemName = "Demon Helmet", amount = 1, price = 40000, playerName = "Elite_Seller", itemId = 2493, category = 4},
    
    -- Potions
    {itemName = "Great Health Potion", amount = 100, price = 15000, playerName = "Potion_Store", itemId = 239, category = 10},
    {itemName = "Great Mana Potion", amount = 100, price = 12000, playerName = "Mana_Shop", itemId = 238, category = 10},
    {itemName = "Ultimate Health Potion", amount = 50, price = 20000, playerName = "Premium_Store", itemId = 237, category = 10},
    
    -- Runes
    {itemName = "Sudden Death Rune", amount = 100, price = 30000, playerName = "Rune_Master", itemId = 2268, category = 9},
    {itemName = "Ultimate Healing Rune", amount = 100, price = 18000, playerName = "Healer_Shop", itemId = 2273, category = 9},
  }
  
  -- Get search text
  local searchText = ""
  if searchEdit then
    searchText = searchEdit:getText():lower()
  end
  
  -- Filter by category and search text
  local filteredOffers = {}
  for _, offer in ipairs(allOffers) do
    local matchesCategory = (selectedCategory == 0 or offer.category == selectedCategory)
    local matchesSearch = (searchText == "" or offer.itemName:lower():find(searchText, 1, true))
    
    if matchesCategory and matchesSearch then
      table.insert(filteredOffers, offer)
    end
  end
  
  -- Add to list
  for _, offer in ipairs(filteredOffers) do
    local text = string.format('%s (x%d) - %d gp - %s', 
      offer.itemName, offer.amount, offer.price, offer.playerName)
    local label = offersList:addItem(text)
    label.offer = offer
  end
  
  print('[Market] ' .. #filteredOffers .. ' offers displayed (category: ' .. selectedCategory .. ')')
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
  if not selectedOffer then
    displayInfoBox('Market', 'Please select an item first!')
    return
  end
  
  print('[Market] Buy button clicked - Item: ' .. selectedOffer.itemName)
  
  local message = string.format(
    'Buy %s (x%d) for %d gold?\n\nThis is a DEMO. Server integration coming soon!',
    selectedOffer.itemName,
    selectedOffer.amount,
    selectedOffer.price
  )
  displayInfoBox('Market - Buy Item', message)
end

function Market.onSellClick()
  print('[Market] Sell button clicked')
  
  local message = 'Sell Item\n\nSelect an item from your inventory to sell.\n\nThis is a DEMO. Server integration coming soon!'
  displayInfoBox('Market - Sell Item', message)
end

function Market.onRefreshClick()
  print('[Market] Refresh button clicked')
  Market.showDemoOffers()
  displayInfoBox('Market', 'Offers refreshed!')
end

function Market.onMyOffersClick()
  print('[Market] My Offers button clicked')
  
  local message = 'My Offers\n\nHere you will see all your active sell offers.\n\nThis is a DEMO. Server integration coming soon!'
  displayInfoBox('Market - My Offers', message)
end

function Market.onSearchChange()
  if not searchEdit then return end
  
  local searchText = searchEdit:getText():lower()
  print('[Market] Search: ' .. searchText)
  
  -- Filter and display offers
  Market.showDemoOffers()
end

print('[Market 7.72] Module loaded')
