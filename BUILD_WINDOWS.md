# Instruções de Build para Windows

## Pré-requisitos

1. **Visual Studio 2022** (Community Edition é grátis)
   - Instalar: "Desktop development with C++"
   - Inclui CMake e ferramentas necessárias

2. **vcpkg** (gerenciador de pacotes C++)
   ```powershell
   cd C:\
   git clone https://github.com/microsoft/vcpkg.git
   cd vcpkg
   .\bootstrap-vcpkg.bat
   .\vcpkg integrate install
   ```

3. **Git** (se ainda não tiver)

## Instalar Dependências

Execute no PowerShell (como Administrador):

```powershell
cd C:\vcpkg
.\vcpkg install libzip:x64-windows bzip2:x64-windows openal-soft:x64-windows zlib:x64-windows luajit:x64-windows physfs:x64-windows openssl:x64-windows glew:x64-windows
```

Isso pode demorar bastante (30-60 minutos na primeira vez).

## Corrigir Dependências

Se o CMake não encontrar as dependências, execute:

```powershell
cd <diretório-do-otclient>
.\fix_vcpkg_dependencies.ps1
```

Este script:
- Copia arquivos de `packages` para `installed`
- Cria `configure_cmake.ps1` com variáveis corretas

## Configurar CMake

Execute o script gerado:

```powershell
.\configure_cmake.ps1
```

Ou manualmente:

```powershell
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release
```

## Compilar

```powershell
cmake --build build --config Release
```

O executável estará em: `build\Release\otclient.exe`

## Problemas Comuns

### CMake não encontra dependências

1. Verifique se o vcpkg está instalado:
   ```powershell
   $env:VCPKG_ROOT
   ```

2. Execute o script de correção:
   ```powershell
   .\fix_vcpkg_dependencies.ps1
   ```

3. Reinstale as dependências:
   ```powershell
   cd C:\vcpkg
   .\vcpkg remove --triplet x64-windows libzip bzip2 openal-soft
   .\vcpkg install --triplet x64-windows libzip bzip2 openal-soft
   ```

### Erro "LIBZIP_LIBRARY not found"

O script `fix_vcpkg_dependencies.ps1` deve resolver isso automaticamente.
Se não resolver, defina manualmente:

```powershell
cmake .. -DLIBZIP_LIBRARY=C:\vcpkg\installed\x64-windows\lib\zip.lib
```

### Erro "BZIP2_LIBRARIES not found"

Defina manualmente:

```powershell
cmake .. -DBZIP2_LIBRARIES=C:\vcpkg\installed\x64-windows\lib\bz2.lib
```

## Efeito 173 (Critical Damage)

O código para renderizar o efeito 173 em 64x64 já está commitado:
- `src/client/thingtype.cpp` - Escala 2x para efeito 173
- `src/client/effect.cpp` - Simplificado

Após compilar, o executável terá o efeito funcionando em 64x64.
