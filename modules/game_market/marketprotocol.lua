-- =============================================
-- MARKET PROTOCOL FOR 7.72
-- =============================================

MarketProtocol = {}

local protocol
local protocolRegistered = false  -- Flag para evitar registro duplo

local MarketOpcodes = {
  -- Client -> Server
  ClientMarketBrowse = 0xF0,
  ClientMarketCreate = 0xF1,
  ClientMarketCancel = 0xF2,
  ClientMarketAccept = 0xF3,
  
  -- Server -> Client (usando 0xEC - opcode não usado em 7.72)
  ServerMarketOffers = 0xEC,
}

local function send(msg)
  if protocol then
    protocol:send(msg)
  end
end

-- =============================================
-- PARSING FUNCTIONS (Server -> Client)
-- =============================================

local function parseMarketOffers(protocol, msg)
  print('[MarketProtocol] Parsing market offers...')
  
  local offers = {}
  local offerCount = msg:getU8()
  
  print('[MarketProtocol] Received ' .. offerCount .. ' offers')
  
  for i = 1, offerCount do
    local offer = {
      id = msg:getU32(),
      itemId = msg:getU16(),
      amount = msg:getU16(),
      price = msg:getU32(),
      type = msg:getU8(),
      playerName = msg:getString(),
      secondsRemaining = msg:getU32()
    }
    
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
  
  signalcall(Market.onOffersReceived, offers)
  return true
end

-- =============================================
-- PROTOCOL REGISTRATION
-- =============================================

function initProtocol()
  connect(g_game, { 
    onGameStart = MarketProtocol.registerProtocol,
    onGameEnd = MarketProtocol.unregisterProtocol 
  })
  
  if g_game.isOnline() then
    MarketProtocol.registerProtocol()
  end
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
  
  ProtocolGame.registerOpcode(MarketOpcodes.ServerMarketOffers, parseMarketOffers)
  
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
  msg:addU8(offerType or 2) -- 0 = buy, 1 = sell, 2 = all
  send(msg)
  print('[MarketProtocol] Requested market browse (type: ' .. (offerType or 2) .. ')')
end

function MarketProtocol.sendMarketCreate(offerType, itemId, amount, price)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketCreate)
  msg:addU8(offerType) -- 0 = buy, 1 = sell
  msg:addU16(itemId)
  msg:addU16(amount)
  msg:addU32(price)
  send(msg)
  print('[MarketProtocol] Creating offer: ' .. offerType .. ', item ' .. itemId .. ', amount ' .. amount .. ', price ' .. price)
end

function MarketProtocol.sendMarketCancel(offerId)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketCancel)
  msg:addU32(offerId)
  send(msg)
  print('[MarketProtocol] Cancelling offer: ' .. offerId)
end

function MarketProtocol.sendMarketAccept(offerId, amount)
  local msg = OutputMessage.create()
  msg:addU8(MarketOpcodes.ClientMarketAccept)
  msg:addU32(offerId)
  msg:addU16(amount)
  send(msg)
  print('[MarketProtocol] Accepting offer: ' .. offerId .. ', amount ' .. amount)
end

-- Auto-initialize protocol
initProtocol()

print('[MarketProtocol] 7.72 Market Protocol module loaded and initialized')

-- Return the protocol table for use by market_772.lua
return MarketProtocol
