-- Item Tooltip System
-- Requests and caches item descriptions from server

ItemTooltip = {}

-- Cache de descrições de itens: [itemId] = "description"
local descriptionCache = {}

-- Items que estão sendo requisitados (para evitar requests duplicados)
local pendingRequests = {}

-- Callbacks aguardando descrição
local waitingCallbacks = {}

function ItemTooltip.init()
  -- Register protocol handler for item descriptions (opcode 0xFE = 254)
  ProtocolGame.registerOpcode(254, ItemTooltip.onReceiveItemDescription)
end

function ItemTooltip.terminate()
  descriptionCache = {}
  pendingRequests = {}
  waitingCallbacks = {}
end

function ItemTooltip.requestDescription(itemId, count, callback)
  if not itemId or itemId == 0 then
    return false
  end
  
  -- Check cache first
  local cacheKey = itemId .. ":" .. (count or 1)
  if descriptionCache[cacheKey] then
    if callback then
      callback(descriptionCache[cacheKey])
    end
    return true
  end
  
  -- Check if already requesting
  if pendingRequests[cacheKey] then
    if callback then
      if not waitingCallbacks[cacheKey] then
        waitingCallbacks[cacheKey] = {}
      end
      table.insert(waitingCallbacks[cacheKey], callback)
    end
    return true
  end
  
  -- Mark as pending
  pendingRequests[cacheKey] = true
  if callback then
    waitingCallbacks[cacheKey] = {callback}
  end
  
  -- Send request to server
  
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(0xFE) -- Item info request opcode
    msg:addU16(itemId)
    msg:addU8(count or 1)
    protocolGame:send(msg)
    return true
  else
    pendingRequests[cacheKey] = nil
    return false
  end
end

function ItemTooltip.onReceiveItemDescription(protocol, msg)
  local itemId = msg:getU16()
  local description = msg:getString()
  local count = 1 -- We'll use count=1 as default for cache
  
  local cacheKey = itemId .. ":" .. count
  
  -- Store in cache
  descriptionCache[cacheKey] = description
  
  -- Mark as no longer pending
  pendingRequests[cacheKey] = nil
  
  -- Call waiting callbacks
  if waitingCallbacks[cacheKey] then
    for _, callback in ipairs(waitingCallbacks[cacheKey]) do
      callback(description)
    end
    waitingCallbacks[cacheKey] = nil
  end
end

function ItemTooltip.getDescription(itemId, count)
  local cacheKey = itemId .. ":" .. (count or 1)
  return descriptionCache[cacheKey]
end

function ItemTooltip.clearCache()
  descriptionCache = {}
  pendingRequests = {}
  waitingCallbacks = {}
end

