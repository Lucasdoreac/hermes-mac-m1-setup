#!/bin/bash
################################################################################
# Hermes Agent - Mac M1 Minimal Setup
# Controle Remoto via GitHub + gh CLI
#
# Objetivo: Instalar o MÍNIMO no Mac para permitir controle total via WSL
################################################################################

set -e  # Para em caso de erro

CORE_VERSION="1.0.0"
LOG_FILE="$HOME/hermes-mac-setup.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Funções de Log
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

################################################################################
# Banner Inicial
################################################################################

clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🍎 Hermes Agent - Mac M1 Minimal Setup                     ║
║   Controle Remoto via GitHub + gh CLI                        ║
║                                                               ║
║   Versão: 1.0.0                                              ║
║   Arquitetura: ARM64 (Apple Silicon)                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""
log "Iniciando setup do Hermes Agent no Mac M1..."
log "Arquivo de log: $LOG_FILE"
echo ""

################################################################################
# Verificações Iniciais
################################################################################

log "Verificando arquitetura do sistema..."
ARCH=$(uname -m)
log "Arquitetura detectada: $ARCH"

if [[ "$ARCH" != "arm64" ]]; then
    warn "AVISO: Este script foi otimizado para ARM64 (Apple Silicon)"
    warn "Arquitetura atual: $ARCH"
    read -p "Continuar mesmo assim? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Setup cancelado pelo usuário"
        exit 1
    fi
fi

log "Verificando conexão com internet..."
if ! ping -c 1 github.com &> /dev/null; then
    error "Sem conexão com internet!"
    exit 1
fi

################################################################################
# PASSO 1: Instalar Homebrew
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [1/7] Instalando Homebrew                                ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

if command -v brew &> /dev/null; then
    log "Homebrew já instalado: $(brew --version | head -1)"
else
    log "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configurar PATH para ARM64
    if [[ -d "/opt/homebrew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log "Homebrew configurado para ARM64"
    fi
fi

log "✅ Homebrew pronto"

################################################################################
# PASSO 2: Instalar Python 3.13 (ARM nativo)
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [2/7] Instalando Python 3.13 (ARM nativo)                ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

if command -v python3.13 &> /dev/null; then
    log "Python 3.13 já instalado: $(python3.13 --version)"
else
    log "Instalando Python 3.13 via Homebrew..."
    brew install python@3.13

    # Criar links simbólicos
    brew link python@3.13 --force
fi

# Verificar arquitetura do Python
PYTHON_ARCH=$(python3.13 -c "import platform; print(platform.machine())")
log "Python 3.13 arquitetura: $PYTHON_ARCH"

if [[ "$PYTHON_ARCH" != "arm64" ]]; then
    warn "AVISO: Python não está rodando em ARM64 nativo!"
    warn "Isso pode reduzir a performance"
fi

log "✅ Python 3.13 pronto"

################################################################################
# PASSO 3: Instalar ferramentas essenciais
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [3/7] Instalando ferramentas essenciais                   ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

PACKAGES=(
    "git"
    "gh"
    "curl"
    "wget"
    "jq"
    "vim"
)

for pkg in "${PACKAGES[@]}"; do
    if command -v "$pkg" &> /dev/null; then
        log "$pkg já instalado"
    else
        log "Instalando $pkg..."
        brew install "$pkg"
    fi
done

log "✅ Ferramentas essenciais prontas"

################################################################################
# PASSO 4: Instalar Hermes Agent
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [4/7] Instalando Hermes Agent                            ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

if command -v hermes &> /dev/null; then
    log "Hermes Agent já instalado: $(hermes --version | head -1)"
else
    log "Instalando Hermes Agent..."
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

    # Adicionar ao PATH
    echo 'export PATH="$HOME/.hermes/bin:$PATH"' >> "$HOME/.zshrc"
    export PATH="$HOME/.hermes/bin:$PATH"
fi

log "✅ Hermes Agent pronto"

################################################################################
# PASSO 5: Configurar Git
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [5/7] Configurando Git                                    ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

log "Configurando Git..."
git config --global user.name "Lucas"
git config --global user.email "lucasdoreac@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input

log "✅ Git configurado"

################################################################################
# PASSO 6: Autenticar GitHub CLI
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [6/7] Autenticando GitHub CLI                             ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

if gh auth status &> /dev/null; then
    log "GitHub CLI já autenticado"
    gh auth status
else
    log "Autenticando GitHub CLI..."
    gh auth login

    log "Verificando autenticação..."
    gh auth status
fi

log "✅ GitHub CLI autenticado"

################################################################################
# PASSO 7: Criar estrutura de diretórios
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║ [7/7] Criando estrutura de diretórios                    ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

DIRS=(
    "$HOME/.hermes"
    "$HOME/.hermes/skills"
    "$HOME/.hermes/scripts"
    "$HOME/.hermes/docs"
    "$HOME/.hermes/memory"
    "$HOME/hermes-tasks"
    "$HOME/hermes-logs"
)

for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log "Criando diretório: $dir"
        mkdir -p "$dir"
    fi
done

log "✅ Estrutura de diretórios criada"

################################################################################
# Setup Completo
################################################################################

log ""
log "╔═══════════════════════════════════════════════════════════╗"
log "║           ✅ SETUP COMPLETO COM SUCESSO!                  ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""

log "Resumo da instalação:"
log "  - Homebrew: $(brew --version | head -1)"
log "  - Python: $(python3.13 --version) ($PYTHON_ARCH)"
log "  - Git: $(git --version)"
log "  - gh CLI: $(gh --version)"
log "  - Hermes: $(hermes --version | head -1)"
log ""

log "Arquivo de log: $LOG_FILE"
log ""

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                  PRÓXIMOS PASSOS                             ║
╚═══════════════════════════════════════════════════════════════╝

1. No WSL, crie um repositório para comandos:
   gh repo create hermes-mac-tasks --public

2. No Mac, clone o repositório:
   cd ~/hermes-tasks
   gh repo clone hermes-mac-tasks

3. Crie um script de execução automática:
   cat > ~/hermes-tasks/executor.sh << 'SCRIPT'
   #!/bin/bash
   while true; do
       cd ~/hermes-tasks
       git pull origin main
       if [[ -f "task.sh" ]]; then
           bash task.sh > ~/hermes-logs/task-$(date +%s).log 2>&1
           rm task.sh
           git rm task.sh
           git commit -m "Task completed"
           git push
       fi
       sleep 60
   done
   SCRIPT

   chmod +x ~/hermes-tasks/executor.sh

4. No WSL, envie comandos para o Mac:
   gh issue create \
     --repo hermes-mac-tasks \
     --title "Comando: <seu comando>" \
     --body "<comando detalhado>"

5. Ou use GitHub Actions para execução remota!

EOF

log "Setup concluído! Mac M1 pronto para controle remoto via GitHub."
log ""

exit 0
