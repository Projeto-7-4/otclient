@echo off
chcp 65001 >nul
title 🗺️ Instalador de Minimap - Nostalrius 7.72

echo.
echo ════════════════════════════════════════════════════════
echo         🗺️  INSTALADOR DE MINIMAP COMPLETO
echo              Nostalrius 7.72 - Projeto 7.4
echo ════════════════════════════════════════════════════════
echo.

REM Verificar se minimap.otmm existe
if not exist "minimap.otmm" (
    echo ❌ ERRO: Arquivo minimap.otmm não encontrado!
    echo.
    echo 📥 Baixe o minimap.otmm do GitHub:
    echo    https://github.com/Projeto-7-4/otclient/tree/main/extras/minimap
    echo.
    pause
    exit /b 1
)

REM Criar pasta do OTClient se não existir
set "OTCLIENT_DIR=%appdata%\otclient"
if not exist "%OTCLIENT_DIR%" (
    echo 📁 Criando pasta do OTClient...
    mkdir "%OTCLIENT_DIR%"
)

echo 📂 Pasta do OTClient: %OTCLIENT_DIR%
echo.

REM Backup do minimap antigo se existir
if exist "%OTCLIENT_DIR%\minimap.otmm" (
    echo 💾 Fazendo backup do minimap antigo...
    move /Y "%OTCLIENT_DIR%\minimap.otmm" "%OTCLIENT_DIR%\minimap.otmm.backup" >nul
    echo    ✅ Backup salvo como: minimap.otmm.backup
    echo.
)

REM Copiar novo minimap
echo 📦 Instalando minimap completo...
copy /Y "minimap.otmm" "%OTCLIENT_DIR%\minimap.otmm" >nul

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════════════════════
    echo            ✅ MINIMAP INSTALADO COM SUCESSO!
    echo ════════════════════════════════════════════════════════
    echo.
    echo 🎮 Próximos passos:
    echo    1. Abra o OTClient
    echo    2. Conecte no servidor (192.168.0.36:7171)
    echo    3. Entre no jogo
    echo    4. Pressione Ctrl+M para abrir o minimap
    echo.
    echo 🗺️  Todo o mapa de Tibia 7.72 estará revelado!
    echo.
    echo ════════════════════════════════════════════════════════
) else (
    echo.
    echo ❌ ERRO: Falha ao copiar minimap!
    echo.
    echo 🔧 Possíveis soluções:
    echo    - Execute este script como Administrador
    echo    - Feche o OTClient se estiver aberto
    echo    - Verifique permissões da pasta %appdata%
    echo.
)

echo.
echo Pressione qualquer tecla para sair...
pause >nul

