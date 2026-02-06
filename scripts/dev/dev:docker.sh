#!/bin/bash
# dev:docker.sh - Desarrollo con Docker Compose
# Entorno aislado con frontend + backend + Ollama

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

show_help() {
    echo -e "${CYAN}📦 Desarrollo con Docker Compose${NC}"
    echo ""
    echo "Uso: ./dev:docker.sh [comando]"
    echo ""
    echo "Comandos:"
    echo "  (sin args)  Iniciar todos los servicios"
    echo "  build       Reconstruir imágenes"
    echo "  up          Iniciar servicios"
    echo "  down        Detener servicios"
    echo "  stop        Detener servicios"
    echo "  restart     Reiniciar servicios"
    echo "  status      Ver estado"
    echo "  logs        Ver logs"
    echo "  ollama      Solo Ollama"
    echo "  help        Ayuda"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no instalado${NC}"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        echo -e "${RED}❌ Docker daemon no ejecutándose${NC}"
        exit 1
    fi
}

start_all() {
    echo -e "${CYAN}📦 Iniciando entorno Docker${NC}"
    echo ""

    check_docker

    echo -e "${BLUE}🏗️  Construyendo imágenes (primera vez)...${NC}"
    docker compose -f docker-compose.yaml build --no-cache

    echo -e "${BLUE}🚀 Levantando servicios...${NC}"
    docker compose -f docker-compose.yaml up -d

    echo ""
    echo -e "${YELLOW}⏳ Esperando servicios...${NC}"
    sleep 10

    echo ""
    echo "==================================="
    echo -e "${GREEN}🎉 Entorno Docker iniciado!${NC}"
    echo "==================================="
    echo ""
    echo -e "${BLUE}🌐 WebUI:     http://localhost:3000${NC}"
    echo -e "${BLUE}🤖 Ollama:    http://localhost:11434${NC}"
    echo ""
    echo "Logs: docker compose -f docker-compose.yaml logs -f"
}

start_ollama_only() {
    echo -e "${CYAN}🤖 Iniciando solo Ollama...${NC}"

    check_docker

    if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
        echo -e "${GREEN}✅ Ollama ya ejecutándose${NC}"
        return 0
    fi

    docker compose -f docker-compose.yaml up -d ollama
    echo -e "${GREEN}✅ Ollama iniciado${NC}"
}

stop() {
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"
    docker compose -f docker-compose.yaml down
    echo -e "${GREEN}✅ Servicios detenido${NC}"
}

restart() {
    echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"
    docker compose -f docker-compose.yaml restart
    echo -e "${GREEN}✅ Servicios reiniciados${NC}"
}

build() {
    echo -e "${BLUE}🏗️  Reconstruyendo imágenes...${NC}"
    docker compose -f docker-compose.yaml build --no-cache
    echo -e "${GREEN}✅ Imágenes reconstruidas${NC}"
}

status() {
    echo -e "${CYAN}📊 Estado de Contenedores${NC}"
    echo ""
    docker compose -f docker-compose.yaml ps
}

logs() {
    echo -e "${CYAN}📋 Logs (Ctrl+C para salir)${NC}"
    docker compose -f docker-compose.yaml logs -f
}

main() {
    case "${1:-start}" in
        start|"")
            start_all
            ;;
        up)
            start_all
            ;;
        build)
            build
            ;;
        down|stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        logs)
            logs
            ;;
        ollama)
            start_ollama_only
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
