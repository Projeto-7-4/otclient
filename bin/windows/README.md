# 🎮 OTClient - Executável Windows

## 📦 Conteúdo desta pasta

Esta pasta contém o **executável compilado automaticamente** pelo GitHub Actions.

- **`otclient.zip`** - Executável comprimido (atualizado a cada commit)
- **`BUILD_INFO.txt`** - Informações da compilação

## 📥 Como usar

1. Baixe `otclient.zip`
2. Extraia o arquivo ZIP
3. Copie `otclient.exe` para sua pasta do OTClient
4. Execute e jogue!

## 🔄 Atualização automática

Este executável é atualizado automaticamente sempre que há um commit na branch `main`.

**🤖 Última compilação:** Veja `BUILD_INFO.txt`

## 🌐 Configuração do servidor

Configure seu `init.lua`:

```lua
Servers = {
    ["Nostalrius 7.72"] = "192.168.0.36:7171:772"
}
ALLOW_CUSTOM_SERVERS = true
```

## 📚 Outras formas de download

### 1. GitHub Releases (recomendado)
- Acesse: https://github.com/Projeto-7-4/otclient/releases
- Cada build gera uma release automática
- Download direto do `.exe` (sem descompactar)

### 2. GitHub Actions Artifacts
- Acesse: https://github.com/Projeto-7-4/otclient/actions
- Clique na execução mais recente
- Baixe o artifact "otclient-windows-x64"
- Disponível por 90 dias

### 3. Este diretório (branch main)
- Clone o repositório
- Navegue até `bin/windows/`
- Extraia `otclient.zip`

## ✨ Otimizações incluídas

- ✅ **FPS padrão: 60** (reduz flicker visual)
- ✅ **Protocolo 772** estável
- ✅ **Build Release** otimizado para performance
- ✅ **Compilado para Windows x64**

## 🐛 Problemas?

Se o executável não funcionar:

1. Certifique-se que você tem **Windows 7 ou superior**
2. Instale **Visual C++ Redistributable 2015-2022**:
   - https://aka.ms/vs/17/release/vc_redist.x64.exe
3. Verifique se os assets (`.dat`, `.spr`) estão corretos na pasta `data/things/772/`

## 📝 Build Info

Veja `BUILD_INFO.txt` para informações detalhadas sobre:
- Data da compilação
- Commit que gerou o build
- Número do build

---

**🤖 Esta pasta é atualizada automaticamente pelo GitHub Actions**

