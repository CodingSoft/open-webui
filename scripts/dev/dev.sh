#!/bin/bash
# dev.sh - Script maestro de desarrollo CodingSoft Open WebUI
# https://github.com/codingsoft/open-webui

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

show_help() {
    echo -e "${CYAN}🚀 CodingSoft Open WebUI - Entorno de Desarrollo${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC} ./dev.sh [comando]"
    echo ""
    echo "Comandos:"
    echo "  local       Desarrollo local (Node.js + Python + sin Docker)"
    echo "  docker      Desarrollo con Docker Compose (entorno aislado)"
    echo "  backend     Solo backend (requiere Python)"
    echo "  frontend    Solo frontend (requiere Node.js)"
    echo "  status      Ver estado de servicios"
    echo "  stop        Detener todos los servicios"
    echo "  restart     Reiniciar servicios"
    echo "  logs        Ver logs en tiempo real"
    echo "  deps        Verificar dependencias"
    echo "  help        Mostrar esta ayuda"
    echo ""
    echo "Métodos disponibles:"
    echo "  local       ⚡ Rápido, desarrollo directo"
    echo "  docker      📦 Entorno aislado, like-producción"
}

check_dependencies() {
    echo -e "${BLUE}📋 Verificando dependencias...${NC}"
    echo ""

    # Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
    else
        echo -e "${RED}❌ Node.js no encontrado${NC}"
        echo "   Instalar: https://nodejs.org/"
    fi

    # Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✅ Python: $PYTHON_VERSION${NC}"
    else
        echo -e "${RED}❌ Python no encontrado${NC}"
        echo "   Instalar: https://python.org/"
    fi

    # Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
        DOCKER_AVAILABLE=true
    else
        echo -e "${YELLOW}⚠️  Docker no encontrado (opción docker no disponible)${NC}"
        DOCKER_AVAILABLE=false
    fi

    # Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker Compose disponible${NC}"
    else
        echo -e "${RED}❌ Docker Compose no encontrado${NC}"
    fi

    echo ""
}

status() {
    echo -e "${CYAN}📊 Estado de Servicios de Desarrollo${NC}"
    echo ""

    # Frontend
    if lsof -i:5173 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend: http://localhost:5173${NC}"
    else
        echo -e "${RED}❌ Frontend: No iniciado${NC}"
    fi

    # Backend
    if lsof -i:7860 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend: http://localhost:7860${NC}"
    else
        echo -e "${RED}❌ Backend: No iniciado${NC}"
    fi

    # API Docs
    if curl -s http://localhost:7860/docs > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API Docs: http://localhost:7860/docs${NC}"
    else
        echo -e "${YELLOW}⚠️  API Docs: No disponible${NC}"
    fi

    # Ollama
    if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama: http://localhost:11434${NC}"
    else
        echo -e "${YELLOW}⚠️  Ollama: No disponible${NC}"
    fi

    echo ""
    echo -e "${CYAN}Procesos:${NC}"
    ps aux | grep -E 'vite|uvicorn' | grep -v grep || echo "Sin procesos en ejecución"
}

stop() {
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"

    # Detener procesos
    if [ -f /tmp/dev-frontend.pid ]; then
        kill $(cat /tmp/dev-frontend.pid) 2>/dev/null || true
        rm -f /tmp/dev-frontend.pid
    fi

    if [ -f /tmp/dev-backend.pid ]; then
        kill $(cat /tmp/dev-backend.pid) 2>/dev/null || true
        rm -f /tmp/dev-backend.pid
    fi

    # Matar procesos en puertos
    fuser -k 5173/tcp 2>/dev/null || true
    fuser -k 7860/tcp 2>/dev/null || true

    # Detener contenedores Docker si existen
    if command -v docker &> /dev/null; then
        docker stop ollama-dev 2>/dev/null || true
        docker rm ollama-dev 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Servicios detenido${NC}"
}

restart() {
    stop
    echo ""
    echo -e "${YELLOW}🔄 Reiniciando...${NC}"
    echo ""
    local method="${1:-local}"
    case "$method" in
        local) ./dev:local.sh ;;
        docker) ./dev:docker.sh ;;
        *) echo -e "${RED}Método desconocido: $method${NC}" ;;
    esac
}

logs() {
    echo -e "${CYAN}📋 Logs (Ctrl+C para salir)${NC}"
    echo ""
    tail -f /tmp/dev-frontend.log /tmp/dev-backend.log 2>/dev/null || \
    echo "Logs no encontrados. Inicia los servicios primero."
}

local_dev() {
    echo -e "${CYAN}⚡ Modo desarrollo local${NC}"
    echo ""
    exec ./dev:local.sh "$@"
}

docker_dev() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no disponible${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose no disponible${NC}"
        exit 1
    fi

    echo -e "${CYAN}📦 Modo desarrollo con Docker${NC}"
    echo ""
    exec ./dev:docker.sh "$@"
}

backend_only() {
    echo -e "${CYAN}⚙️  Iniciando solo backend...${NC}"
    exec ./dev:local.sh backend
}

frontend_only() {
    echo -e "${CYAN}🎨 Iniciando solo frontend...${NC}"
    exec ./dev:local.sh frontend
}

main() {
    case "${1:-help}" in
        local)
            local_dev "${@:2}"
            ;;
        docker)
            docker_dev "${@:2}"
            ;;
        backend)
            backend_only
            ;;
        frontend)
            frontend_only
            ;;
        status)
            status
            ;;
        stop)
            stop
            ;;
        restart)
            restart "${2:-local}"
            ;;
        logs)
            logs
            ;;
        deps|check)
            check_dependencies
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
