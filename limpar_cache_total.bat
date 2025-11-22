@echo off
echo Limpando TODOS os caches do OTClient...
echo.

REM Fecha o cliente se estiver rodando
taskkill /F /IM otclient_dx.exe 2>nul
taskkill /F /IM otclient_gl.exe 2>nul

echo Aguardando 2 segundos...
timeout /t 2 /nobreak >nul

REM Limpa todo o AppData
echo Removendo cache do AppData...
rd /s /q "%APPDATA%\otclient" 2>nul

echo.
echo ✅ Cache limpo!
echo Agora abra o cliente novamente.
pause
