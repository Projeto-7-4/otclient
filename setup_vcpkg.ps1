# Script PowerShell para configurar vcpkg no Windows
# Execute: .\setup_vcpkg.ps1

Write-Host "🔧 Configurando vcpkg para OTClient..." -ForegroundColor Cyan

# Verificar se vcpkg já está instalado
$vcpkgPath = "$env:VCPKG_ROOT"
if (-not $vcpkgPath) {
    $vcpkgPath = "C:\vcpkg"
    Write-Host "⚠️  VCPKG_ROOT não configurado. Usando padrão: $vcpkgPath" -ForegroundColor Yellow
}

# Verificar se vcpkg existe
if (-not (Test-Path $vcpkgPath)) {
    Write-Host "📦 Clonando vcpkg..." -ForegroundColor Yellow
    $parentDir = Split-Path $vcpkgPath
    Set-Location $parentDir
    git clone https://github.com/microsoft/vcpkg.git (Split-Path -Leaf $vcpkgPath)
}

Set-Location $vcpkgPath

# Bootstrap vcpkg
if (-not (Test-Path "vcpkg.exe")) {
    Write-Host "🔨 Executando bootstrap-vcpkg..." -ForegroundColor Yellow
    .\bootstrap-vcpkg.bat
}

# Integrar com Visual Studio
Write-Host "🔗 Integrando vcpkg com Visual Studio..." -ForegroundColor Yellow
.\vcpkg integrate install

# Configurar variável de ambiente
Write-Host "🌍 Configurando variável de ambiente VCPKG_ROOT..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", $vcpkgPath, "User")
$env:VCPKG_ROOT = $vcpkgPath

Write-Host "✅ vcpkg configurado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Instalando dependências do OTClient..." -ForegroundColor Cyan
Write-Host "   Isso pode levar 30-60 minutos na primeira vez..." -ForegroundColor Yellow

# Instalar dependências
.\vcpkg install `
    asio `
    abseil `
    cpp-httplib `
    discord-rpc `
    liblzma `
    libogg `
    libvorbis `
    nlohmann-json `
    openal-soft `
    openssl `
    parallel-hashmap `
    physfs `
    protobuf `
    pugixml `
    stduuid `
    zlib `
    luajit `
    opengl `
    glew `
    angle `
    --triplet x64-windows

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Todas as dependências foram instaladas com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Feche e reabra o terminal para carregar VCPKG_ROOT"
    Write-Host "   2. Execute: cmake --preset windows-default"
    Write-Host "   3. Execute: cmake --build --preset windows-release"
} else {
    Write-Host ""
    Write-Host "❌ Erro ao instalar dependências. Verifique os logs acima." -ForegroundColor Red
}

