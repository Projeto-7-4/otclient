# GitHub Actions Workflows

Este diretório contém workflows do GitHub Actions para compilar o OTClient automaticamente.

## Workflows Disponíveis

### 1. `build-windows.yml` (Recomendado)
**Usa CMake** - Método padrão e recomendado pelo projeto.

- ✅ Mais rápido
- ✅ Mais confiável
- ✅ Usa os presets do CMake
- ✅ Melhor integração com vcpkg

**Triggers:**
- Push para branches `main` ou `master`
- Pull requests
- Execução manual (`workflow_dispatch`)

**Como usar:**
1. Faça push do código para o repositório
2. O workflow será executado automaticamente
3. Baixe o executável na aba "Actions" > "Artifacts"

### 2. `build-windows-vs.yml`
**Usa Visual Studio Solution** - Compila usando o arquivo `.sln`

- ✅ Compila exatamente como no Visual Studio
- ✅ Usa as mesmas configurações do `vc17/otclient.vcxproj`
- ⚠️ Executa apenas quando arquivos em `vc17/` ou `src/` mudarem

**Como usar:**
1. Vá para a aba "Actions" no GitHub
2. Selecione "Build OTClient Windows (Visual Studio Solution)"
3. Clique em "Run workflow"
4. Baixe o executável em "Artifacts"

## Download do Executável

Após a compilação:

1. Vá para a aba **Actions** no GitHub
2. Clique na execução do workflow (verde = sucesso)
3. Role até o final da página
4. Em **Artifacts**, clique para baixar:
   - `otclient-windows-x64` (CMake)
   - `otclient-windows-x64-vs` (Visual Studio)

## Vantagens do CI/CD

✅ **Não precisa instalar nada localmente**
✅ **Compilação consistente e reproduzível**
✅ **Automaticamente atualizado com cada push**
✅ **Executáveis prontos para download**
✅ **Sem problemas de espaço em disco**
✅ **Sem problemas de configuração do ambiente**

## Notas

- A primeira execução pode demorar mais (instalação de dependências)
- As dependências são cacheadas pelo GitHub Actions
- O executável é mantido por 30 dias

