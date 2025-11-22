CastsList = {}

local castsWindow
local castsList
local availableCasts = {}

function CastsList.init()
  castsWindow = g_ui.loadUI('castslist', rootWidget)
  castsWindow:hide()
  
  castsList = castsWindow:getChildById('castsList')
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
  if not castsWindow then
    return
  end
  
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
  if not castsList then
    return
  end
  
  castsList:destroyChildren()
  availableCasts = {}
  
  -- Buscar casts ativos do servidor
  -- Por enquanto, vamos criar casts de exemplo
  -- TODO: Implementar requisição ao servidor para listar casts
  
  -- Exemplo de casts (remover quando implementar a requisição real)
  local exampleCasts = {
    {name = "Mage", viewers = 5, description = "Hunting Dragons"},
    {name = "Knight", viewers = 3, description = "Training Skills"},
    {name = "Paladin", viewers = 8, description = "PvP Action"}
  }
  
  -- Tentar buscar casts do servidor
  local success, casts = pcall(CastsList.fetchCastsFromServer)
  if success and casts and #casts > 0 then
    availableCasts = casts
  else
    availableCasts = exampleCasts
  end
  
  -- Adicionar casts à lista
  for i, cast in ipairs(availableCasts) do
    local label = g_ui.createWidget('Label', castsList)
    label:setId('cast_' .. i)
    label:setText(string.format('%s (%d viewers) - %s', cast.name, cast.viewers, cast.description or ''))
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
    label:setText('No active casts found')
    label:setPhantom(true)
  end
end

function CastsList.fetchCastsFromServer()
  -- TODO: Implementar requisição HTTP ou protocolo customizado
  -- para buscar lista de casts ativos do servidor
  
  -- Por enquanto retorna nil para usar os exemplos
  return nil
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

