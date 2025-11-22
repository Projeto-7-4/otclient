-- Script para gerar minimap completo a partir do map.otbm
-- Execute no OTClient com: Ctrl+T e cole este script

print("===========================================")
print("🗺️  GERADOR DE MINIMAP COMPLETO")
print("===========================================")

-- Verifica se o arquivo existe
if not g_resources.fileExists('/data/map.otbm') then
    print("❌ ERROR: Arquivo map.otbm não encontrado em /data/")
    print("   Copie o arquivo map.otbm do servidor para otclient/data/")
    return
end

print("📂 Carregando map.otbm...")
print("⏳ Isso pode demorar alguns minutos...")

-- Carrega o mapa
local success = pcall(function()
    g_map.loadOtbm('/data/map.otbm')
end)

if not success then
    print("❌ ERRO ao carregar o mapa!")
    return
end

print("✅ Mapa carregado com sucesso!")
print("💾 Salvando minimap...")

-- Salva o minimap
g_minimap.saveOtmm('/minimap772.otmm')

print("✅ Minimap gerado: /minimap772.otmm")
print("📍 Local do arquivo:")
if g_platform.getPlatformName() == "windows" then
    print("   %APPDATA%\\otclient\\minimap772.otmm")
else
    print("   ~/.otclient/minimap772.otmm")
end
print("===========================================")
print("✅ CONCLUÍDO!")
print("   Copie o arquivo minimap772.otmm para:")
print("   otclient/data/minimap772.otmm")
print("===========================================")

