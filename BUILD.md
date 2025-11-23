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

### 2. Configurar variável de ambiente

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")
```

**Windows (CMD):**
```cmd
setx VCPKG_ROOT "C:\vcpkg"
```

**Linux/macOS:**
```bash
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.bashrc
source ~/.bashrc
```

**Importante:** Feche e reabra o terminal após configurar a variável.

---

## 📦 Instalação das Dependências

### Windows (x64-windows)

```powershell
cd C:\vcpkg
.\vcpkg install asio abseil cpp-httplib discord-rpc liblzma libogg libvorbis nlohmann-json openal-soft openssl parallel-hashmap physfs protobuf pugixml stduuid zlib luajit opengl glew angle --triplet x64-windows
```

### Windows (x64-windows-static) - Linking Estático

```powershell
.\vcpkg install asio abseil cpp-httplib discord-rpc liblzma libogg libvorbis nlohmann-json openal-soft openssl parallel-hashmap physfs protobuf pugixml stduuid zlib luajit opengl glew angle --triplet x64-windows-static
```

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

## ⚠️ Problemas Comuns

### Erro: "vcpkg_installed directory not found"

**Solução:**
1. Verifique se `VCPKG_ROOT` está configurado corretamente
2. Execute `vcpkg install` novamente para garantir que as dependências estão instaladas
3. Verifique se o triplet está correto (x64-windows, x64-linux, etc.)

### Erro: "CMAKE_TOOLCHAIN_FILE not found"

**Solução:**
1. Verifique se o vcpkg está instalado em `C:\vcpkg` (Windows) ou `~/vcpkg` (Linux)
2. Configure a variável `VCPKG_ROOT` corretamente
3. Use o caminho completo: `C:/vcpkg/scripts/buildsystems/vcpkg.cmake`

### Erro: "Package not found"

**Solução:**
1. Verifique se todas as dependências foram instaladas:
   ```powershell
   vcpkg list
   ```
2. Instale as dependências faltantes manualmente:
   ```powershell
   vcpkg install <nome-do-pacote> --triplet x64-windows
   ```

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

