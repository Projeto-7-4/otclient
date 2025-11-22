-- Script para gerar minimap completo a partir do map.otbm
-- Execute no OTClient com: Ctrl+T e cole este script

print("===========================================")
print("🗺️  GERADOR DE MINIMAP COMPLETO v2")
print("===========================================")

-- Verifica se está logado
if g_game.isOnline() then
    print("❌❌❌ ERRO CRÍTICO! ❌❌❌")
    print("")
    print("   Você está LOGADO no servidor!")
    print("")
    print("⚠️  DESLOGUE e FECHE o cliente!")
    print("===========================================")
    return
end

print("✅ Cliente não está logado - OK!")
print("")

-- Verifica se o arquivo existe
if not g_resources.fileExists('/data/map.otbm') then
    print("❌ ERROR: Arquivo map.otbm não encontrado em /data/")
    return
end

print("✅ Arquivo map.otbm encontrado - OK!")
print("")

print("📂 Carregando arquivos necessários...")
print("")

-- Tenta carregar os things (dat/spr) se ainda não foram carregados
local thingsLoaded = pcall(function()
    if g_resources.fileExists('/things/772/Tibia.dat') then
        print("   Carregando Tibia.dat...")
        g_game.setClientVersion(772)
        g_game.setProtocolVersion(772)
    end
end)

print("")
print("📂 Carregando map.otbm (70MB)...")
print("⏳ AGUARDE 5-10 MINUTOS!")
print("⏳ Cliente vai TRAVAR - NÃO FECHE!")
print("")

-- Pequeno delay
local startTime = g_clock.millis()
while g_clock.millis() - startTime < 1000 do end

-- Carrega o mapa
local mapSuccess, mapError = pcall(function()
    g_map.loadOtbm('/data/map.otbm')
end)

if not mapSuccess then
    print("")
    print("❌ ERRO ao carregar o mapa!")
    print("   Detalhes: " .. tostring(mapError))
    print("")
    print("⚠️  SOLUÇÃO ALTERNATIVA:")
    print("")
    print("   O OTClient precisa estar com os arquivos")
    print("   .dat e .spr carregados ANTES de executar.")
    print("")
    print("   TENTE ISTO:")
    print("   1. Abra o cliente")
    print("   2. Vá em 'Options' > 'Protocol'")
    print("   3. Certifique-se que está em versão 7.72")
    print("   4. FECHE o cliente")
    print("   5. ABRA novamente")
    print("   6. Execute este script SEM logar")
    print("")
    print("===========================================")
    return
end

print("")
print("✅ Mapa carregado!")
print("")

-- Aguarda um pouco
local startTime2 = g_clock.millis()
while g_clock.millis() - startTime2 < 2000 do end

print("💾 Salvando minimap...")

-- Salva o minimap
local saveSuccess, saveError = pcall(function()
    g_minimap.saveOtmm('/minimap772.otmm')
end)

if not saveSuccess then
    print("❌ ERRO ao salvar: " .. tostring(saveError))
    return
end

print("")
print("✅✅✅ MINIMAP GERADO COM SUCESSO! ✅✅✅")
print("")
print("📍 Arquivo gerado em:")
print("   %APPDATA%\\otclient\\minimap772.otmm")
print("")
print("📋 PRÓXIMOS PASSOS:")
print("   1. Pressione Win+R")
print("   2. Digite: %APPDATA%\\otclient")
print("   3. Copie minimap772.otmm")
print("   4. Cole em otclient/data/minimap772.otmm")
print("   5. Cole também em otclient/minimap772.otmm")
print("===========================================")
