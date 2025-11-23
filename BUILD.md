# 🔨 Guia de Compilação do OTClient

## 📋 Pré-requisitos

### Windows

1. **Visual Studio 2022** (Community Edition é grátis)
   - Baixe: https://visualstudio.microsoft.com/downloads/
   - Durante instalação, selecione:
     - ✅ **Desktop development with C++**
     - ✅ **C++ CMake tools for Windows**
     - ✅ **Windows SDK**

2. **Git for Windows**
   - Baixe: https://git-scm.com/download/win

3. **CMake** (geralmente incluído no Visual Studio)
   - Ou baixe separadamente: https://cmake.org/download/

### Linux

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git
```

### macOS

```bash
brew install cmake git
```

---

## 🔧 Instalação do vcpkg

### 1. Clonar e configurar vcpkg

**Windows:**
```powershell
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

**Linux/macOS:**
```bash
cd ~
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
./vcpkg integrate install
```

### 2. Configurar variável de ambiente VCPKG_ROOT

**⚠️ IMPORTANTE:** A variável deve ser `VCPKG_ROOT` (não `VcpkgRoot`).

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")
# Verificar
echo $env:VCPKG_ROOT
```

**Windows (CMD):**
```cmd
setx VCPKG_ROOT "C:\vcpkg"
REM Verificar (em novo terminal)
echo %VCPKG_ROOT%
```

**Linux/macOS:**
```bash
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.bashrc
# Ou para zsh:
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.zshrc
source ~/.bashrc  # ou source ~/.zshrc
# Verificar
echo $VCPKG_ROOT
```

**Importante:** 
- Feche e reabra o terminal após configurar a variável
- O CMake usa `VCPKG_ROOT` para encontrar o toolchain do vcpkg
- Sem essa variável, o CMake não conseguirá encontrar as dependências

---

## 📦 Instalação das Dependências

### Windows (x64-windows)

```powershell
cd C:\vcpkg
.\vcpkg install asio abseil cpp-httplib discord-rpc liblzma libogg libvorbis nlohmann-json openal-soft openssl parallel-hashmap physfs protobuf pugixml stduuid zlib luajit opengl glew angle --triplet x64-windows
```

### Windows (x64-windows-static) - Linking Estático

**⚠️ Recomendado para OpenGL no Windows:**

```powershell
.\vcpkg install asio abseil cpp-httplib discord-rpc liblzma libogg libvorbis nlohmann-json openal-soft openssl parallel-hashmap physfs protobuf pugixml stduuid zlib luajit opengl glew angle --triplet x64-windows-static
```

**Nota:** O triplet `x64-windows-static` é recomendado quando você precisa de linking estático, especialmente para OpenGL. Use `x64-windows` para linking dinâmico (mais comum).

### Linux

```bash
cd ~/vcpkg
./vcpkg install asio abseil cpp-httplib discord-rpc liblzma libogg libvorbis nlohmann-json openal-soft openssl parallel-hashmap physfs protobuf pugixml stduuid zlib luajit opengl glew --triplet x64-linux
```

**Nota:** A instalação pode levar 30-60 minutos na primeira vez.

---

## 🏗️ Compilação

### Opção 1: Usando CMake Presets (Recomendado)

**Windows:**
```powershell
cd C:\Users\%USERNAME%\Desktop\7.4\otclient
cmake --preset windows-default
cmake --build --preset windows-release
```

**Linux:**
```bash
cd ~/Desktop/7.4/otclient
cmake --preset linux-default
cmake --build --preset linux-release
```

### Opção 2: Usando Visual Studio (Windows)

1. Abra o **Visual Studio 2022**
2. Clique em **"Open a local folder"**
3. Selecione a pasta `otclient`
4. Aguarde o Visual Studio carregar o projeto CMake
5. No menu superior:
   - **Project** → **CMake Settings**
   - Verifique se `CMAKE_TOOLCHAIN_FILE` está configurado:
     - `C:/vcpkg/scripts/buildsystems/vcpkg.cmake`
6. **Build** → **Build All** (ou pressione `Ctrl+Shift+B`)

### Opção 3: Linha de Comando Manual

**Windows:**
```powershell
cd C:\Users\%USERNAME%\Desktop\7.4\otclient
mkdir build
cd build
cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release -j
```

**Linux:**
```bash
cd ~/Desktop/7.4/otclient
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release -j
```

---

## 📍 Localização do Executável

Após compilação bem-sucedida:

**Windows:**
```
build\Release\otclient.exe
```

**Linux:**
```
build\otclient
```

**macOS:**
```
build\otclient_mac
```

---

## 📂 Diretório vcpkg_installed

O diretório `vcpkg_installed` é criado **automaticamente** pelo vcpkg quando você instala as dependências. Ele contém:

- Bibliotecas compiladas
- Headers (arquivos de cabeçalho)
- Arquivos de configuração CMake
- Binários das dependências

### Localização

O diretório `vcpkg_installed` é criado dentro do diretório do vcpkg:

**Windows:**
```
C:\vcpkg\vcpkg_installed\
```

**Linux/macOS:**
```
~/vcpkg/vcpkg_installed/
```

### Estrutura

```
vcpkg_installed/
├── x64-windows/          # Para triplet x64-windows
│   ├── include/          # Headers
│   ├── lib/              # Bibliotecas
│   └── share/            # Arquivos CMake
├── x64-windows-static/   # Para triplet x64-windows-static
└── ...
```

### Verificar se está instalado

```powershell
# Windows
Test-Path "C:\vcpkg\vcpkg_installed\x64-windows"

