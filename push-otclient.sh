#!/bin/bash

# Script para facilitar push do OTClient para GitHub
# Uso: ./push-otclient.sh "mensagem do commit"

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎮 OTClient - Push para GitHub${NC}"
echo ""

# Verificar se está no diretório correto
if [ ! -f "init.lua" ]; then
    echo "❌ Erro: Execute este script no diretório do OTClient!"
    exit 1
fi

# Verificar se há mensagem de commit
if [ -z "$1" ]; then
    echo "❌ Erro: Forneça uma mensagem de commit!"
    echo "Uso: ./push-otclient.sh \"sua mensagem aqui\""
    exit 1
fi

COMMIT_MSG="$1"

echo -e "${YELLOW}📝 Status atual:${NC}"
git status --short
echo ""

# Adicionar todos os arquivos
echo -e "${BLUE}➕ Adicionando arquivos...${NC}"
git add .

# Commitar
echo -e "${BLUE}💾 Commitando: $COMMIT_MSG${NC}"
git commit -m "$COMMIT_MSG"

# Push
echo -e "${BLUE}🚀 Fazendo push para GitHub...${NC}"
git push origin main

echo ""
echo -e "${GREEN}✅ Push realizado com sucesso!${NC}"
echo -e "${GREEN}🔗 https://github.com/Projeto-7-4/otclient${NC}"
echo ""
echo -e "${YELLOW}📱 No Windows, execute:${NC}"
echo -e "   ${BLUE}cd otclient-projeto74${NC}"
echo -e "   ${BLUE}git pull origin main${NC}"

