# Script completo para corrigir dependências vcpkg e compilar OTClient
# Execute no PowerShell como Administrador

param(
    [string]$VCPKG_ROOT = "",
    [string]$TRIPLET = "x64-windows",
    [switch]$SkipDependencies = $false,
    [switch]$SkipConfigure = $false,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔧 Script de Build OTClient - Correção de Dependências" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Detectar VCPKG_ROOT
if (-not $VCPKG_ROOT) {
    $VCPKG_ROOT = $env:VCPKG_ROOT
    if (-not $VCPKG_ROOT) {
        $commonPaths = @(
            "C:\vcpkg",
            "C:\tools\vcpkg",
            "$env:USERPROFILE\vcpkg",
            "$env:USERPROFILE\Desktop\vcpkg"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $VCPKG_ROOT = $path
                break
            }
        }
        
        if (-not $VCPKG_ROOT) {
            Write-Host "❌ vcpkg não encontrado!" -ForegroundColor Red
            Write-Host "💡 Defina VCPKG_ROOT ou instale o vcpkg:" -ForegroundColor Yellow
            Write-Host "   git clone https://github.com/microsoft/vcpkg.git C:\vcpkg" -ForegroundColor Gray
            Write-Host "   cd C:\vcpkg" -ForegroundColor Gray
            Write-Host "   .\bootstrap-vcpkg.bat" -ForegroundColor Gray
            exit 1
        }
    }
}

$PACKAGES_DIR = "$VCPKG_ROOT\packages"
$INSTALLED_DIR = "$VCPKG_ROOT\installed\$TRIPLET"

Write-Host "✅ vcpkg encontrado: $VCPKG_ROOT" -ForegroundColor Green
Write-Host "📋 TRIPLET: $TRIPLET" -ForegroundColor Green
Write-Host ""

# Função para encontrar e copiar pacote
function Fix-VcpkgPackage {
    param(
        [string]$PackageName,
        [string[]]$LibPatterns = @(),
        [string[]]$IncludeDirs = @()
    )
    
    Write-Host "📦 Corrigindo $PackageName..." -ForegroundColor Yellow
    
    # Procurar em packages
    $packageDirs = Get-ChildItem "$PACKAGES_DIR" -Directory -Filter "${PackageName}_*" -ErrorAction SilentlyContinue
    
    if (-not $packageDirs) {
        Write-Host "  ⚠️  $PackageName não encontrado em packages" -ForegroundColor Yellow
        Write-Host "  💡 Execute: vcpkg install ${PackageName}:$TRIPLET" -ForegroundColor Cyan
        return $false
    }
    
    $packageDir = $packageDirs[0].FullName
    Write-Host "  📋 Pacote encontrado: $packageDir" -ForegroundColor Gray
    
    $copied = $false
    
    # Copiar libs
    if ($LibPatterns.Count -eq 0) {
        $LibPatterns = @("*.lib", "*.a")
    }
    
    $libSource = "$packageDir\lib"
    if (Test-Path $libSource) {
        $libTarget = "$INSTALLED_DIR\lib"
        if (-not (Test-Path $libTarget)) {
            New-Item -ItemType Directory -Path $libTarget -Force | Out-Null
        }
        
        foreach ($pattern in $LibPatterns) {
            $libs = Get-ChildItem $libSource -Filter $pattern -ErrorAction SilentlyContinue
            foreach ($lib in $libs) {
                $target = "$libTarget\$($lib.Name)"
                Copy-Item $lib.FullName -Destination $target -Force
                Write-Host "  ✅ Copiado: $($lib.Name)" -ForegroundColor Green
                $copied = $true
            }
        }
    }
    
    # Copiar includes
    if ($IncludeDirs.Count -eq 0) {
        $IncludeDirs = @("include")
    }
    
    foreach ($includeDir in $IncludeDirs) {
        $includeSource = "$packageDir\$includeDir"
        if (Test-Path $includeSource) {
            $includeTarget = "$INSTALLED_DIR\include"
            if (-not (Test-Path $includeTarget)) {
                New-Item -ItemType Directory -Path $includeTarget -Force | Out-Null
            }
            
            $packageIncludeName = Split-Path $includeSource -Leaf
            $targetInclude = "$includeTarget\$packageIncludeName"
            
            if (Test-Path $targetInclude) {
                Remove-Item $targetInclude -Recurse -Force
            }
            
            Copy-Item $includeSource -Destination $targetInclude -Recurse -Force
            Write-Host "  ✅ Headers copiados: $includeDir" -ForegroundColor Green
            $copied = $true
        }
    }
    
    # Copiar bin (se existir)
    $binSource = "$packageDir\bin"
    $binTarget = "$INSTALLED_DIR\bin"
    if (Test-Path $binSource) {
        if (-not (Test-Path $binTarget)) {
            New-Item -ItemType Directory -Path $binTarget -Force | Out-Null
        }
        Copy-Item "$binSource\*" -Destination $binTarget -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Binários copiados" -ForegroundColor Green
    }
    
    return $copied
}

