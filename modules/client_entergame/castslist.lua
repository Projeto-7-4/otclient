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
  
  -- Verificar se está conectado
  if not g_game.isOnline() then
    g_logger.info('[CastsList] Not connected to server, showing instruction message')
    local label = g_ui.createWidget('Label', castsList)
    label:setText('Please connect to the server first to see active casts.\n\nSteps:\n1. Login to the game\n2. Open this window again\n3. Click Refresh to see active casts')
    label:setPhantom(true)
    label:setTextAlign(AlignTopLeft)
    return
  end
  
  -- Adicionar mensagem de carregamento
  local loadingLabel = g_ui.createWidget('Label', castsList)
  loadingLabel:setId('loadingLabel')
  loadingLabel:setText('Loading casts from server...')
  loadingLabel:setPhantom(true)
  
  g_logger.info('[CastsList] Requesting casts from server...')
  
  -- Requisitar casts do servidor via protocolo
  if CastProtocol then
    local success = CastProtocol.requestCastList()
    if not success then
      loadingLabel:setText('Failed to request cast list. Click Refresh to try again.')
    end
  else
    g_logger.error('[CastsList] CastProtocol not loaded!')
    loadingLabel:setText('Error: Cast protocol not loaded')
  end
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

