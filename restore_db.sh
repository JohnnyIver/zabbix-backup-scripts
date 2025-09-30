#!/bin/bash

# ####################################################################
# ## ATENÇÃO! ESTE SCRIPT É DESTRUTIVO!                             ##
# ## ELE IRÁ SOBRESCREVER O BANCO DE DADOS ATUAL COM DADOS DE UM    ##
# ## ARQUIVO DE BACKUP. USE COM EXTREMO CUIDADO.                    ##
# ####################################################################

# --- CONFIGURAÇÃO DO DIRETÓRIO DE BACKUP ---
BACKUP_DIR="/var/backups/sql"
# --- FIM DA CONFIGURAÇÃO ---


# --- LÓGICA DO SCRIPT ---

# 1. SOLICITAÇÃO INTERATIVA DAS CREDENCIAIS
echo "--- Credenciais do Banco de Dados de Destino ---"
read -p "Digite o nome do Banco de Dados a ser restaurado: " DB_NAME
read -p "Digite o nome do Usuário do banco de dados: " DB_USER
read -sp "Digite a Senha do usuário ${DB_USER}: " DB_PASS
echo "" # Adiciona uma quebra de linha após a senha secreta
echo "------------------------------------------------"
echo ""

# 2. ENCONTRA O ARQUIVO DE BACKUP
if [ -n "$1" ]; then
    # Modo Manual: Usa o arquivo especificado pelo usuário
    BACKUP_FILE_NAME="$1"
    BACKUP_FILE_PATH="${BACKUP_DIR}/${BACKUP_FILE_NAME}"
else
    # Modo Automático: Encontra o arquivo de backup mais recente no diretório
    echo "Nenhum arquivo especificado. Procurando o backup mais recente..."
    BACKUP_FILE_PATH=$(ls -t ${BACKUP_DIR}/*~.sql.gz | head -n 1)
fi

# 3. VERIFICA SE O ARQUIVO FOI ENCONTRADO
if [ -z "$BACKUP_FILE_PATH" ] || [ ! -f "$BACKUP_FILE_PATH" ]; then
    echo "ERRO: Nenhum arquivo de backup encontrado ou o arquivo especificado não existe."
    exit 1
fi

# 4. TRAVA DE SEGURANÇA E CONFIRMAÇÃO
echo ""
echo "============================ AVISO! ============================"
echo "Você está prestes a SOBRESCREVER o banco de dados '${DB_NAME}'."
echo "Os dados atuais serão PERDIDOS e substituídos pelo conteúdo do arquivo:"
echo ""
echo "  ==> ${BACKUP_FILE_PATH}"
echo ""
echo "================================================================"
read -p "Você tem ABSOLUTA certeza de que deseja continuar? (s/N): " response

if [[ "$response" =~ ^([sS][iI][mM]|[sS])$ ]]; then
    echo "Iniciando a restauração..."

    # 5. EXECUÇÃO DA RESTAURAÇÃO
    set -o pipefail
    gunzip < "$BACKUP_FILE_PATH" | mysql --user=${DB_USER} --password=${DB_PASS} ${DB_NAME}

    if [ $? -eq 0 ]; then
        echo "✅ Restauração concluída com sucesso!"
    else
        echo "❌ ERRO: A restauração falhou. Verifique as credenciais ou a integridade do arquivo de backup."
        exit 1
    fi
else
    echo "Operação abortada pelo usuário."
    exit 0
fi
