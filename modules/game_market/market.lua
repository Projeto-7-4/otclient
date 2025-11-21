Market = {}

-- Configurações
Market.config = {
  TAX_RATE = 0.05, -- 5% de taxa
  MAX_OFFERS = 100,
  MIN_PRICE = 1,
  MAX_PRICE = 999999999
}

-- Estado do market
Market.offers = {
  buy = {},
  sell = {}
}

Market.categories = {
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

local marketWindow
local categoryList
local offersList
local buyButton
local sellButton
local myOffersButton
local searchEdit
local itemPreview
local selectedCategory = nil
local selectedOffer = nil

function Market.init()
  connect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })

  marketWindow = g_ui.loadUI('market', modules.game_interface.getRightPanel())
  marketWindow:setVisible(false)

  -- Componentes da UI
  categoryList = marketWindow:recursiveGetChildById('categoryList')
  offersList = marketWindow:recursiveGetChildById('offersList')
  buyButton = marketWindow:recursiveGetChildById('buyButton')
  sellButton = marketWindow:recursiveGetChildById('sellButton')
  myOffersButton = marketWindow:recursiveGetChildById('myOffersButton')
  searchEdit = marketWindow:recursiveGetChildById('searchEdit')
  itemPreview = marketWindow:recursiveGetChildById('itemPreview')

  -- Conectar eventos
  categoryList.onChildFocusChange = Market.onCategorySelect
  offersList.onChildFocusChange = Market.onOfferSelect
  buyButton.onClick = Market.onBuyClick
  sellButton.onClick = Market.onSellClick
  myOffersButton.onClick = Market.onMyOffersClick
  searchEdit.onTextChange = Market.onSearchChange

  -- Popular categorias
  Market.populateCategories()

  -- Adicionar botão no top menu
  Market.addMenuButton()

  print("[Market] Module initialized")
end

function Market.terminate()
  disconnect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })

  if marketWindow then
    marketWindow:destroy()
    marketWindow = nil
  end

  Market.removeMenuButton()
  
  print("[Market] Module terminated")
end

function Market.online()
  -- Requisitar lista de ofertas do servidor
  Market.requestOffers()
end

function Market.offline()
  Market.offers = {buy = {}, sell = {}}
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
    Market.requestOffers()
  end
end

function Market.addMenuButton()
  local gameInterface = modules.game_interface
  if not gameInterface then return end

  local topMenu = gameInterface.getTopMenu()
  if not topMenu then return end

  Market.menuButton = topMenu:addChild(g_ui.createWidget('TopButton', topMenu))
  Market.menuButton:setId('marketButton')
  Market.menuButton:setText('Market')
  Market.menuButton:setTooltip('Market (Ctrl+M)')
  Market.menuButton.onClick = Market.toggle
  
  g_keyboard.bindKeyPress('Ctrl+M', Market.toggle)
end

function Market.removeMenuButton()
  if Market.menuButton then
    Market.menuButton:destroy()
    Market.menuButton = nil
  end
  g_keyboard.unbindKeyPress('Ctrl+M')
end

function Market.populateCategories()
  if not categoryList then return end
  
  categoryList:destroyChildren()
  
  -- Adicionar "All" category
  local allLabel = g_ui.createWidget('MarketCategoryLabel', categoryList)
  allLabel:setText('All Items')
  allLabel.categoryId = 0
  
  -- Adicionar outras categorias
  for _, category in ipairs(Market.categories) do
    local label = g_ui.createWidget('MarketCategoryLabel', categoryList)
    label:setText(category.name)
    label.categoryId = category.id
  end
end

function Market.onCategorySelect(categoryList, focusedChild)
  if not focusedChild then return end
  
  selectedCategory = focusedChild.categoryId
  Market.refreshOffers()
end

function Market.refreshOffers()
  if not offersList then return end
  
  offersList:destroyChildren()
  
  local searchText = searchEdit:getText():lower()
  
  -- Filtrar e exibir ofertas
  for _, offer in ipairs(Market.offers.sell) do
    local shouldShow = true
    
    -- Filtrar por categoria
    if selectedCategory and selectedCategory > 0 and offer.category ~= selectedCategory then
      shouldShow = false
    end
    
    -- Filtrar por busca
    if searchText ~= "" and not offer.itemName:lower():find(searchText) then
      shouldShow = false
    end
    
    if shouldShow then
      Market.addOfferToList(offer)
    end
  end
end

function Market.addOfferToList(offer)
  local label = g_ui.createWidget('MarketOfferLabel', offersList)
  label:setText(string.format('%s - %d gp (x%d)', offer.itemName, offer.price, offer.amount))
  label.offerId = offer.id
  label.offer = offer
end

function Market.onOfferSelect(offersList, focusedChild)
  if not focusedChild then return end
  
  selectedOffer = focusedChild.offer
  
  -- Atualizar preview do item
  if itemPreview and selectedOffer then
    itemPreview:setItemId(selectedOffer.itemId)
  end
end

function Market.onBuyClick()
  if not selectedOffer then
    g_logger.warning("[Market] No offer selected")
    return
  end
  
  -- Abrir janela de confirmação
  Market.showBuyWindow(selectedOffer)
end

