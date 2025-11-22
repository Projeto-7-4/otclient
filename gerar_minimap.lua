-- Script para gerar minimap completo a partir do map.otbm
-- Execute no OTClient com: Ctrl+T e cole este script

print("===========================================")
print("🗺️  GERADOR DE MINIMAP COMPLETO")
print("===========================================")

-- IMPORTANTE: Feche o cliente e abra novamente antes de executar este script!
print("⚠️  IMPORTANTE:")
print("   1. Feche TODOS os módulos de jogo abertos")
print("   2. NÃO esteja logado no servidor")
print("")

-- Verifica se o arquivo existe
if not g_resources.fileExists('/data/map.otbm') then
    print("❌ ERROR: Arquivo map.otbm não encontrado em /data/")
    print("   Copie o arquivo map.otbm do servidor para otclient/data/")
    return
end

-- Aguarda um pouco para garantir que tudo está carregado
print("📂 Preparando para carregar o mapa...")
print("⏳ Aguarde...")

-- Pequeno delay
local startTime = g_clock.millis()
while g_clock.millis() - startTime < 2000 do
    -- Aguarda 2 segundos
end

print("📂 Carregando map.otbm...")
print("⏳ Isso pode demorar 5-10 minutos...")
print("⏳ O cliente VAI TRAVAR - é NORMAL!")
print("⏳ NÃO FECHE O CLIENTE!")
print("")

-- Carrega o mapa
local mapSuccess, mapError = pcall(function()
    g_map.loadOtbm('/data/map.otbm')
end)

if not mapSuccess then
    print("❌ ERRO ao carregar o mapa: " .. tostring(mapError))
    print("")
    print("POSSÍVEIS SOLUÇÕES:")
    print("1. Feche o cliente completamente")
    print("2. Abra novamente (NÃO logue no servidor)")
    print("3. Pressione Ctrl+T e execute o script novamente")
    return
end

print("✅ Mapa carregado com sucesso!")
print("💾 Salvando minimap...")

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
print("📍 Local do arquivo:")
print("   Windows: %APPDATA%\\otclient\\minimap772.otmm")
print("   Linux/Mac: ~/.otclient/minimap772.otmm")
print("")
print("📋 PRÓXIMOS PASSOS:")
print("   1. Vá até a pasta %APPDATA%\\otclient\\")
print("   2. Copie o arquivo minimap772.otmm")
print("   3. Cole em: otclient/data/minimap772.otmm")
print("   4. Cole também em: otclient/minimap772.otmm")
print("   5. Reinicie o cliente e logue no servidor")
print("===========================================")
