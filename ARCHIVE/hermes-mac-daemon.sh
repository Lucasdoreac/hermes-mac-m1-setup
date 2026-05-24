#!/bin/bash
################################################################################
# Hermes Mac Daemon - Poll GitHub for commands and execute
################################################################################

set -e

REPO_NAME="hermes-mac-tasks"
GITHUB_USER="lucasdoreac"
REPO_DIR="$HOME/hermes-tasks/$REPO_NAME"
LOG_DIR="$HOME/hermes-logs"
POLL_INTERVAL=60  # segundos

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

################################################################################
# Setup inicial
################################################################################

setup() {
    log "Inicializando Hermes Mac Daemon..."

    # Criar diretórios
    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"

    # Clonar repositório se não existe
    if [[ ! -d "$REPO_DIR" ]]; then
        log "Clonando repositório $GITHUB_USER/$REPO_NAME..."
        cd "$(dirname "$REPO_DIR")"

        if gh repo clone "$GITHUB_USER/$REPO_NAME" 2>/dev/null; then
            log "Repositório clonado com sucesso"
        else
            error "Falha ao clonar repositório!"
            error "Execute o setup no WSL primeiro:"
            error "  hermes-remote-control.sh setup"
            exit 1
        fi
    fi

    log "Setup completo!"
}

################################################################################
# Poll por comandos
################################################################################

poll() {
    cd "$REPO_DIR" || {
        error "Diretório do repositório não encontrado: $REPO_DIR"
        exit 1
    }

    # Pull latest changes
    log "Buscando atualizações..."
    git pull origin main > /dev/null 2>&1 || true

    # Verificar se há task
    if [[ -f "task.sh" ]]; then
        log "📨 Task encontrada! Executando..."

        # Timestamp para log
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        LOG_FILE="$LOG_DIR/task-$TIMESTAMP.log"

        # Executar task
        log "Executando: task.sh"
        log "Log: $LOG_FILE"

        bash task.sh > "$LOG_FILE" 2>&1
        EXIT_CODE=$?

        log "Task concluída (exit code: $EXIT_CODE)"

        # Adicionar log ao repo
        mkdir -p logs
        cp "$LOG_FILE" "logs/"

        # Remover task
        git rm task.sh
        git add logs/
        git commit -m "Task completed (exit: $EXIT_CODE)"
        git push origin main

        log "✅ Task processada e resultado enviado!"
    else
        log "Nenhuma task encontrada. Aguardando..."
    fi
}

################################################################################
# Daemon loop
################################################################################

daemon() {
    log "╔═══════════════════════════════════════════════════════════════╗"
    log "║         Hermes Mac Daemon - Iniciado                         ║"
    log "║         Poll interval: ${POLL_INTERVAL}s                            ║"
    log "╚═══════════════════════════════════════════════════════════════╝"
    log ""

    while true; do
        poll
        log "Aguardando ${POLL_INTERVAL}s até próxima verificação..."
        sleep "$POLL_INTERVAL"
    done
}

################################################################################
# Main
################################################################################

case "${1:-daemon}" in
    setup)
        setup
        ;;
    poll)
        poll
        ;;
    daemon)
        setup
        daemon
        ;;
    *)
        echo "Uso: $0 {setup|poll|daemon}"
        echo ""
        echo "Comandos:"
        echo "  setup    - Configura repositório local"
        echo "  poll     - Faz uma única verificação"
        echo "  daemon   - Modo daemon (loop infinito)"
        exit 1
        ;;
esac
