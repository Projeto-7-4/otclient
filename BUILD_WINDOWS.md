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

## Solução Rápida (Recomendado)

Execute o script completo que faz tudo automaticamente:

```powershell
.\fix_and_build.ps1
```

Este script:
1. ✅ Detecta automaticamente o vcpkg
2. ✅ Corrige dependências (copia de packages para installed)
3. ✅ Configura CMake com variáveis corretas
4. ✅ Compila o projeto

### Opções do Script

```powershell
# Apenas corrigir dependências (sem configurar/build)
.\fix_and_build.ps1 -SkipConfigure -SkipBuild

# Apenas configurar CMake (sem corrigir/build)
.\fix_and_build.ps1 -SkipDependencies -SkipBuild

# Apenas compilar (já configurado)
.\fix_and_build.ps1 -SkipDependencies -SkipConfigure

# Especificar caminho do vcpkg
.\fix_and_build.ps1 -VCPKG_ROOT "C:\meu\caminho\vcpkg"
```

### Se o Script Falhar

1. Verifique se o vcpkg está instalado:
   ```powershell
   $env:VCPKG_ROOT
   ```

2. Instale as dependências manualmente:
   ```powershell
   cd C:\vcpkg
   .\vcpkg install libzip:x64-windows bzip2:x64-windows openal-soft:x64-windows
   ```

3. Execute o script novamente:
   ```powershell
   .\fix_and_build.ps1
   ```
