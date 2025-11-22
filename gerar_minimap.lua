-- Script para gerar minimap completo a partir do map.otbm
-- Execute no OTClient com: Ctrl+T e cole este script

print("===========================================")
print("🗺️  GERADOR DE MINIMAP COMPLETO")
print("===========================================")

-- Verifica se está logado
if g_game.isOnline() then
    print("❌❌❌ ERRO CRÍTICO! ❌❌❌")
    print("")
    print("   Você está LOGADO no servidor!")
    print("")
    print("⚠️  SIGA ESTAS INSTRUÇÕES:")
    print("   1. DESLOGUE do servidor (saia do jogo)")
    print("   2. FECHE o OTClient completamente")
    print("   3. ABRA o OTClient novamente")
    print("   4. NÃO LOGUE no servidor!")
    print("   5. Pressione Ctrl+T e execute este script")
    print("")
    print("===========================================")
    return
end

print("✅ Cliente não está logado - OK!")
print("")

-- Verifica se o arquivo existe
if not g_resources.fileExists('/data/map.otbm') then
    print("❌ ERROR: Arquivo map.otbm não encontrado em /data/")
    print("   Copie o arquivo map.otbm do servidor para otclient/data/")
    return
end

print("✅ Arquivo map.otbm encontrado - OK!")
print("")

-- Aguarda um pouco para garantir que tudo está carregado
print("📂 Preparando para carregar o mapa...")
print("⏳ Aguarde...")

-- Pequeno delay
local startTime = g_clock.millis()
while g_clock.millis() - startTime < 2000 do
    -- Aguarda 2 segundos
end

print("")
print("📂 Carregando map.otbm (70MB)...")
print("⏳ Isso pode demorar 5-10 minutos...")
print("⏳ O cliente VAI TRAVAR - é NORMAL!")
print("⏳ NÃO FECHE O CLIENTE!")
print("")

-- Carrega o mapa
local mapSuccess, mapError = pcall(function()
    g_map.loadOtbm('/data/map.otbm')
end)

-- Aguarda mais um pouco após o carregamento
local startTime2 = g_clock.millis()
while g_clock.millis() - startTime2 < 1000 do
    -- Aguarda 1 segundo
end

-- Verifica se o mapa realmente foi carregado
local tilesCarregadas = 0
if g_map.getWidth() > 0 and g_map.getHeight() > 0 then
    print("✅ Mapa carregado: " .. g_map.getWidth() .. "x" .. g_map.getHeight())
    tilesCarregadas = g_map.getWidth() * g_map.getHeight()
else
    print("❌ ERRO: Mapa não foi carregado corretamente!")
    print("")
    print("⚠️  POSSÍVEIS CAUSAS:")
    print("   1. Você ainda está com módulos de jogo ativos")
    print("   2. O arquivo map.otbm está corrompido")
    print("   3. O cliente precisa ser reiniciado")
    print("")
    print("SOLUÇÃO:")
    print("   1. FECHE o cliente completamente")
    print("   2. ABRA novamente (NÃO logue!)")
    print("   3. Execute este script imediatamente")
    return
end

print("💾 Salvando minimap...")
print("⏳ Aguarde mais um pouco...")
print("")

-- Salva o minimap
local saveSuccess, saveError = pcall(function()
    g_minimap.saveOtmm('/minimap772.otmm')
end)

if not saveSuccess then
    print("❌ ERRO ao salvar minimap: " .. tostring(saveError))
    return
end

print("")
print("✅✅✅ MINIMAP GERADO COM SUCESSO! ✅✅✅")
print("")
print("📊 ESTATÍSTICAS:")
print("   Área do mapa: " .. g_map.getWidth() .. "x" .. g_map.getHeight())
print("")
print("📍 Local do arquivo:")
print("   Windows: %APPDATA%\\otclient\\minimap772.otmm")
print("   Linux/Mac: ~/.otclient/minimap772.otmm")
print("")
print("📋 PRÓXIMOS PASSOS:")
print("   1. Vá até a pasta %APPDATA%\\otclient\\")
print("      (Cole isso na barra do Windows Explorer)")
print("   2. Copie o arquivo minimap772.otmm")
print("   3. Cole em: otclient/data/minimap772.otmm")
print("   4. Cole também em: otclient/minimap772.otmm")
print("   5. Reinicie o cliente e logue no servidor")
print("===========================================")
