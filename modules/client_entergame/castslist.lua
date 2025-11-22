CastsList = {}

local castsWindow
local castsList
local availableCasts = {}

function CastsList.init()
  g_logger.info('[CastsList] Initializing...')
  castsWindow = g_ui.displayUI('castslist')
  if not castsWindow then
    g_logger.error('[CastsList] Failed to load casts list window')
    return
  end
  g_logger.info('[CastsList] Window loaded successfully')
  castsWindow:hide()
  
  castsList = castsWindow:getChildById('castsList')
  if not castsList then
    g_logger.error('[CastsList] Failed to get castsList widget')
  else
    g_logger.info('[CastsList] Initialized successfully')
  end
end

function CastsList.terminate()
  if castsWindow then
    castsWindow:destroy()
    castsWindow = nil
  end
  castsList = nil
  availableCasts = {}
end

function CastsList.show()
  g_logger.info('[CastsList] show() called')
  if not castsWindow then
    g_logger.error('[CastsList] castsWindow is nil!')
    return
  end
  
  g_logger.info('[CastsList] Showing window...')
  castsWindow:show()
  castsWindow:raise()
  castsWindow:focus()
  
  CastsList.refresh()
end

function CastsList.hide()
  if castsWindow then
    castsWindow:hide()
  end
end

function CastsList.refresh()
  g_logger.info('[CastsList] refresh() called')
  if not castsList then
    g_logger.error('[CastsList] castsList is nil!')
    return
  end
  
  castsList:destroyChildren()
  availableCasts = {}
  
  -- Adicionar mensagem de carregamento
  local loadingLabel = g_ui.createWidget('Label', castsList)
  loadingLabel:setId('loadingLabel')
  loadingLabel:setText('Connecting to server...')
  loadingLabel:setPhantom(true)
  
  g_logger.info('[CastsList] Connecting to server to fetch cast list...')
  
  -- Se já está online, requisitar diretamente
  if g_game.isOnline() then
    loadingLabel:setText('Loading casts from server...')
    if CastProtocol then
      local success = CastProtocol.requestCastList()
      if not success then
        loadingLabel:setText('Failed to request cast list. Click Refresh to try again.')
      end
    else
      g_logger.error('[CastsList] CastProtocol not loaded!')
      loadingLabel:setText('Error: Cast protocol not loaded')
    end
  else
    -- Se não está online, usar o mesmo servidor configurado no login
    CastsList.connectToFetchCasts()
  end
end

function CastsList.connectToFetchCasts()
  g_logger.info('[CastsList] Attempting to connect to server to fetch casts...')
  
  -- Pegar configurações do servidor da tela de login
  local host = g_settings.get('host') or '192.168.0.36:7172'
  local clientVersion = tonumber(g_settings.get('client-version')) or 772
  
  g_logger.info('[CastsList] Using server: ' .. host .. ', version: ' .. clientVersion)
  
  -- Criar um ProtocolLogin temporário
  local tempProtocol = ProtocolLogin.create()
  
  tempProtocol.onConnect = function()
    g_logger.info('[CastsList] Connected! Requesting cast list...')
  end
  
  tempProtocol.onError = function(protocol, message)
    g_logger.error('[CastsList] Connection error: ' .. message)
    CastsList.showErrorMessage('Failed to connect to server: ' .. message)
  end
  
  -- Fazer a conexão
  local server_params = host:split(":")
  local server_ip = server_params[1]
  local server_port = tonumber(server_params[2]) or 7172
  
  g_logger.info('[CastsList] Connecting to ' .. server_ip .. ':' .. server_port .. '...')
  
  -- Usar HTTP se disponível, senão mostrar mensagem
  CastsList.fetchCastsViaHTTP(host)
end

function CastsList.fetchCastsViaHTTP(host)
  -- Tentar via HTTP primeiro
  local serverIp = host:split(':')[1]
  local httpUrl = 'http://' .. serverIp .. '/casts.php'
  
  g_logger.info('[CastsList] Fetching casts via HTTP: ' .. httpUrl)
  
  HTTP.getJSON(httpUrl, function(data, err)
    if err then
      g_logger.error('[CastsList] HTTP error: ' .. err)
      -- Tentar IP local da VPS
      httpUrl = 'http://192.168.0.36/casts.php'
      g_logger.info('[CastsList] Trying local IP: ' .. httpUrl)
      
      HTTP.getJSON(httpUrl, function(data2, err2)
        if err2 then
          g_logger.error('[CastsList] HTTP error on retry: ' .. err2)
          CastsList.showMockCasts()
          return
        end
        
        CastsList.processCastsData(data2)
      end)
      return
    end
    
    CastsList.processCastsData(data)
  end)
end

