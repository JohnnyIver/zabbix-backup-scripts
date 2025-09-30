#!/bin/bash

# Define as cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

# Local do arquivo de log de status
LOG_STATUS="/var/log/backup_status.log"

# Verifica se o arquivo de log existe e tem conteúdo
if [ -s "$LOG_STATUS" ]; then
    # Pega a última linha do log
    LAST_STATUS=$(tail -n 1 "$LOG_STATUS")

    # Verifica se a última linha contém "SUCESSO"
    if echo "$LAST_STATUS" | grep -q "SUCESSO"; then
        STATUS_MSG="${GREEN}✅ SUCESSO${NC}"
    else
        STATUS_MSG="${RED}❌ FALHA${NC}"
    fi

    # Exibe o relatório formatado
    echo ""
    echo -e "--- Relatório do Último Backup ---"
    echo -e "Status: ${STATUS_MSG}"
    echo -e "Detalhes: ${LAST_STATUS}"
    echo ""
fi
