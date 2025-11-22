-- Enhanced effects module for custom sprite sizes
-- This module allows effects to be rendered at custom sizes (e.g., 64x64 instead of 32x32)

CONST_ME_CRITICAL_DAMAGE = 173

local effect173ThingType = nil
local originalSpriteSize = nil

function init()
  -- Try to get ThingType for effect 173 and modify it if possible
  if g_things and g_things.getThingType then
    effect173ThingType = g_things.getThingType(CONST_ME_CRITICAL_DAMAGE, ThingCategoryEffect)
    
    if effect173ThingType then
      print("✅ Effect 173 ThingType encontrado")
      
      -- Try to modify sprite size if API allows
      -- Note: This may not work if the API doesn't support modification
      if effect173ThingType.setSize then
        effect173ThingType:setSize({width = 64, height = 64})
        print("💡 Tentando definir tamanho do sprite para 64x64")
      elseif effect173ThingType.setSpriteSize then
        effect173ThingType:setSpriteSize(64, 64)
        print("💡 Tentando definir sprite size para 64x64")
      else
        print("⚠️  API não permite modificar tamanho do sprite via Lua")
        print("💡 Tentando criar shader customizado para escalar o efeito")
        createEffectShader()
      end
    else
      print("⚠️  Effect 173 ThingType não encontrado ainda")
      print("💡 Tentando novamente após carregar things...")
      scheduleEvent(function()
        effect173ThingType = g_things.getThingType(CONST_ME_CRITICAL_DAMAGE, ThingCategoryEffect)
        if effect173ThingType then
          print("✅ Effect 173 ThingType encontrado (tentativa 2)")
        end
      end, 1000)
    end
  end
  
  connect(g_game, {
    onMagicEffect = onMagicEffect
  })
  
  print("✅ Enhanced effects module loaded")
  print("💡 Effect 173 (Critical Damage) - tentando renderizar em 64x64")
end

function terminate()
  disconnect(g_game, {
    onMagicEffect = onMagicEffect
  })
end

function onMagicEffect(position, effectId)
  -- Debug: Log todos os efeitos recebidos
  if effectId == CONST_ME_CRITICAL_DAMAGE then
    print("[CLIENT DEBUG] Effect 173 (Critical Damage) recebido em: " .. position.x .. "," .. position.y .. "," .. position.z)
  elseif effectId == 6 then  -- CONST_ME_EXPLOSIONHIT
    print("[CLIENT DEBUG] ⚠️ Effect 6 (EXPLOSIONHIT) recebido em: " .. position.x .. "," .. position.y .. "," .. position.z)
  elseif effectId == 5 then  -- CONST_ME_EXPLOSIONAREA
    print("[CLIENT DEBUG] ⚠️ Effect 5 (EXPLOSIONAREA) recebido em: " .. position.x .. "," .. position.y .. "," .. position.z)
  end
end

function createEffectShader()
  -- Criar shader customizado para escalar efeito 173
  -- Isso requer modificação dos shaders do mapa
  if g_shaders and g_shaders.createShader then
    -- Nota: Shaders precisam ser criados em game_shaders/shaders.lua
    -- Vamos apenas registrar que precisamos do shader
    print("💡 Para suporte completo de 64x64, crie um shader customizado")
    print("   que detecte o efeito 173 e o escale 2x")
  end
end

