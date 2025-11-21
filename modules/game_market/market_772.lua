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
local selectedCategoryWidget = nil
local selectedOfferWidget = nil

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

  -- Get components using recursiveGetChildById (classic syntax)
  categoryList = marketWindow:recursiveGetChildById('categoryList')
  offersList = marketWindow:recursiveGetChildById('offersList')
  buyButton = marketWindow:recursiveGetChildById('buyButton')
  sellButton = marketWindow:recursiveGetChildById('sellButton')
  refreshButton = marketWindow:recursiveGetChildById('refreshButton')
  myOffersButton = marketWindow:recursiveGetChildById('myOffersButton')
  searchEdit = marketWindow:recursiveGetChildById('searchEdit')
  itemPreview = marketWindow:recursiveGetChildById('itemPreview')
  itemNameLabel = marketWindow:recursiveGetChildById('itemNameLabel')
  priceLabel = marketWindow:recursiveGetChildById('priceLabel')
  amountLabel = marketWindow:recursiveGetChildById('amountLabel')
  sellerLabel = marketWindow:recursiveGetChildById('sellerLabel')
  
  -- Debug: check which components exist
  if not categoryList then print('[Market] WARNING: categoryList not found') end
  if not offersList then print('[Market] WARNING: offersList not found') end
  if not buyButton then print('[Market] WARNING: buyButton not found') end
  if not sellButton then print('[Market] WARNING: sellButton not found') end
  if not refreshButton then print('[Market] WARNING: refreshButton not found') end
  
  print('[Market] Components loaded')

  -- Connect button events (direct onClick)
  if buyButton then
    buyButton.onClick = Market.onBuyClick
  end
  
  if sellButton then
    sellButton.onClick = Market.onSellClick
  end
  
  if refreshButton then
    refreshButton.onClick = Market.onRefreshClick
  end
  
  if myOffersButton then
    myOffersButton.onClick = Market.onMyOffersClick
  end
  
  if searchEdit then
    searchEdit.onTextChange = Market.onSearchChange
  end
  
  print('[Market] Button events connected')

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
    -- Create widget manually (like Shop does)
    local label = g_ui.createWidget('Label', categoryList)
    label:setText(category.name)
    label:setPhantom(false)
    label.categoryId = category.id
    label:setHeight(20)
    label:setTextAlign(AlignLeft)
    label:setMarginLeft(5)
    label:setBackgroundColor('#00000055')
    
    -- Make it clickable with visual selection
    label.onClick = function()
      -- Remove highlight from previous selection
      if selectedCategoryWidget then
        selectedCategoryWidget:setBackgroundColor('#00000055')
      end
      
      -- Highlight this one
      label:setBackgroundColor('#ffffff44')
      selectedCategoryWidget = label
      
      selectedCategory = category.id
      print('[Market] Category clicked: ' .. category.name)
      Market.showDemoOffers()
    end
    
    -- Select "All Items" by default
    if i == 1 then
      label:setBackgroundColor('#ffffff44')
      selectedCategoryWidget = label
    end
    
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
  
  -- Demo offers com IDs básicos/comuns do Tibia 7.72
  local allOffers = {
    -- Weapons (IDs básicos)
    {itemName = "Sword", amount = 1, price = 500, playerName = "Warrior99", itemId = 2376, category = 1},
    {itemName = "Two Handed Sword", amount = 1, price = 950, playerName = "Knight_Pro", itemId = 2377, category = 1},
    {itemName = "Axe", amount = 1, price = 500, playerName = "Axe_Master", itemId = 2386, category = 1},
    {itemName = "Club", amount = 1, price = 500, playerName = "Club_Guy", itemId = 2382, category = 1},
    
    -- Armors (IDs básicos)
    {itemName = "Plate Armor", amount = 1, price = 4000, playerName = "Armor_Shop", itemId = 2463, category = 2},
    {itemName = "Chain Armor", amount = 1, price = 700, playerName = "Dealer_Pro", itemId = 2464, category = 2},
    {itemName = "Leather Armor", amount = 1, price = 300, playerName = "Newbie_Store", itemId = 2467, category = 2},
    
    -- Shields (IDs básicos)
    {itemName = "Wooden Shield", amount = 1, price = 150, playerName = "Shield_Guy", itemId = 2512, category = 3},
    {itemName = "Steel Shield", amount = 1, price = 800, playerName = "Tank_Pro", itemId = 2509, category = 3},
    {itemName = "Battle Shield", amount = 1, price = 350, playerName = "Warrior_Shop", itemId = 2513, category = 3},
    
    -- Helmets (IDs básicos)
    {itemName = "Helmet", amount = 1, price = 580, playerName = "Helmet_Shop", itemId = 2458, category = 4},
    {itemName = "Chain Helmet", amount = 1, price = 350, playerName = "Armor_Guy", itemId = 2457, category = 4},
    {itemName = "Brass Helmet", amount = 1, price = 200, playerName = "Dealer_Store", itemId = 2460, category = 4},
    
    -- Legs (IDs básicos)
    {itemName = "Plate Legs", amount = 1, price = 1200, playerName = "Legs_Shop", itemId = 2647, category = 5},
    {itemName = "Chain Legs", amount = 1, price = 300, playerName = "Armor_Store", itemId = 2648, category = 5},
    
    -- Boots (IDs básicos)
    {itemName = "Leather Boots", amount = 1, price = 200, playerName = "Boot_Shop", itemId = 2643, category = 6},
    {itemName = "Steel Boots", amount = 1, price = 800, playerName = "Premium_Store", itemId = 2645, category = 6},
    
    -- Potions (IDs básicos)
    {itemName = "Health Potion", amount = 100, price = 5000, playerName = "Potion_Store", itemId = 236, category = 10},
    {itemName = "Mana Potion", amount = 100, price = 5000, playerName = "Mana_Shop", itemId = 268, category = 10},
    
    -- Others
    {itemName = "Rope", amount = 50, price = 500, playerName = "Tool_Shop", itemId = 2120, category = 11},
    {itemName = "Shovel", amount = 10, price = 300, playerName = "Tool_Store", itemId = 2554, category = 11},
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
  
  -- Add to list (using createWidget like Shop)
  for _, offer in ipairs(filteredOffers) do
    local text = string.format('%s (x%d) - %d gp - %s', 
      offer.itemName, offer.amount, offer.price, offer.playerName)
    
    -- Create widget manually
    local label = g_ui.createWidget('Label', offersList)
    label:setText(text)
    label:setPhantom(false)
    label.offer = offer
    label:setHeight(20)
    label:setTextAlign(AlignLeft)
    label:setMarginLeft(5)
    label:setBackgroundColor('#00000055')
    
    -- Make it clickable with visual selection
    label.onClick = function()
      -- Remove highlight from previous selection
      if selectedOfferWidget then
        selectedOfferWidget:setBackgroundColor('#00000055')
      end
      
      -- Highlight this one
      label:setBackgroundColor('#ffffff44')
      selectedOfferWidget = label
      
      Market.onOfferSelect(offersList, label)
    end
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