# Linux/macOS
test -d "$HOME/vcpkg/vcpkg_installed/x64-linux" && echo "OK" || echo "Não encontrado"
```

---

## ⚠️ Problemas Comuns

### Erro: "vcpkg_installed directory not found"

**Causa:** As dependências não foram instaladas ainda.

**Solução:**
1. Verifique se `VCPKG_ROOT` está configurado corretamente:
   ```powershell
   # Windows
   echo $env:VCPKG_ROOT
   
   # Linux/macOS
   echo $VCPKG_ROOT
   ```

2. Instale as dependências:
   ```powershell
   # Windows
   cd $env:VCPKG_ROOT
   .\vcpkg install --triplet x64-windows
   
   # Linux
   cd $VCPKG_ROOT
   ./vcpkg install --triplet x64-linux
   ```

3. Verifique se o triplet está correto:
   - Windows: `x64-windows` ou `x64-windows-static`
   - Linux: `x64-linux`
   - macOS: `x64-osx` ou `arm64-osx`

4. O diretório `vcpkg_installed` será criado automaticamente após a primeira instalação bem-sucedida.

### Erro: "CMAKE_TOOLCHAIN_FILE not found"

**Solução:**
1. Verifique se o vcpkg está instalado em `C:\vcpkg` (Windows) ou `~/vcpkg` (Linux)
2. Configure a variável `VCPKG_ROOT` corretamente
3. Use o caminho completo: `C:/vcpkg/scripts/buildsystems/vcpkg.cmake`

### Erro: "Package not found"

**Solução:**
1. Verifique se todas as dependências foram instaladas:
   ```powershell
   # Windows
   cd $env:VCPKG_ROOT
   .\vcpkg list
   
   # Linux/macOS
   cd $VCPKG_ROOT
   ./vcpkg list
   ```

2. Verifique o triplet usado:
   ```powershell
   # Windows
   .\vcpkg list --triplet x64-windows
   
   # Se usar static
   .\vcpkg list --triplet x64-windows-static
   ```

3. Instale as dependências faltantes manualmente:
   ```powershell
   # Windows
   .\vcpkg install <nome-do-pacote> --triplet x64-windows
   
   # Ou para static
   .\vcpkg install <nome-do-pacote> --triplet x64-windows-static
   ```

### Erro: "VCPKG_ROOT not set"

**Solução:**
1. Configure a variável `VCPKG_ROOT` (veja seção "Configurar variável de ambiente")
2. Verifique se está configurada:
   ```powershell
   # Windows
   echo $env:VCPKG_ROOT
   
   # Linux/macOS
   echo $VCPKG_ROOT
   ```
3. Se não estiver configurada, configure novamente e **feche e reabra o terminal**

### Erro de compilação: "Cannot find OpenGL"

**Solução:**
- Windows: Use `x64-windows-static` ou instale `opengl` via vcpkg
- Linux: Instale `libgl1-mesa-dev`:
  ```bash
  sudo apt-get install libgl1-mesa-dev
  ```

---

## 📚 Dependências Instaladas

O `vcpkg.json` define as seguintes dependências:

- **asio** - Biblioteca de rede assíncrona
- **abseil** - Bibliotecas C++ do Google
- **cpp-httplib** - Cliente HTTP
- **discord-rpc** - Integração Discord
- **liblzma** - Compressão LZMA
- **libogg** - Áudio Ogg
- **libvorbis** - Áudio Vorbis
- **nlohmann-json** - Biblioteca JSON
- **openal-soft** - Áudio OpenAL
- **openssl** - SSL/TLS
- **parallel-hashmap** - Hash maps paralelos
- **physfs** - Sistema de arquivos físico
- **protobuf** - Serialização Protocol Buffers
- **pugixml** - Parser XML
- **stduuid** - UUID
- **zlib** - Compressão
- **luajit** - Interpretador Lua JIT
- **opengl** - OpenGL (Windows/Linux)
- **glew** - Extensões OpenGL
- **angle** - ANGLE (Windows)

---

## 🚀 Próximos Passos

Após compilar com sucesso:

1. Copie o executável para a pasta do OTClient
2. Execute e teste no servidor
3. Se encontrar problemas, verifique os logs em `otclientv8.log`

---

## 📞 Suporte

Para mais informações, consulte:
- [Documentação do vcpkg](https://vcpkg.io/)
- [Documentação do CMake](https://cmake.org/documentation/)
- [Repositório OTClient](https://github.com/edubart/otclient)

