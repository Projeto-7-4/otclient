-- =============================================
-- MARKET PROTOCOL FOR 7.72
-- =============================================

MarketProtocol = {}

local protocol
local protocolRegistered = false  -- Flag para evitar registro duplo

local MarketOpcodes = {
  -- Client -> Server (alinhado com protocolgame.cpp do servidor)
  ClientMarketBrowse = 0xF0,  -- parseMarketRequestOffers
  ClientMarketBuy = 0xF1,      -- parseMarketBuy (COMPRAR/ACEITAR)
  ClientMarketSell = 0xF2,     -- parseMarketSell (CRIAR OFERTA)
  ClientMarketCancel = 0xF3,   -- parseMarketCancel
  ClientMarketMyOffers = 0xF4, -- parseMarketMyOffers
  ClientMarketHistory = 0xF5,  -- parseMarketHistory (NOVO)
  
  -- Server -> Client
  ServerMarketOffers = 0x32,   -- Lista de ofertas
  ServerMarketBuyResponse = 0xF1,  -- Resposta de compra (success/fail)
  ServerMarketHistory = 0x33,  -- Histórico de transações (NOVO)
}

local function send(msg)
  if protocol then
    protocol:send(msg)
  end
end

-- =============================================
-- PARSING FUNCTIONS (Server -> Client)
-- =============================================

local function parseMarketBuyResponse(protocol, msg)
  print('[MarketProtocol] Parsing buy response...')
  
  local success = msg:getU8()
  local message = msg:getString()
  local updatedGold = msg:getU64()  -- Gold atualizado do servidor
  
  if success == 1 then
    print('[MarketProtocol] ✅ Buy success: ' .. message .. ' (new gold: ' .. updatedGold .. ')')
    
    -- Atualizar gold instantaneamente
    if Market and Market.updatePlayerGold then
      Market.updatePlayerGold(updatedGold)
    end
    
    -- Remover oferta da lista INSTANTANEAMENTE se a compra foi bem-sucedida
    if Market and Market.removeOfferById and Market.getLastPurchasedOfferId then
      local offerId = Market.getLastPurchasedOfferId()
      if offerId then
        Market.removeOfferById(offerId)  -- Instantâneo (0ms)
      end
    end
  else
    print('[MarketProtocol] ❌ Buy failed: ' .. message .. ' (gold: ' .. updatedGold .. ')')
    displayErrorBox('Market - Error', message)
  end
  
  return true
end

local function parseMarketOffers(protocol, msg)
  print('[MarketProtocol] Parsing market offers...')
  
  local offers = {}
  local offerCount = msg:getU8()
  
  -- Read player's bank balance (sent by server)
  local bankBalance = msg:getU64()
  print('[MarketProtocol] Player bank balance: ' .. bankBalance .. ' gp')
  
  -- Read player's GUID (sent by server)
  local playerGUID = msg:getU32()
  print('[MarketProtocol] Player GUID: ' .. playerGUID)
  
  print('[MarketProtocol] Received ' .. offerCount .. ' offers')
  
  for i = 1, offerCount do
    -- Ordem EXATA do servidor (protocolgame.cpp):
    -- 1. id, 2. itemId, 3. itemName (STRING!), 4. amount, 5. price, 6. type, 7. playerName, 8. secondsRemaining
    local offer = {
      id = msg:getU32(),
      itemId = msg:getU16()
    }
    
    -- 3. itemName (String) - NOVO CAMPO!
    offer.name = msg:getString()
    print('[MarketProtocol] Item name: ' .. offer.name)
    
    -- 4. amount, 5. price
    offer.amount = msg:getU16()
    offer.price = msg:getU32()
    
    -- 6. Ler type e converter ASCII para número se necessário
    local rawType = msg:getU8()
    if rawType > 10 then
      rawType = rawType - 48  -- Converter ASCII '0'-'9' (48-57) para 0-9
      print('[MarketProtocol] Converted ASCII ' .. (rawType + 48) .. ' to ' .. rawType)
    end
    offer.type = rawType
    
    -- 7. playerName, 8. secondsRemaining
    offer.playerName = msg:getString()
    offer.secondsRemaining = msg:getU32()
    
    -- Calculate expire time string
    local hours = math.floor(offer.secondsRemaining / 3600)
    local days = math.floor(hours / 24)
    
    if days > 0 then
      offer.expireText = string.format("Expires in %d day%s %dh", days, days > 1 and "s" or "", hours % 24)
    elseif hours > 0 then
      offer.expireText = string.format("Expires in %dh %dmin", hours, math.floor((offer.secondsRemaining % 3600) / 60))
    else
      offer.expireText = string.format("Expires in %dmin", math.floor(offer.secondsRemaining / 60))
    end
    
    -- Format currency
    offer.currencyText = string.format("%d Gold Coin%s", offer.price, offer.price > 1 and "s" or "")
    
    table.insert(offers, offer)
  end
  
  signalcall(Market.onOffersReceived, offers, bankBalance, playerGUID)
  return true
end
local function parseMarketHistory(protocol, msg)
  print('[MarketProtocol] Parsing market history...')
  
  local historyCount = msg:getU8()
  print('[MarketProtocol] Received ' .. historyCount .. ' history items')
  
  local historyItems = {}
  
  for i = 1, historyCount do
    local item = {
      id = msg:getU32(),
      itemId = msg:getU16(),
      itemName = msg:getString(),
      amount = msg:getU16(),
      price = msg:getU32(),
      type = msg:getU8(),  -- 0 = bought, 1 = sold
      date = msg:getString()
    }
    table.insert(historyItems, item)
    print('[MarketProtocol]   - ' .. item.date .. ': ' .. (item.type == 0 and 'Bought' or 'Sold') .. ' ' .. item.amount .. 'x ' .. item.itemName .. ' for ' .. item.price .. ' gp')
  end
  
  -- Enviar para o Market
  signalcall(Market.onHistoryReceived, historyItems)
  return true
