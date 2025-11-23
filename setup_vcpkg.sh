#!/bin/bash
# Script para configurar vcpkg no Linux/macOS
# Execute: chmod +x setup_vcpkg.sh && ./setup_vcpkg.sh

echo "🔧 Configurando vcpkg para OTClient..."

# Verificar se vcpkg já está instalado
VCPKG_ROOT="${VCPKG_ROOT:-$HOME/vcpkg}"

# Verificar se vcpkg existe
if [ ! -d "$VCPKG_ROOT" ]; then
    echo "📦 Clonando vcpkg..."
    cd "$HOME"
    git clone https://github.com/microsoft/vcpkg.git
fi

cd "$VCPKG_ROOT"

# Bootstrap vcpkg
if [ ! -f "./vcpkg" ]; then
    echo "🔨 Executando bootstrap-vcpkg..."
    ./bootstrap-vcpkg.sh
fi

# Integrar com sistema
echo "🔗 Integrando vcpkg..."
./vcpkg integrate install

# Configurar variável de ambiente
echo "🌍 Configurando variável de ambiente VCPKG_ROOT..."
if ! grep -q "VCPKG_ROOT" ~/.bashrc 2>/dev/null; then
    echo "export VCPKG_ROOT=\"$VCPKG_ROOT\"" >> ~/.bashrc
fi
if ! grep -q "VCPKG_ROOT" ~/.zshrc 2>/dev/null; then
    echo "export VCPKG_ROOT=\"$VCPKG_ROOT\"" >> ~/.zshrc
fi

export VCPKG_ROOT="$VCPKG_ROOT"

echo "✅ vcpkg configurado com sucesso!"
echo ""
echo "📦 Instalando dependências do OTClient..."
echo "   Isso pode levar 30-60 minutos na primeira vez..."

# Instalar dependências
./vcpkg install \
    asio \
    abseil \
    cpp-httplib \
    discord-rpc \
    liblzma \
    libogg \
    libvorbis \
    nlohmann-json \
    openal-soft \
    openssl \
    parallel-hashmap \
    physfs \
    protobuf \
    pugixml \
    stduuid \
    zlib \
    luajit \
    opengl \
    glew \
    --triplet x64-linux

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Todas as dependências foram instaladas com sucesso!"
    echo ""
    echo "💡 Próximos passos:"
    echo "   1. Execute: source ~/.bashrc (ou source ~/.zshrc)"
    echo "   2. Execute: cmake --preset linux-default"
    echo "   3. Execute: cmake --build --preset linux-release"
else
    echo ""
    echo "❌ Erro ao instalar dependências. Verifique os logs acima."
fi

