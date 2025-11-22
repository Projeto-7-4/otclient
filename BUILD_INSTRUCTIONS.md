# Instruções de Build

## ⚠️ Importante

Este repositório contém apenas os arquivos de runtime do OTClient.
**NÃO contém os arquivos de build** (CMakeLists.txt, etc).

## Como Compilar

### Opção 1: Compilar Manualmente no Windows

1. Faça pull deste repositório:
   ```bash
   git pull origin develop
   ```

2. Os arquivos fonte modificados já estão aqui:
   - `src/client/thingtype.cpp` (com suporte para efeito 173 em 64x64)
   - `src/client/effect.cpp` (simplificado)

3. Compile usando seu método usual no Windows

4. O executável compilado terá as correções do efeito 173

### Opção 2: Usar repositório com código completo

Use o repositório `otclient-build` que contém o código fonte completo.

## Arquivos Modificados

- ✅ `src/client/thingtype.cpp` - Escala 2x para efeito 173
- ✅ `src/client/effect.cpp` - Simplificado

## Efeito 173 (Critical Damage)

O efeito 173 agora renderiza em **64x64 pixels** em vez de 32x32.