function CastsList.processCastsData(data)
  g_logger.info('[CastsList] Processing casts data: ' .. type(data))
  
  if not data then
    g_logger.error('[CastsList] Data is nil!')
    CastsList.showMockCasts()
    return
  end
  
  -- Parse JSON response
  if type(data) == 'table' then
    g_logger.info('[CastsList] Data is table. Keys: ' .. table.concat(table.keys(data), ', '))
    
    if data.success then
      g_logger.info('[CastsList] API success = true')
      
      if data.casts then
        local count = data.count or #data.casts
        g_logger.info('[CastsList] Found ' .. count .. ' casts')
        
        if count > 0 then
          CastsList.updateCastList(data.casts)
        else
          CastsList.showNoCastsMessage()
        end
      else
        g_logger.error('[CastsList] No casts field in response')
        CastsList.showMockCasts()
      end
    else
      g_logger.error('[CastsList] API returned error: ' .. (data.error or 'unknown'))
      CastsList.showMockCasts()
    end
  else
    g_logger.error('[CastsList] Invalid data type received: ' .. type(data))
    CastsList.showMockCasts()
  end
end

function CastsList.showNoCastsMessage()
  if not castsList then
    return
  end
  
  castsList:destroyChildren()
  
  local label = g_ui.createWidget('Label', castsList)
  label:setText('No active casts at the moment.\n\nTo start casting:\n1. Login to the game\n2. Type: /cast on\n3. Others can watch you!')
  label:setPhantom(true)
  label:setTextAlign(AlignTopLeft)
  label:setColor('#ffff00')
end

function CastsList.showMockCasts()
  -- Mostrar casts de exemplo enquanto não tem conexão real
  g_logger.info('[CastsList] Showing mock casts for demonstration')
  
  local mockCasts = {
    {
      name = "Example Player 1",
      viewers = 12,
      description = "Hunting Dragons",
      password = false
    },
    {
      name = "Example Player 2",
      viewers = 5,
      description = "PvP Action",
      password = true
    },
    {
      name = "Example Player 3",
      viewers = 8,
      description = "Training Skills",
      password = false
    }
  }
  
  CastsList.updateCastList(mockCasts)
  
  -- Adicionar nota explicativa
  scheduleEvent(function()
    if castsList then
      local noteLabel = g_ui.createWidget('Label', castsList)
      noteLabel:setText('\n\nNote: These are example casts.\nReal casts will appear when someone uses /cast on in-game.')
      noteLabel:setPhantom(true)
      noteLabel:setColor('#ffff00')
    end
  end, 100)
end

function CastsList.showErrorMessage(message)
  if not castsList then
    return
  end
  
  castsList:destroyChildren()
  
  local label = g_ui.createWidget('Label', castsList)
  label:setText('Error: ' .. message .. '\n\nClick Refresh to try again.')
  label:setPhantom(true)
  label:setColor('#ff0000')
end

function CastsList.updateCastList(casts)
  g_logger.info('[CastsList] updateCastList() called with ' .. #casts .. ' casts')
  
  if not castsList then
    g_logger.error('[CastsList] castsList is nil!')
    return
  end
  
  -- Limpar lista
  castsList:destroyChildren()
  availableCasts = casts
  
  -- Adicionar casts à lista
  for i, cast in ipairs(availableCasts) do
    local label = g_ui.createWidget('Label', castsList)
    label:setId('cast_' .. i)
    
    local passwordIcon = cast.password and '🔒 ' or ''
    label:setText(string.format('%s%s (%d viewers) - %s', passwordIcon, cast.name, cast.viewers, cast.description or 'No description'))
    label:setPhantom(false)
    label:setFocusable(true)
    label.castData = cast
    
    label.onClick = function(self)
      CastsList.selectCast(self)
    end
    
    label.onDoubleClick = function(self)
      CastsList.selectCast(self)
      CastsList.watchSelectedCast()
    end
  end
  
  if #availableCasts == 0 then
    local label = g_ui.createWidget('Label', castsList)
    label:setText('No active casts found. Start casting with /cast on')
    label:setPhantom(true)
  end
  
  g_logger.info('[CastsList] Cast list updated successfully')
end

function CastsList.selectCast(widget)
  if not castsList then
    return
  end
  
  -- Remover seleção anterior
  for _, child in pairs(castsList:getChildren()) do
    child:setBackgroundColor('#00000000')
  end
  
  -- Selecionar novo
  widget:setBackgroundColor('#ffffff22')
  castsList.selectedCast = widget.castData
end

function CastsList.watchSelectedCast()
  if not castsList or not castsList.selectedCast then
    displayErrorBox('Error', 'Please select a cast to watch')
    return
  end
  
  local cast = castsList.selectedCast
  
  -- Pedir senha se o cast for protegido
  if cast.password then
    local passwordWindow = displayTextBox('Cast Password', 'Enter the password for ' .. cast.name .. ':', function(password)
      CastsList.connectToCast(cast, password)
    end)
    return
  end
  
  CastsList.connectToCast(cast)
end

function CastsList.connectToCast(cast, password)
  if not cast then
    return
  end
  
  -- Fechar janela de casts
  CastsList.hide()
  
  -- Conectar ao cast
  -- Usa o mesmo sistema de login mas com prefixo especial
  local castAccount = 'CAST_' .. cast.name
  local castPassword = password or ''
  
  g_logger.info('Connecting to cast: ' .. cast.name)
  
  -- Usar o sistema de login existente
  EnterGame.doLogin(castAccount, castPassword)
end

