# 🎮 OTClient - Projeto 7.4

Fork customizado do [mehah/otclient](https://github.com/mehah/otclient) para o servidor Nostalrius 7.72.

---

## 🔗 Repositório

**GitHub:** https://github.com/Projeto-7-4/otclient

---

## 🚀 Workflow de Desenvolvimento

### No Mac (Desenvolvimento):

```bash
# 1. Fazer modificações no código
cd /Users/brunovavretchek/Desktop/7.4/otclient-mehah

# 2. Testar/Compilar (se necessário)
# [comandos de compilação aqui]

# 3. Commitar mudanças
git add .
git commit -m "Descrição das mudanças"

# 4. Push para GitHub
git push origin main
```

### No Windows (Uso):

```bash
# 1. Clonar pela primeira vez (só fazer UMA VEZ)
cd C:\Users\SeuUsuario\Desktop
git clone https://github.com/Projeto-7-4/otclient.git otclient-projeto74

# 2. Para atualizar (sempre que houver mudanças)
cd otclient-projeto74
git pull origin main

# 3. Compilar no Windows (se necessário)
# [comandos de compilação Windows aqui]
```

---

## 📁 Estrutura Importante

```
otclient/
├── data/
│   ├── things/
│   │   └── 772/          ← Assets do Tibia 7.72
│   │       ├── Tibia.dat
│   │       ├── Tibia.spr
│   │       └── Tibia.pic
│   └── ...
├── init.lua              ← Configuração principal
├── modules/
│   └── game_*/           ← Módulos do jogo
└── src/                  ← Código fonte C++
```

---

## ⚙️ Configuração para Nostalrius

### init.lua

```lua
-- Servidor
Servers = {
    ["Nostalrius 7.72"] = "192.168.0.36:7171:772"
}

-- Permitir servidores customizados
ALLOW_CUSTOM_SERVERS = true

-- Nome do cliente
g_app.setName("OTClient - Nostalrius 7.72")
```

---

## 🔧 Compilação

### Mac (M1/M2):

```bash
mkdir build && cd build
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 ..
make -j$(sysctl -n hw.ncpu)
```

### Windows:

```bash
# Usando Visual Studio
mkdir build && cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
cmake --build . --config Release
```

### Linux:

```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

---

## 🐛 Fixes Aplicados

### 1. Compatibilidade com Protocolo 772
- Configurado para protocolo 7.72
- Assets corretos (Tibia.dat ~550 KB)
- Suporte a IDs até 8000

### 2. Configuração de Servidor
- IP: 192.168.0.36
- Porta: 7171
- Protocolo: 772

---

## 📚 Documentação Original

- [mehah/otclient](https://github.com/mehah/otclient)
- [OTClient Wiki](https://github.com/edubart/otclient/wiki)

---

## 🔄 Sincronizar com Upstream (mehah)

Para pegar atualizações do repositório original:

```bash
# Adicionar upstream (se ainda não tiver)
git remote add upstream git@github.com:mehah/otclient.git

# Pegar mudanças
git fetch upstream
git merge upstream/main

# Resolver conflitos (se houver)
# ...

# Push para nosso repositório
git push origin main
```

---

## 📝 Convenções de Commit

```
🎨 Style: Mudanças de formatação/estilo
🐛 Fix: Correção de bugs
✨ Feature: Nova funcionalidade
📚 Docs: Documentação
🔧 Config: Configurações
🚀 Performance: Melhorias de performance
♻️ Refactor: Refatoração de código
```

---

## 🆘 Troubleshooting

### Problema: Assets não carregam
```bash
# Verificar se os arquivos estão corretos
ls -lh data/things/772/
# Tibia.dat deve ter ~550 KB
# Tibia.spr deve ter ~8-10 MB
```

### Problema: "Protocol 772 not supported"
```lua
-- Verificar init.lua
Servers = {
    ["Seu Servidor"] = "IP:PORT:772"  ← 772 aqui!
}
```

### Problema: Cache corrompido
```bash
# Mac
rm -rf ~/Library/Application\ Support/otclient/

# Windows
# Win + R → %appdata%\otclient → Delete tudo
```

---

## 🌐 Links Úteis

- **Servidor:** https://github.com/Projeto-7-4/nostalrius-server
- **Website:** https://github.com/Projeto-7-4/nostalrius-website
- **OTClient:** https://github.com/Projeto-7-4/otclient

---

**Última atualização:** 19/11/2025  
**Versão:** mehah/otclient fork  
**Protocolo:** 7.72

