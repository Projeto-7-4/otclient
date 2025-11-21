-- Market System for 7.72
-- Simplified version adapted for Nostalrius protocol
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

  -- Load UI
  print('[Market] Loading market.otui...')
  
  -- Try different methods to get parent widget
  local parentWidget = nil
  if g_ui.getRootWidget then
    parentWidget = g_ui.getRootWidget()
    print('[Market] Using g_ui.getRootWidget()')
  elseif rootWidget then
    parentWidget = rootWidget
    print('[Market] Using rootWidget')
  elseif modules and modules.game_interface and modules.game_interface.getMapPanel then
    parentWidget = modules.game_interface.getMapPanel():getParent()
    print('[Market] Using MapPanel parent')
  end
  
  local success, result = pcall(function()
    if parentWidget then
      return g_ui.loadUI('market', parentWidget)
    else
      return g_ui.loadUI('market')
    end
  end)
  
  if success and result then
    marketWindow = result
    print('[Market] ✅ UI loaded successfully!')
  else
    print('[Market] ❌ ERROR: Failed to load market.otui')
    print('[Market] Error:', result)
    return
  end
  
  marketWindow:hide()
  print('[Market] Window hidden')

  -- Get components
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
  
  -- Check critical components
  if not categoryList then print('[Market] WARNING: categoryList not found') end
  if not offersList then print('[Market] WARNING: offersList not found') end
  if not buyButton then print('[Market] WARNING: buyButton not found') end
  print('[Market] Components loaded')

  -- Connect events
  if categoryList then
    categoryList.onChildFocusChange = Market.onCategorySelect
  end
  
  if offersList then
    offersList.onChildFocusChange = Market.onOfferSelect
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

  -- Populate categories
  Market.populateCategories()

  -- Register hotkey
  g_keyboard.bindKeyDown('Ctrl+M', Market.toggle)
  print('[Market] Hotkey registered')

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
    Market.requestOffers()
    print('[Market] Window should be visible now!')
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
  Market.requestOffers()
end

function Market.requestOffers()
  if not g_game.isOnline() then
    print('[Market] Cannot request offers: not online')
    return
  end
  
  protocol.sendMarketBrowse(selectedCategory)
end

