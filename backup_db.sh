#!/bin/bash

# --- CONFIGURAÇÕES ---
DB_USER="zabbix"
DB_PASS="admin" 
DB_NAME="zabbix"
BACKUP_DIR="/var/backups/sql"
DATE=$(date +%F) # Formato AAAA-MM-DD
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
LOG_STATUS="/var/log/backup_status.log"

# ===== LINHA MODIFICADA AQUI =====
# O nome do arquivo agora segue o formato [nome do banco]-[data]~.sql.gz
FILENAME="${DB_NAME}-${DATE}~.sql.gz" 
# ===============================

# --- FIM DAS CONFIGURAÇÕES ---

# --- EXECUÇÃO E VERIFICAÇÃO ---
echo "Iniciando backup do banco de dados: ${DB_NAME}"

set -o pipefail
mariadb-dump --user=${DB_USER} --password=${DB_PASS} --host=localhost --single-transaction --routines --events ${DB_NAME} | gzip > "${BACKUP_DIR}/${FILENAME}"

if [ $? -eq 0 ]; then
  echo "[$DATETIME] - SUCESSO - Arquivo: ${BACKUP_DIR}/${FILENAME}" >> ${LOG_STATUS}
else
  echo "[$DATETIME] - FALHA - Ocorreu um erro ao gerar o backup do banco de dados ${DB_NAME}." >> ${LOG_STATUS}
  exit 1
fi

# --- ROTAÇÃO DE BACKUPS ---
# Apaga backups com mais de 2 dias para manter a retenção de 3 dias.
# O find agora procura por arquivos que terminem com '~.sql.gz'
echo "Removendo backups com mais de 3 dias..."
find ${BACKUP_DIR} -type f -name "*~.sql.gz" -mtime +2 -delete

echo "Processo de backup finalizado com sucesso."
