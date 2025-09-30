# Scripts de Backup e Restore para Zabbix (MariaDB/MySQL)

Este repositório contém um conjunto de scripts em Shell para automatizar o processo de backup e restauração de bancos de dados MariaDB/MySQL. A solução foi projetada para ser leve, robusta e de baixo custo, ideal para proteger uma instância do Zabbix (ou qualquer outro banco de dados crítico) em uma infraestrutura com recursos limitados.

## Funcionalidades ✨

- **Backup Automatizado:** Cria "snapshots" lógicos e consistentes do banco de dados diariamente.
- **Compressão:** Os backups são comprimidos em tempo real para economizar espaço em disco.
- **Retenção Automática:** Gerencia o espaço de armazenamento, apagando backups mais antigos que 3 dias.
- **Monitoramento Proativo:** Exibe um status do último backup (SUCESSO ou FALHA) a cada login no servidor.
- **Restauração Segura:** Oferece um script de restauração interativo com travas de segurança para prevenir acidentes.

---

## Como Funciona

A solução é composta por três scripts principais:

### 1. `backup_db.sh`
Este é o coração do sistema. Sua lógica é a seguinte:
- **Execução:** É projetado para ser executado via `cron` (agendador de tarefas).
- **Snapshot Consistente:** Utiliza `mariadb-dump` com a flag `--single-transaction`, que garante uma cópia consistente das tabelas (do tipo InnoDB) sem a necessidade de travar o banco ou interromper o serviço.
- **Compressão:** A saída do `mariadb-dump` é enviada via pipe (`|`) diretamente para o `gzip`. Isso significa que o backup é comprimido em tempo real, sem a necessidade de criar um arquivo `.sql` gigante temporário.
- **Registro:** Ao final da execução, ele adiciona uma linha no arquivo `/var/log/backup_status.log`, registrando se a operação foi um `SUCESSO` ou uma `FALHA`.
- **Limpeza:** Utiliza o comando `find` para procurar e apagar arquivos de backup na pasta de destino que sejam mais antigos que o período de retenção (3 dias).

### 2. `restore_db.sh`
Este script é a sua ferramenta de recuperação. **É uma operação destrutiva e deve ser usada com cuidado.**
- **Interatividade:** Ele não possui configurações fixas. Ao ser executado, ele solicita interativamente as credenciais (banco de dados, usuário e senha) do banco de destino. A senha é digitada de forma oculta.
- **Dois Modos de Operação:**
    1.  **Modo Automático:** Se executado sem argumentos (`sudo ./restore_db.sh`), ele automaticamente encontra o arquivo de backup mais recente na pasta de backups.
    2.  **Modo Manual:** Se você passar um nome de arquivo como argumento (`sudo ./restore_db.sh nome-do-arquivo.sql.gz`), ele usará esse arquivo específico.
- **Trava de Segurança:** Antes de executar a restauração, o script exibe um aviso claro, mostrando qual banco de dados será sobrescrito e qual arquivo será usado, exigindo uma confirmação explícita (`s` ou `sim`) para prosseguir.

### 3. `backup-status.sh`
Este é o script de "boas-vindas" ou monitoramento.
- **Gatilho:** Ele deve ser colocado no diretório `/etc/profile.d/` e é executado automaticamente toda vez que um usuário faz login no sistema via terminal (SSH).
- **Lógica:** O script lê a última linha do arquivo `/var/log/backup_status.log` e exibe uma mensagem formatada e colorida, informando o status do último backup (✅ SUCESSO ou ❌ FALHA) e os detalhes.

---

## Instalação e Configuração

1.  **Copie os Scripts para os Diretórios Padrão:**
    ```bash
    # Scripts executáveis de sistema
    sudo cp backup_db.sh /usr/local/sbin/
    sudo cp restore_db.sh /usr/local/sbin/
    
    # Script de boas-vindas para login
    sudo cp backup-status.sh /etc/profile.d/
    ```

2.  **Dê as Permissões Adequadas:**
    Os scripts precisam de permissão de execução.
    ```bash
    sudo chmod +x /usr/local/sbin/backup_db.sh
    sudo chmod +x /usr/local/sbin/restore_db.sh
    sudo chmod +x /etc/profile.d/backup-status.sh
    ```

3.  **Crie o Diretório de Backups e o Arquivo de Log:**
    ```bash
    sudo mkdir -p /var/backups/sql
    sudo touch /var/log/backup_status.log
    sudo chmod 666 /var/log/backup_status.log
    ```

4.  **Agende o Backup no `cron`:**
    Execute `sudo crontab -e` e adicione a linha abaixo para rodar o backup todo dia às 2h da manhã.
    ```crontab
    0 2 * * * /usr/local/sbin/backup_db.sh > /var/log/backup_db.log 2>&1
    ```

### ⚠️ Nota Importante sobre Segurança

Manter usuário e senha diretamente no script (`backup_db.sh`) não é uma prática recomendada. Embora uma alternativa seja o uso de variáveis de ambiente, para tarefas agendadas com `cron` o método mais seguro e robusto é usar um **arquivo de configuração de cliente do MariaDB/MySQL**.

**Como fazer:**
1. Crie o arquivo `/root/.my.cnf`. O `cron` roda como `root`, então ele lerá este arquivo.
    ```bash
    sudo nano /root/.my.cnf
    ```
2. Adicione o seguinte conteúdo:
    ```ini
    [client]
    user=seu_usuario_de_backup
    password=sua_senha_secreta
    host=localhost
    ```
3. Dê permissões restritas ao arquivo, para que apenas o usuário `root` possa lê-lo:
    ```bash
    sudo chmod 600 /root/.my.cnf
    ```
4. Após isso, você pode **remover as variáveis `DB_USER` e `DB_PASS` e os parâmetros `--user` e `--password`** do comando `mariadb-dump` no seu script `backup_db.sh`. O comando os lerá automaticamente do arquivo `.my.cnf` de forma segura.
