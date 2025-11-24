# 🔧 Troubleshooting - Build do OTClient

## Problemas Comuns e Soluções

### 1. ❌ Erro: "Cannot open include file: 'parallel_hashmap/btree.h'"

**Causa:** vcpkg não instalou ou não encontrou o `parallel-hashmap`

**Solução:**
- O workflow `build-windows-fixed.yml` verifica se os headers foram instalados
- Se ainda falhar, execute manualmente:
  ```powershell
  vcpkg install parallel-hashmap --triplet x64-windows-static
  ```

### 2. ❌ Erro: "VCPKG_ROOT not found"

**Causa:** Variável de ambiente não configurada

**Solução:**
- No GitHub Actions, o `setup-vcpkg@v1` configura automaticamente
- Localmente, configure:
  ```powershell
  [System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")
  ```

### 3. ❌ Erro: "MSBuild not found"

**Causa:** Visual Studio não instalado ou MSBuild não no PATH

**Solução:**
- O workflow usa `setup-msbuild@v1` automaticamente
- Localmente, instale Visual Studio Build Tools

### 4. ❌ Erro: "vcpkg install failed"

**Causa:** Problemas de rede, memória ou dependências

**Solução:**
- Verifique conexão de internet
- Aumente timeout (já configurado para 120 minutos)
- Execute com mais verbosidade para debug

### 5. ❌ Build completa mas executável não encontrado

**Causa:** Executável em local diferente do esperado

**Solução:**
- O workflow busca em múltiplos locais
- Verifica:
  - `otclient_gl_x64.exe` (raiz)
  - `vc17\otclient_gl_x64.exe`
  - `vc17\x64\OpenGL\otclient_gl_x64.exe`
  - Busca recursiva em todos os diretórios

## Workflows Disponíveis

### ✅ Recomendado: `build-windows-fixed.yml`
- **Nome:** "Build OTClient Windows (Fixed - No More Breaks)"
- **Por que usar:** Mais robusto, com verificações e logs detalhados
- **Características:**
  - Verifica instalação do vcpkg
  - Verifica headers críticos após instalação
  - Logs detalhados para debug
  - Upload do build.log se falhar

### `build-windows-direct.yml`
- Usa MSBuild diretamente
- Mais simples, menos verificações

### `build-windows-final.yml`
- Versão anterior com busca automática de MSBuild

## Como Executar Manualmente

### 1. Instalar Dependências
```powershell
vcpkg install --triplet x64-windows-static --x-manifest-root=. --x-install-root=./vcpkg_installed
```

### 2. Compilar
```powershell
msbuild vc17\otclient.sln `
  /t:Build `
  /p:Configuration=OpenGL `
  /p:Platform=x64 `
  /p:VcpkgTriplet=x64-windows-static `
  /p:VcpkgRoot="$env:VCPKG_ROOT" `
  /p:VcpkgInstalledDir="./vcpkg_installed"
```

## Verificações Antes de Fazer Push

1. ✅ `vcpkg.json` está atualizado?
2. ✅ `.vcxproj` usa `$(VcpkgRoot)\installed` (não caminho hardcoded)?
3. ✅ Todos os arquivos fonte estão commitados?
4. ✅ Workflow configurado corretamente?

## Se o Build Ainda Quebrar

1. **Verifique os logs:**
   - GitHub Actions: Abra a run e veja os logs de cada step
   - O workflow `build-windows-fixed.yml` salva o `build.log` como artefato

2. **Verifique dependências:**
   - Execute `vcpkg list` para ver o que está instalado
   - Compare com o `vcpkg.json`

3. **Teste localmente:**
   - Se funciona localmente mas não no CI, pode ser diferença de ambiente
   - Verifique versões do Visual Studio, Windows SDK, etc.

## Logs e Debug

O workflow `build-windows-fixed.yml` inclui:
- ✅ Verificação de instalação do vcpkg
- ✅ Verificação de headers críticos
- ✅ Logs detalhados em cada etapa
- ✅ Upload automático do build.log se falhar

