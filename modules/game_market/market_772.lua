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

  -- Get components (optional for now - just testing)
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
  
  print('[Market] Components loaded')

  -- Connect events (only if components exist)
  if categoryList then
    categoryList.onChildFocusChange = Market.onCategorySelect
    print('[Market] Connected categoryList events')
  end
  
  if offersList then
    offersList.onChildFocusChange = Market.onOfferSelect
    print('[Market] Connected offersList events')
  end
  
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
  print('[Market] Events connected')

  -- Populate categories (only if list exists)
  if categoryList then
    Market.populateCategories()
  end

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
  
  print('[Market] Categories populated')
end

function Market.onCategorySelect(categoryList, focusedChild)
  if not focusedChild then return end
  
  selectedCategory = focusedChild.categoryId or 0
  print(string.format('[Market] Category selected: %d', selectedCategory))
end

function Market.onOfferSelect(offersList, focusedChild)
  if not focusedChild then return end
  
  selectedOffer = focusedChild.offer
  print(string.format('[Market] Selected offer: %s', selectedOffer and selectedOffer.itemName or 'none'))
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