function Market.showBuyWindow(offer)
  local buyWindow = g_ui.createWidget('MarketBuyWindow', rootWidget)
  
  local itemName = buyWindow:recursiveGetChildById('itemName')
  local priceLabel = buyWindow:recursiveGetChildById('priceLabel')
  local amountEdit = buyWindow:recursiveGetChildById('amountEdit')
  local totalLabel = buyWindow:recursiveGetChildById('totalLabel')
  local confirmButton = buyWindow:recursiveGetChildById('confirmButton')
  local cancelButton = buyWindow:recursiveGetChildById('cancelButton')
  
  itemName:setText(offer.itemName)
  priceLabel:setText(string.format('Price per unit: %d gp', offer.price))
  amountEdit:setText('1')
  
  local function updateTotal()
    local amount = tonumber(amountEdit:getText()) or 0
    local total = amount * offer.price
    totalLabel:setText(string.format('Total: %d gp', total))
  end
  
  amountEdit.onTextChange = updateTotal
  updateTotal()
  
  confirmButton.onClick = function()
    local amount = tonumber(amountEdit:getText()) or 0
    if amount <= 0 or amount > offer.amount then
      g_logger.warning("[Market] Invalid amount")
      return
    end
    
    Market.sendBuyRequest(offer.id, amount)
    buyWindow:destroy()
  end
  
  cancelButton.onClick = function()
    buyWindow:destroy()
  end
end

function Market.onSellClick()
  -- Abrir janela para vender item
  Market.showSellWindow()
end

function Market.showSellWindow()
  local sellWindow = g_ui.createWidget('MarketSellWindow', rootWidget)
  
  local itemEdit = sellWindow:recursiveGetChildById('itemEdit')
  local priceEdit = sellWindow:recursiveGetChildById('priceEdit')
  local amountEdit = sellWindow:recursiveGetChildById('amountEdit')
  local confirmButton = sellWindow:recursiveGetChildById('confirmButton')
  local cancelButton = sellWindow:recursiveGetChildById('cancelButton')
  
  confirmButton.onClick = function()
    local itemId = tonumber(itemEdit:getText()) or 0
    local price = tonumber(priceEdit:getText()) or 0
    local amount = tonumber(amountEdit:getText()) or 0
    
    if itemId <= 0 or price < Market.config.MIN_PRICE or amount <= 0 then
      g_logger.warning("[Market] Invalid values")
      return
    end
    
    Market.sendSellRequest(itemId, amount, price)
    sellWindow:destroy()
  end
  
  cancelButton.onClick = function()
    sellWindow:destroy()
  end
end

function Market.onMyOffersClick()
  -- Exibir apenas as ofertas do player
  print("[Market] My offers clicked")
end

function Market.onSearchChange(widget, newText)
  Market.refreshOffers()
end

-- Funções de protocolo
function Market.requestOffers()
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  
  local msg = OutputMessage.create()
  msg:addU8(0xF0) -- Opcode para requisitar ofertas
  msg:addU16(0) -- Category (0 = all)
  protocolGame:send(msg)
  
  print("[Market] Requesting offers from server")
end

function Market.sendBuyRequest(offerId, amount)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  
  local msg = OutputMessage.create()
  msg:addU8(0xF1) -- Opcode para comprar
  msg:addU32(offerId)
  msg:addU16(amount)
  protocolGame:send(msg)
  
  print(string.format("[Market] Buying offer %d (amount: %d)", offerId, amount))
end

function Market.sendSellRequest(itemId, amount, price)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  
  local msg = OutputMessage.create()
  msg:addU8(0xF2) -- Opcode para vender
  msg:addU16(itemId)
  msg:addU16(amount)
  msg:addU32(price)
  protocolGame:send(msg)
  
  print(string.format("[Market] Selling item %d (amount: %d, price: %d)", itemId, amount, price))
end

-- Receber ofertas do servidor
function Market.parseOffers(protocol, msg)
  local count = msg:getU16()
  
  Market.offers.sell = {}
  
  for i = 1, count do
    local offer = {
      id = msg:getU32(),
      playerId = msg:getU32(),
      playerName = msg:getString(),
      itemId = msg:getU16(),
      itemName = msg:getString(),
      amount = msg:getU16(),
      price = msg:getU32(),
      category = msg:getU8(),
      timestamp = msg:getU32()
    }
    
    table.insert(Market.offers.sell, offer)
  end
  
  print(string.format("[Market] Received %d offers from server", count))
  Market.refreshOffers()
end

-- Resposta de compra
function Market.parseBuyResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  if success then
    g_logger.info(string.format("[Market] Purchase successful: %s", message))
    Market.requestOffers() -- Atualizar lista
  else
    g_logger.warning(string.format("[Market] Purchase failed: %s", message))
  end
end

-- Resposta de venda
function Market.parseSellResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  if success then
    g_logger.info(string.format("[Market] Sale successful: %s", message))
    Market.requestOffers() -- Atualizar lista
  else
    g_logger.warning(string.format("[Market] Sale failed: %s", message))
  end
end

-- Registrar parsers de protocolo
function Market.registerProtocolParsers()
  ProtocolGame.registerExtendedOpcode(0xF0, Market.parseOffers)
  ProtocolGame.registerExtendedOpcode(0xF1, Market.parseBuyResponse)
  ProtocolGame.registerExtendedOpcode(0xF2, Market.parseSellResponse)
end

-- Inicializar quando o módulo for carregado
Market.init()
Market.registerProtocolParsers()
