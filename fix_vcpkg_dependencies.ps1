# Script para corrigir dependências do vcpkg e configurar CMake
# Execute este script no PowerShell como Administrador

Write-Host "🔧 Corrigindo dependências do vcpkg para OTClient..." -ForegroundColor Cyan
Write-Host ""

# Configurações
$VCPKG_ROOT = $env:VCPKG_ROOT
if (-not $VCPKG_ROOT) {
    $VCPKG_ROOT = "C:\vcpkg"
    Write-Host "⚠️  VCPKG_ROOT não definido, usando: $VCPKG_ROOT" -ForegroundColor Yellow
}

$TRIPLET = "x64-windows"
$PACKAGES_DIR = "$VCPKG_ROOT\installed\$TRIPLET"
$INSTALLED_DIR = "$VCPKG_ROOT\installed\$TRIPLET"

Write-Host "📋 VCPKG_ROOT: $VCPKG_ROOT" -ForegroundColor Green
Write-Host "📋 TRIPLET: $TRIPLET" -ForegroundColor Green
Write-Host ""

# Função para copiar arquivos de packages para installed
function Copy-VcpkgPackage {
    param(
        [string]$PackageName,
        [string]$SourceSubDir = ""
    )
    
    $sourceDir = "$VCPKG_ROOT\packages\${PackageName}_$TRIPLET"
    $targetDir = "$INSTALLED_DIR"
    
    if (-not (Test-Path $sourceDir)) {
        Write-Host "❌ $PackageName não encontrado em packages" -ForegroundColor Red
        return $false
    }
    
    Write-Host "📋 Copiando $PackageName..." -ForegroundColor Yellow
    
    # Copiar libs
    $libSource = "$sourceDir\lib"
    $libTarget = "$targetDir\lib"
    if (Test-Path $libSource) {
        if (-not (Test-Path $libTarget)) {
            New-Item -ItemType Directory -Path $libTarget -Force | Out-Null
        }
        Copy-Item "$libSource\*" -Destination $libTarget -Recurse -Force
        Write-Host "  ✅ Libs copiadas" -ForegroundColor Green
    }
    
    # Copiar includes
    $includeSource = "$sourceDir\include"
    $includeTarget = "$targetDir\include"
    if (Test-Path $includeSource) {
        if (-not (Test-Path $includeTarget)) {
            New-Item -ItemType Directory -Path $includeTarget -Force | Out-Null
        }
        Copy-Item "$includeSource\*" -Destination $includeTarget -Recurse -Force
        Write-Host "  ✅ Headers copiados" -ForegroundColor Green
    }
    
    # Copiar bin (se existir)
    $binSource = "$sourceDir\bin"
    $binTarget = "$targetDir\bin"
    if (Test-Path $binSource) {
        if (-not (Test-Path $binTarget)) {
            New-Item -ItemType Directory -Path $binTarget -Force | Out-Null
        }
        Copy-Item "$binSource\*" -Destination $binTarget -Recurse -Force
        Write-Host "  ✅ Binários copiados" -ForegroundColor Green
    }
    
    return $true
}