end

-- =============================================
-- PROTOCOL REGISTRATION
-- =============================================

function initProtocol()
  print('[MarketProtocol] Initializing protocol module...')
  
  connect(g_game, { 
    onGameStart = MarketProtocol.registerProtocol,
    onGameEnd = MarketProtocol.unregisterProtocol 
  })
  
  -- NÃO chamar registerProtocol() aqui, deixar apenas o onGameStart fazer isso
  -- para evitar registro duplo
  print('[MarketProtocol] Protocol module initialized (will register on game start)')
end

function terminateProtocol()
  disconnect(g_game, { 
    onGameStart = MarketProtocol.registerProtocol,
    onGameEnd = MarketProtocol.unregisterProtocol 
  })
  
  MarketProtocol.unregisterProtocol()
  MarketProtocol = nil
end

function MarketProtocol.updateProtocol(_protocol)
  protocol = _protocol
end

function MarketProtocol.registerProtocol()
  if protocolRegistered then
    print('[MarketProtocol] ⚠️ Protocol already registered, skipping...')
    return
  end
  
  print('[MarketProtocol] Registering protocol handlers...')
  
  -- Primeiro tenta desregistrar (caso já exista)
  pcall(function()
    ProtocolGame.unregisterOpcode(MarketOpcodes.ServerMarketOffers, parseMarketOffers)
    ProtocolGame.unregisterOpcode(MarketOpcodes.ServerMarketBuyResponse, parseMarketBuyResponse)
  end)
  
  -- Agora registra
  ProtocolGame.registerOpcode(MarketOpcodes.ServerMarketOffers, parseMarketOffers)
  ProtocolGame.registerOpcode(MarketOpcodes.ServerMarketBuyResponse, parseMarketBuyResponse)
  ProtocolGame.registerOpcode(MarketOpcodes.ServerMarketHistory, parseMarketHistory)
  
  MarketProtocol.updateProtocol(g_game.getProtocolGame())
  
  protocolRegistered = true
  print('[MarketProtocol] ✅ Protocol handlers registered!')
end

function MarketProtocol.unregisterProtocol()
  if not protocolRegistered then
    print('[MarketProtocol] Protocol not registered, nothing to unregister')
    return
  end
  
  print('[MarketProtocol] Unregistering protocol handlers...')
  
  ProtocolGame.unregisterOpcode(MarketOpcodes.ServerMarketOffers, parseMarketOffers)
  ProtocolGame.unregisterOpcode(MarketOpcodes.ServerMarketBuyResponse, parseMarketBuyResponse)
  ProtocolGame.unregisterOpcode(MarketOpcodes.ServerMarketHistory, parseMarketHistory)
  
  MarketProtocol.updateProtocol(nil)
  
  protocolRegistered = false
  print('[MarketProtocol] Protocol unregistered')
end

-- =============================================
-- SENDING FUNCTIONS (Client -> Server)
-- =============================================

function MarketProtocol.sendMarketBrowse(offerType)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketBrowse)
  
  -- Converter string para número se necessário
  local typeNum = offerType
  if type(offerType) == 'string' then
    if offerType == 'buy' then
      typeNum = 0
    elseif offerType == 'sell' then
      typeNum = 1
    else
      typeNum = 2  -- all
    end
  elseif offerType == nil then
    typeNum = 2  -- all
  end
  
  msg:addU8(typeNum) -- 0 = buy, 1 = sell, 2 = all
  send(msg)
  print('[MarketProtocol] Requested market browse (type: ' .. typeNum .. ')')
end

function MarketProtocol.sendMarketHistory()
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketHistory)  -- 0xF5
  send(msg)
  print('[MarketProtocol] Requested market history')
end

function MarketProtocol.sendMarketCreate(offerType, itemId, amount, price)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketSell)  -- 0xF2 = criar oferta de venda
  msg:addU8(offerType) -- 0 = buy, 1 = sell
  msg:addU16(itemId)
  msg:addU16(amount)
  msg:addU32(price)
  send(msg)
  print('[MarketProtocol] Creating offer: ' .. offerType .. ', item ' .. itemId .. ', amount ' .. amount .. ', price ' .. price)
end

function MarketProtocol.sendMarketCancel(offerId)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketCancel)  -- 0xF3 = cancelar oferta
  msg:addU32(offerId)
  send(msg)
  print('[MarketProtocol] Cancelling offer: ' .. offerId)
end

function MarketProtocol.sendMarketAccept(offerId, amount)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketBuy)  -- 0xF1 = comprar/aceitar oferta
  msg:addU32(offerId)
  msg:addU16(amount)
  send(msg)
  print('[MarketProtocol] Buying/accepting offer: ' .. offerId .. ', amount ' .. amount)
end

-- Auto-initialize protocol
initProtocol()

print('[MarketProtocol] 7.72 Market Protocol module loaded and initialized')

-- Export globally for market_772.lua to access
_G.MarketProtocol = MarketProtocol

-- Also return it (for runinsandbox compatibility)
return MarketProtocol