# Corrigir dependências
if (-not $SkipDependencies) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📦 Corrigindo dependências..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    $dependencies = @(
        @{Name="libzip"; LibPatterns=@("zip.lib", "*zip*.lib")},
        @{Name="bzip2"; LibPatterns=@("bz2.lib", "*bz2*.lib")},
        @{Name="openal-soft"; LibPatterns=@("OpenAL32.lib", "*openal*.lib", "*al*.lib")}
    )
    
    $allFixed = $true
    foreach ($dep in $dependencies) {
        $fixed = Fix-VcpkgPackage -PackageName $dep.Name -LibPatterns $dep.LibPatterns
        if (-not $fixed) {
            $allFixed = $false
        }
        Write-Host ""
    }
    
    if (-not $allFixed) {
        Write-Host "⚠️  Algumas dependências não foram corrigidas" -ForegroundColor Yellow
        Write-Host "💡 Instale as dependências faltantes:" -ForegroundColor Cyan
        Write-Host "   vcpkg install libzip:$TRIPLET bzip2:$TRIPLET openal-soft:$TRIPLET" -ForegroundColor Gray
        Write-Host ""
    }
}

# Configurar CMake
if (-not $SkipConfigure) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔧 Configurando CMake..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    $BUILD_DIR = "build"
    
    if (-not (Test-Path $BUILD_DIR)) {
        New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
    }
    
    # Encontrar bibliotecas
    $cmakeArgs = @(
        "-B", $BUILD_DIR,
        "-S", ".",
        "-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake",
        "-DVCPKG_TARGET_TRIPLET=$TRIPLET",
        "-DCMAKE_BUILD_TYPE=Release"
    )
    
    # LIBZIP
    $libzipLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*zip*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($libzipLib) {
        $cmakeArgs += "-DLIBZIP_LIBRARY=$($libzipLib.FullName)"
        Write-Host "✅ LIBZIP_LIBRARY: $($libzipLib.Name)" -ForegroundColor Green
    }
    
    # BZIP2
    $bzip2Lib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*bz2*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bzip2Lib) {
        $cmakeArgs += "-DBZIP2_LIBRARIES=$($bzip2Lib.FullName)"
        Write-Host "✅ BZIP2_LIBRARIES: $($bzip2Lib.Name)" -ForegroundColor Green
    }
    
    # OPENAL
    $openalLib = Get-ChildItem "$INSTALLED_DIR\lib" -Filter "*openal*.lib","*al*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($openalLib) {
        $cmakeArgs += "-DOPENAL_LIBRARY=$($openalLib.FullName)"
        Write-Host "✅ OPENAL_LIBRARY: $($openalLib.Name)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📋 Executando CMake..." -ForegroundColor Yellow
    Write-Host "   cmake $($cmakeArgs -join ' ')" -ForegroundColor Gray
    Write-Host ""
    
    & cmake $cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Erro ao configurar CMake" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✅ CMake configurado com sucesso!" -ForegroundColor Green
    Write-Host ""
}

# Compilar
if (-not $SkipBuild) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔨 Compilando..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "📋 Executando build..." -ForegroundColor Yellow
    Write-Host "   cmake --build build --config Release" -ForegroundColor Gray
    Write-Host ""
    
    & cmake --build build --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Erro ao compilar" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✅ Compilação concluída!" -ForegroundColor Green
    
    $exePath = "build\Release\otclient.exe"
    if (Test-Path $exePath) {
        Write-Host ""
        Write-Host "🎉 Executável criado: $exePath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Processo concluído!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