# Verificar se vcpkg existe
if (-not (Test-Path $VCPKG_ROOT)) {
    Write-Host "❌ vcpkg não encontrado em: $VCPKG_ROOT" -ForegroundColor Red
    Write-Host "💡 Instale o vcpkg ou defina VCPKG_ROOT" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ vcpkg encontrado" -ForegroundColor Green
Write-Host ""

# Copiar dependências faltantes
Write-Host "📦 Copiando dependências de packages para installed..." -ForegroundColor Cyan
Write-Host ""

$dependencies = @("libzip", "bzip2", "openal-soft")
$allCopied = $true

foreach ($dep in $dependencies) {
    $copied = Copy-VcpkgPackage -PackageName $dep
    if (-not $copied) {
        Write-Host "⚠️  $dep não foi copiado (pode não estar instalado)" -ForegroundColor Yellow
        Write-Host "💡 Execute: vcpkg install $dep`:$TRIPLET" -ForegroundColor Yellow
        $allCopied = $false
    }
}

Write-Host ""

# Verificar arquivos copiados
Write-Host "🔍 Verificando arquivos copiados..." -ForegroundColor Cyan
Write-Host ""

# Verificar libzip
$libzipLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*zip*.lib" -ErrorAction SilentlyContinue
if ($libzipLib) {
    Write-Host "✅ libzip.lib encontrado: $($libzipLib.Name)" -ForegroundColor Green
} else {
    Write-Host "❌ libzip.lib não encontrado" -ForegroundColor Red
}

# Verificar bzip2
$bzip2Lib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*bz2*.lib" -ErrorAction SilentlyContinue
if ($bzip2Lib) {
    Write-Host "✅ bzip2.lib encontrado: $($bzip2Lib.Name)" -ForegroundColor Green
} else {
    Write-Host "❌ bzip2.lib não encontrado" -ForegroundColor Red
}

# Verificar openal-soft
$openalLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*openal*.lib" -ErrorAction SilentlyContinue
if ($openalLib) {
    Write-Host "✅ openal-soft.lib encontrado: $($openalLib.Name)" -ForegroundColor Green
} else {
    Write-Host "❌ openal-soft.lib não encontrado" -ForegroundColor Red
}

Write-Host ""

# Criar script de configuração CMake
Write-Host "📝 Criando script de configuração CMake..." -ForegroundColor Cyan
Write-Host ""

$cmakeConfigScript = @"
# Configuração CMake para OTClient com variáveis de dependências

`$VCPKG_ROOT = "$VCPKG_ROOT"
`$TRIPLET = "$TRIPLET"
`$BUILD_DIR = "build"

# Criar diretório de build
if (-not (Test-Path `$BUILD_DIR)) {
    New-Item -ItemType Directory -Path `$BUILD_DIR | Out-Null
}

Write-Host "🔧 Configurando CMake..." -ForegroundColor Cyan

# Definir variáveis de dependências
`$cmakeArgs = @(
    "-B", `$BUILD_DIR,
    "-S", ".",
    "-DCMAKE_TOOLCHAIN_FILE=`$VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake",
    "-DVCPKG_TARGET_TRIPLET=`$TRIPLET",
    "-DCMAKE_BUILD_TYPE=Release"
)

# Adicionar variáveis específicas se os arquivos existirem
`$libzipLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*zip*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
if (`$libzipLib) {
    `$cmakeArgs += "-DLIBZIP_LIBRARY=`$(`$libzipLib.FullName)"
    Write-Host "✅ LIBZIP_LIBRARY definido: `$(`$libzipLib.Name)" -ForegroundColor Green
}

`$bzip2Lib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*bz2*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
if (`$bzip2Lib) {
    `$cmakeArgs += "-DBZIP2_LIBRARIES=`$(`$bzip2Lib.FullName)"
    Write-Host "✅ BZIP2_LIBRARIES definido: `$(`$bzip2Lib.Name)" -ForegroundColor Green
}

`$openalLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*openal*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
if (`$openalLib) {
    `$cmakeArgs += "-DOPENAL_LIBRARY=`$(`$openalLib.FullName)"
    Write-Host "✅ OPENAL_LIBRARY definido: `$(`$openalLib.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Executando CMake..." -ForegroundColor Cyan
Write-Host "cmake `$cmakeArgs" -ForegroundColor Gray

& cmake `$cmakeArgs

if (`$LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ CMake configurado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Agora você pode compilar:" -ForegroundColor Cyan
    Write-Host "   cmake --build build --config Release" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Erro ao configurar CMake" -ForegroundColor Red
    exit 1
}
"@

$cmakeConfigScript | Out-File -FilePath "configure_cmake.ps1" -Encoding UTF8

Write-Host "✅ Script configure_cmake.ps1 criado" -ForegroundColor Green
Write-Host ""

# Resumo
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Script concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Execute: .\configure_cmake.ps1" -ForegroundColor Yellow
Write-Host "   2. Se der certo: cmake --build build --config Release" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Se ainda faltar dependências:" -ForegroundColor Cyan
Write-Host "   vcpkg install libzip:$TRIPLET bzip2:$TRIPLET openal-soft:$TRIPLET" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
