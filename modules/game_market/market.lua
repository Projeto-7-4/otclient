Market = {}

-- Estado do market
Market.offers = {}
local marketWindow

function Market.init()
  -- Criar botão simples
  Market.createButton()
  
  print("[Market] Module initialized - Press F10 to open")
end

function Market.terminate()
  if marketWindow then
    marketWindow:destroy()
    marketWindow = nil
  end
  
  if Market.button then
    Market.button:destroy()
    Market.button = nil
  end
  
  print("[Market] Module terminated")
end

function Market.createButton()
  -- Tentar criar botão no top menu
  local topMenu = modules.client_topmenu
  if topMenu then
    Market.button = topMenu.addLeftButton('marketButton', 'Market (F10)', '/images/topbuttons/market', Market.toggle)
  end
  
  -- Registrar atalho F10
  g_keyboard.bindKeyPress('F10', Market.toggle)
  
  print("[Market] Button and hotkey F10 registered")
end

function Market.toggle()
  if not marketWindow then
    Market.createWindow()
  end
  
  if marketWindow:isVisible() then
    marketWindow:hide()
    print("[Market] Window hidden")
  else
    marketWindow:show()
    marketWindow:raise()
    marketWindow:focus()
    Market.requestOffers()
    print("[Market] Window shown")
  end
end

function Market.createWindow()
  marketWindow = g_ui.createWidget('MarketWindow', rootWidget)
  
  -- Conectar eventos
  local buyButton = marketWindow:recursiveGetChildById('buyButton')
  local sellButton = marketWindow:recursiveGetChildById('sellButton')
  local refreshButton = marketWindow:recursiveGetChildById('refreshButton')
  local closeButton = marketWindow:recursiveGetChildById('closeButton')
  
  if buyButton then
    buyButton.onClick = function() Market.showBuyWindow() end
  end
  
  if sellButton then
    sellButton.onClick = function() Market.showSellWindow() end
  end
  
  if refreshButton then
    refreshButton.onClick = function() Market.requestOffers() end
  end
  
  if closeButton then
    closeButton.onClick = function() marketWindow:hide() end
  end
  
  marketWindow:hide()
  print("[Market] Window created")
end

function Market.requestOffers()
  if not g_game.isOnline() then
    print("[Market] Not connected to server")
    return
  end
  
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    print("[Market] Protocol not available")
    return
  end
  
  local msg = OutputMessage.create()
  msg:addU8(0xF0) -- Opcode para requisitar ofertas
  msg:addU16(0) -- Category (0 = all)
  protocolGame:send(msg)
  
  print("[Market] Requesting offers from server")
end

function Market.showBuyWindow()
  local buyWindow = g_ui.displayUI('buydialog')
  if buyWindow then
    local okButton = buyWindow:getChildById('buttonOk')
    okButton.onClick = function()
      buyWindow:destroy()
    end
  end
end

function Market.showSellWindow()
  local infoWindow = displayInfoBox('Market', 'Sell functionality coming soon!')
end

-- Receber ofertas do servidor
function Market.parseOffers(protocol, msg)
  local count = msg:getU16()
  
  Market.offers = {}
  
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
    
    table.insert(Market.offers, offer)
  end
  
  print(string.format("[Market] Received %d offers from server", count))
  Market.updateOffersList()
end

function Market.updateOffersList()
  if not marketWindow then return end
  
  local offersList = marketWindow:recursiveGetChildById('offersList')
  if not offersList then return end
  
  offersList:destroyChildren()
  
  for _, offer in ipairs(Market.offers) do
    local label = g_ui.createWidget('Label', offersList)
    label:setText(string.format('%s - %d gp (x%d) - by %s', 
      offer.itemName, offer.price, offer.amount, offer.playerName))
  end
  
  print(string.format("[Market] Updated list with %d offers", #Market.offers))
end

-- Resposta de compra
function Market.parseBuyResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  if success then
    displayInfoBox('Market', 'Purchase successful: ' .. message)
  else
    displayErrorBox('Market', 'Purchase failed: ' .. message)
  end
end

-- Resposta de venda
function Market.parseSellResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  if success then
    displayInfoBox('Market', 'Sale successful: ' .. message)
  else
    displayErrorBox('Market', 'Sale failed: ' .. message)
  end
end

-- Registrar parsers de protocolo
function Market.registerProtocolParsers()
  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    ProtocolGame.registerExtendedOpcode(0xF0, Market.parseOffers)
    ProtocolGame.registerExtendedOpcode(0xF1, Market.parseBuyResponse)
    ProtocolGame.registerExtendedOpcode(0xF2, Market.parseSellResponse)
    print("[Market] Protocol parsers registered")
  else
    print("[Market] WARNING: Could not register protocol parsers")
  end
end

-- Inicializar
Market.init()
Market.registerProtocolParsers()