function Market.onMarketBrowse(receivedOffers)
  offers = receivedOffers or {}
  print(string.format('[Market] Browse received %d offers', #offers))
  Market.refreshOffers()
end

function Market.refreshOffers()
  if not offersList then return end
  
  offersList:destroyChildren()
  
  local searchText = searchEdit and searchEdit:getText():lower() or ""
  local filteredOffers = {}
  
  for _, offer in ipairs(offers) do
    local matchesSearch = searchText == "" or offer.itemName:lower():find(searchText, 1, true)
    if matchesSearch then
      table.insert(filteredOffers, offer)
    end
  end
  
  for _, offer in ipairs(filteredOffers) do
    local text = string.format('%s (x%d) - %d gp - by %s', 
      offer.itemName, offer.amount, offer.price, offer.playerName)
    local label = offersList:addItem(text)
    label.offer = offer
  end
  
  print(string.format('[Market] Displaying %d filtered offers', #filteredOffers))
end

function Market.onOfferSelect(offersList, focusedChild)
  if not focusedChild then return end
  
  selectedOffer = focusedChild.offer
  
  if selectedOffer and itemPreview then
    itemPreview:setItemId(selectedOffer.itemId)
  end
  
  if selectedOffer and itemNameLabel then
    itemNameLabel:setText(selectedOffer.itemName)
  end
  
  if selectedOffer and priceLabel then
    priceLabel:setText(string.format('Price: %d gp', selectedOffer.price))
  end
  
  if selectedOffer and amountLabel then
    amountLabel:setText(string.format('Amount: %d', selectedOffer.amount))
  end
  
  if selectedOffer and sellerLabel then
    sellerLabel:setText(string.format('Seller: %s', selectedOffer.playerName))
  end
  
  print(string.format('[Market] Selected offer: %s', selectedOffer and selectedOffer.itemName or 'none'))
end

function Market.onBuyClick()
  if not selectedOffer then
    displayInfoBox('Market', 'Please select an offer first.')
    return
  end
  
  Market.showBuyWindow(selectedOffer)
end

function Market.showBuyWindow(offer)
  local window = g_ui.createWidget('MainWindow', rootWidget)
  window:setId('buyWindow')
  window:setText('Buy Item')
  window:setSize({width = 300, height = 200})
  window:centerIn('parent')
  
  -- Item name
  local nameLabel = g_ui.createWidget('Label', window)
  nameLabel:setText(offer.itemName)
  nameLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  nameLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  nameLabel:setMarginTop(20)
  nameLabel:setTextAlign(AlignCenter)
  
  -- Price
  local priceLabel = g_ui.createWidget('Label', window)
  priceLabel:setText(string.format('Price per unit: %d gp', offer.price))
  priceLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  priceLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  priceLabel:setMarginTop(10)
  
  -- Amount label
  local amountLabel = g_ui.createWidget('Label', window)
  amountLabel:setText('Amount:')
  amountLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  amountLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  amountLabel:setMarginTop(15)
  amountLabel:setMarginLeft(20)
  
  -- Amount edit
  local amountEdit = g_ui.createWidget('TextEdit', window)
  amountEdit:setText('1')
  amountEdit:addAnchor(AnchorTop, 'prev', AnchorTop)
  amountEdit:addAnchor(AnchorLeft, 'prev', AnchorRight)
  amountEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
  amountEdit:setMarginLeft(10)
  amountEdit:setMarginRight(20)
  
  -- Total label
  local totalLabel = g_ui.createWidget('Label', window)
  totalLabel:setText('Total: 0 gp')
  totalLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  totalLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  totalLabel:setMarginTop(10)
  
  -- Update total
  local function updateTotal()
    local amount = tonumber(amountEdit:getText()) or 0
    local total = amount * offer.price
    totalLabel:setText(string.format('Total: %d gp', total))
  end
  
  amountEdit.onTextChange = updateTotal
  updateTotal()
  
  -- Buttons
  local confirmButton = g_ui.createWidget('Button', window)
  confirmButton:setText('Confirm')
  confirmButton:setWidth(100)
  confirmButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  confirmButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  confirmButton:setMarginBottom(10)
  confirmButton:setMarginLeft(20)
  confirmButton.onClick = function()
    local amount = tonumber(amountEdit:getText()) or 0
    if amount <= 0 or amount > offer.amount then
      displayErrorBox('Market', 'Invalid amount!')
      return
    end
    
    protocol.sendMarketAcceptOffer(offer.id, amount)
    window:destroy()
  end
  
  local cancelButton = g_ui.createWidget('Button', window)
  cancelButton:setText('Cancel')
  cancelButton:setWidth(100)
  cancelButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  cancelButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  cancelButton:setMarginBottom(10)
  cancelButton:setMarginRight(20)
  cancelButton.onClick = function()
    window:destroy()
  end
end

function Market.onSellClick()
  Market.showSellWindow()
end

function Market.showSellWindow()
  local window = g_ui.createWidget('MainWindow', rootWidget)
  window:setId('sellWindow')
  window:setText('Sell Item')
  window:setSize({width = 300, height = 250})
  window:centerIn('parent')
  
  -- Item ID label
  local idLabel = g_ui.createWidget('Label', window)
  idLabel:setText('Item ID:')
  idLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  idLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  idLabel:setMarginTop(20)
  idLabel:setMarginLeft(20)
  
  -- Item ID edit
  local idEdit = g_ui.createWidget('TextEdit', window)
  idEdit:addAnchor(AnchorTop, 'prev', AnchorTop)
  idEdit:addAnchor(AnchorLeft, 'prev', AnchorRight)
  idEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
  idEdit:setMarginLeft(10)
  idEdit:setMarginRight(20)
  
  -- Amount label
  local amountLabel = g_ui.createWidget('Label', window)
  amountLabel:setText('Amount:')
  amountLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  amountLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  amountLabel:setMarginTop(15)
  amountLabel:setMarginLeft(20)
  
  -- Amount edit
  local amountEdit = g_ui.createWidget('TextEdit', window)
  amountEdit:setText('1')
  amountEdit:addAnchor(AnchorTop, 'prev', AnchorTop)
  amountEdit:addAnchor(AnchorLeft, 'prev', AnchorRight)
  amountEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
  amountEdit:setMarginLeft(10)
  amountEdit:setMarginRight(20)
  
  -- Price label
  local priceLabel = g_ui.createWidget('Label', window)
  priceLabel:setText('Price (per unit):')
  priceLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  priceLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  priceLabel:setMarginTop(15)
  priceLabel:setMarginLeft(20)
  
  -- Price edit
  local priceEdit = g_ui.createWidget('TextEdit', window)
  priceEdit:addAnchor(AnchorTop, 'prev', AnchorTop)
  priceEdit:addAnchor(AnchorLeft, 'prev', AnchorRight)
  priceEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
  priceEdit:setMarginLeft(10)
  priceEdit:setMarginRight(20)
  
  -- Tax label
  local taxLabel = g_ui.createWidget('Label', window)
  taxLabel:setText('Tax: 5% (will be deducted)')
  taxLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
  taxLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  taxLabel:setMarginTop(10)
  taxLabel:setColor('#ffaa00')
  
  -- Buttons
  local confirmButton = g_ui.createWidget('Button', window)
  confirmButton:setText('Confirm')
  confirmButton:setWidth(100)
  confirmButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  confirmButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  confirmButton:setMarginBottom(10)
  confirmButton:setMarginLeft(20)
  confirmButton.onClick = function()
    local itemId = tonumber(idEdit:getText()) or 0
    local amount = tonumber(amountEdit:getText()) or 0
    local price = tonumber(priceEdit:getText()) or 0
    
    if itemId <= 0 or amount <= 0 or price <= 0 then
      displayErrorBox('Market', 'Invalid values!')
      return
    end
    
    protocol.sendMarketCreateOffer(itemId, amount, price)
    window:destroy()
  end
  
  local cancelButton = g_ui.createWidget('Button', window)
  cancelButton:setText('Cancel')
  cancelButton:setWidth(100)
  cancelButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  cancelButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  cancelButton:setMarginBottom(10)
  cancelButton:setMarginRight(20)
  cancelButton.onClick = function()
    window:destroy()
  end
end

function Market.onRefreshClick()
  Market.requestOffers()
end

function Market.onMyOffersClick()
  protocol.sendMarketBrowseMyOffers()
end

function Market.onSearchChange()
  Market.refreshOffers()
end

-- Protocol callbacks
function Market.onMarketBuyResponse(success, message)
  if success then
    displayInfoBox('Market', message)
    Market.requestOffers()
  else
    displayErrorBox('Market', message)
  end
end

function Market.onMarketSellResponse(success, message)
  if success then
    displayInfoBox('Market', message)
    Market.requestOffers()
  else
    displayErrorBox('Market', message)
  end
end

print('[Market 7.72] Module loaded')

