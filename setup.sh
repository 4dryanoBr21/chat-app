#!/bin/bash

# ─────────────────────────────────────────
#   Setup Script — Chat do Lambari
# ─────────────────────────────────────────

REPO_URL="https://github.com/4dryanoBr21/chat-app.git"
REPO_DIR="chat-app"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ─── Verifica se está rodando como root ───
if [ "$EUID" -ne 0 ]; then
    error "Execute o script como root: sudo bash setup.sh"
fi

# ─── Verifica o sistema operacional ───
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    error "Sistema operacional não suportado."
fi

# ─── Instala o Docker ───
install_docker() {
    warn "Docker não encontrado. Iniciando instalação..."

    case "$OS" in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y ca-certificates curl gnupg lsb-release

            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
              https://download.docker.com/linux/$OS \
              $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

            apt-get update -y
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|fedora)
            dnf -y install dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            error "Distribuição '$OS' não suportada por este script. Instale o Docker manualmente: https://docs.docker.com/engine/install/"
            ;;
    esac

    systemctl enable docker
    systemctl start docker

    log "Docker instalado com sucesso! $(docker --version)"
}

# ─── Instala o Git se necessário ───
install_git() {
    if ! command -v git &> /dev/null; then
        warn "Git não encontrado. Instalando..."
        case "$OS" in
            ubuntu|debian) apt-get install -y git ;;
            centos|rhel|fedora) dnf install -y git ;;
        esac
        log "Git instalado: $(git --version)"
    fi
}

# ════════════════════════════════════════════
#   INÍCIO
# ════════════════════════════════════════════

echo ""
echo "  🐟  Chat do Lambari — Setup"
echo "────────────────────────────────────────"
echo ""

# ─── Verifica o Docker ───
if command -v docker &> /dev/null; then
    log "Docker já está instalado: $(docker --version)"
else
    install_docker
fi

# ─── Verifica o Docker Compose ───
if docker compose version &> /dev/null; then
    log "Docker Compose já está disponível: $(docker compose version)"
else
    error "Docker Compose não encontrado. Tente reinstalar o Docker."
fi

# ─── Verifica e instala o Git ───
install_git

# ─── Clona o repositório ───
if [ -d "$REPO_DIR" ]; then
    warn "Pasta '$REPO_DIR' já existe. Atualizando repositório..."
    cd "$REPO_DIR" && git pull
else
    log "Clonando repositório..."
    git clone "$REPO_URL" "$REPO_DIR" || error "Falha ao clonar o repositório."
    cd "$REPO_DIR"
fi

# ─── Verifica se o docker-compose.yml existe ───
if [ ! -f "docker-compose.yml" ]; then
    error "Arquivo docker-compose.yml não encontrado no repositório."
fi

# ─── Sobe a aplicação ───
echo ""
log "Subindo a aplicação com Docker Compose..."
echo ""

docker compose up -d

echo ""
log "Aplicação rodando em: http://localhost:3000"
echo ""
