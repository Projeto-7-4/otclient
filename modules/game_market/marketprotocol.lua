-- Market Protocol for 7.72
-- Adapted from mehah's OTClient for Nostalrius 7.72 protocol
MarketProtocol = {}

local silent
local protocol
local statistics = runinsandbox('offerstatistic')

-- Send message to server
local function send(msg)
  if protocol and not silent then
    protocol:send(msg)
  end
end

-- Read market offer from message (simplified for 7.72)
local function readMarketOffer(msg)
  local offerId = msg:getU32()
  local playerId = msg:getU32()
  local playerName = msg:getString()
  local itemId = msg:getU16()
  local itemName = msg:getString()
  local amount = msg:getU16()
  local price = msg:getU32()
  local category = msg:getU8()
  local timestamp = msg:getU32()
  
  return {
    id = offerId,
    playerId = playerId,
    playerName = playerName,
    itemId = itemId,
    itemName = itemName,
    amount = amount,
    price = price,
    category = category,
    timestamp = timestamp,
    item = Item.create(itemId)
  }
end

-- Parse market offers list (0xF0)
local function parseMarketOffers(protocol, msg)
  local count = msg:getU16()
  local offers = {}
  
  for i = 1, count do
    table.insert(offers, readMarketOffer(msg))
  end
  
  print(string.format('[MarketProtocol] Received %d offers from server', count))
  signalcall(Market.onMarketBrowse, offers)
  return true
end

-- Parse buy response (0xF1)
local function parseMarketBuyResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  print(string.format('[MarketProtocol] Buy response: %s - %s', success and 'SUCCESS' or 'FAILED', message))
  signalcall(Market.onMarketBuyResponse, success, message)
  return true
end

-- Parse sell response (0xF2)
local function parseMarketSellResponse(protocol, msg)
  local success = msg:getU8() == 1
  local message = msg:getString()
  
  print(string.format('[MarketProtocol] Sell response: %s - %s', success and 'SUCCESS' or 'FAILED', message))
  signalcall(Market.onMarketSellResponse, success, message)
  return true
end

-- Initialize protocol
function initProtocol()
  connect(g_game, { 
    onGameStart = MarketProtocol.registerProtocol,
    onGameEnd = MarketProtocol.unregisterProtocol 
  })

  if g_game.isOnline() then
    MarketProtocol.registerProtocol()
  end

  MarketProtocol.silent(false)
  print('[MarketProtocol] Initialized for 7.72')
end

-- Terminate protocol
function terminateProtocol()
  disconnect(g_game, { 
    onGameStart = MarketProtocol.registerProtocol,
    onGameEnd = MarketProtocol.unregisterProtocol 
  })

  MarketProtocol.unregisterProtocol()
  MarketProtocol = nil
  print('[MarketProtocol] Terminated')
end

-- Update protocol reference
function MarketProtocol.updateProtocol(_protocol)
  protocol = _protocol
end

-- Register opcodes for 7.72
function MarketProtocol.registerProtocol()
  -- Using extended opcodes for 7.72
  ProtocolGame.registerExtendedOpcode(0xF0, parseMarketOffers)
  ProtocolGame.registerExtendedOpcode(0xF1, parseMarketBuyResponse)
  ProtocolGame.registerExtendedOpcode(0xF2, parseMarketSellResponse)
  
  MarketProtocol.updateProtocol(g_game.getProtocolGame())
  print('[MarketProtocol] Opcodes registered (0xF0-0xF2)')
end

-- Unregister opcodes
function MarketProtocol.unregisterProtocol()
  ProtocolGame.unregisterExtendedOpcode(0xF0)
  ProtocolGame.unregisterExtendedOpcode(0xF1)
  ProtocolGame.unregisterExtendedOpcode(0xF2)
  
  MarketProtocol.updateProtocol(nil)
  print('[MarketProtocol] Opcodes unregistered')
end

-- Silent mode
function MarketProtocol.silent(mode)
  silent = mode
end

-- ============================================================================
-- SENDING PROTOCOLS (Client -> Server)
-- ============================================================================

-- Request offers list (0xF0)
function MarketProtocol.sendMarketBrowse(category)
  local msg = OutputMessage.create()
  msg:addU8(0xF0)  -- Request offers
  msg:addU16(category or 0)  -- 0 = all categories
  send(msg)
  print(string.format('[MarketProtocol] Requesting offers (category: %d)', category or 0))
end

-- Buy offer (0xF1)
function MarketProtocol.sendMarketAcceptOffer(offerId, amount)
  local msg = OutputMessage.create()
  msg:addU8(0xF1)  -- Buy offer
  msg:addU32(offerId)
  msg:addU16(amount)
  send(msg)
  print(string.format('[MarketProtocol] Buying offer %d (amount: %d)', offerId, amount))
end

-- Create sell offer (0xF2)
function MarketProtocol.sendMarketCreateOffer(itemId, amount, price)
  local msg = OutputMessage.create()
  msg:addU8(0xF2)  -- Create offer
  msg:addU16(itemId)
  msg:addU16(amount)
  msg:addU32(price)
  send(msg)
  print(string.format('[MarketProtocol] Creating offer (item: %d, amount: %d, price: %d)', itemId, amount, price))
end

-- Cancel offer (0xF3)
function MarketProtocol.sendMarketCancelOffer(offerId)
  local msg = OutputMessage.create()
  msg:addU8(0xF3)  -- Cancel offer
  msg:addU32(offerId)
  send(msg)
  print(string.format('[MarketProtocol] Cancelling offer %d', offerId))
end

-- Request my offers (0xF4)
function MarketProtocol.sendMarketBrowseMyOffers()
  local msg = OutputMessage.create()
  msg:addU8(0xF4)  -- My offers
  send(msg)
  print('[MarketProtocol] Requesting my offers')
end

-- Compatibility aliases for existing Market module
MarketProtocol.sendMarketBrowseMyHistory = MarketProtocol.sendMarketBrowseMyOffers
MarketProtocol.sendMarketLeave = function() end -- Not needed for 7.72

print('[MarketProtocol] Module loaded for 7.72')
