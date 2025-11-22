CastProtocol = {}

-- Opcodes
local CastOpcodes = {
    ClientRequestCastList = 0xF5,
    ServerCastList = 0xF6
}

function CastProtocol.init()
    g_logger.info('[CastProtocol] Initializing...')
    
    -- Registrar opcode para receber lista de casts
    ProtocolGame.registerOpcode(CastOpcodes.ServerCastList, CastProtocol.parseCastList)
    
    g_logger.info('[CastProtocol] Initialized successfully')
end

function CastProtocol.terminate()
    g_logger.info('[CastProtocol] Terminating...')
    
    -- Desregistrar opcode
    if ProtocolGame then
        pcall(function()
            ProtocolGame.unregisterOpcode(CastOpcodes.ServerCastList)
        end)
    end
end

function CastProtocol.requestCastList()
  g_logger.info('[CastProtocol] Requesting cast list...')
  
  if g_game.isOnline() then
    -- Se já está online, usar o protocolo existente
    g_logger.info('[CastProtocol] Already connected, using existing protocol')
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
      local msg = OutputMessage.create()
      msg:addU8(CastOpcodes.ClientRequestCastList)
      protocolGame:send(msg)
      return true
    end
  end
  
  -- Se não está online, fazer uma requisição via HTTP ou retornar erro
  g_logger.error('[CastProtocol] Cannot request cast list: not connected to server')
  
  -- Notificar que precisa estar logado
  if CastsList then
    scheduleEvent(function()
      CastsList.showNotConnectedMessage()
    end, 100)
  end
  
  return false
end

function CastProtocol.parseCastList(protocol, msg)
    g_logger.info('[CastProtocol] Received cast list from server')
    
    local casts = {}
    local count = msg:getU16()
    
    g_logger.info('[CastProtocol] Parsing ' .. count .. ' casts')
    
    for i = 1, count do
        local cast = {
            name = msg:getString(),
            viewers = msg:getU16(),
            description = msg:getString(),
            password = msg:getU8() == 1
        }
        table.insert(casts, cast)
        g_logger.info('[CastProtocol] Cast ' .. i .. ': ' .. cast.name .. ' (' .. cast.viewers .. ' viewers)')
    end
    
    -- Atualizar a lista de casts
    if CastsList then
        CastsList.updateCastList(casts)
    end
    
    return true
end

