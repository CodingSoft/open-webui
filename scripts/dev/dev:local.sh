#!/bin/bash
# dev:local.sh - Desarrollo local sin Docker
# Inicia frontend (Node.js) + backend (Python) + Ollama

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
    echo -e "${CYAN}⚡ Desarrollo Local sin Docker${NC}"
    echo ""
    echo "Uso: ./dev:local.sh [comando]"
    echo ""
    echo "Comandos:"
    echo "  (sin args)  Iniciar todos los servicios"
    echo "  backend     Solo backend"
    echo "  frontend    Solo frontend"
    echo "  ollama      Solo Ollama (Docker)"
    echo "  stop        Detener servicios"
    echo "  status      Ver estado"
    echo "  help        Ayuda"
}

check_port() {
    if lsof -i:$1 > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Puerto $1 ocupado${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Puerto $1 libre${NC}"
        return 0
    fi
}

start_ollama() {
    echo -e "${BLUE}🤖 Verificando Ollama...${NC}"

    if command -v docker &> /dev/null; then
        if docker ps -a --format '{{.Names}}' | grep -q "^ollama-dev$"; then
            if docker ps --format '{{.Names}}' | grep -q "^ollama-dev$"; then
                echo -e "${GREEN}✅ Ollama ya ejecutándose${NC}"
                return 0
            else
                echo -e "${YELLOW}🔄 Reiniciando Ollama...${NC}"
                docker start ollama-dev
                sleep 5
                return 0
            fi
        fi

        echo -e "${BLUE}🐳 Iniciando Ollama con Docker...${NC}"
        docker run -d \
            --name ollama-dev \
            -p 11434:11434 \
            -v ollama-dev:/root/.ollama \
            ollama/ollama:latest

        echo -e "${YELLOW}⏳ Esperando Ollama...${NC}"
        for i in {1..15}; do
            if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Ollama listo${NC}"
                return 0
            fi
            sleep 2
        done
        echo -e "${RED}❌ Ollama no respondió${NC}"
        return 1
    else
        if pgrep -x ollama > /dev/null; then
            echo -e "${GREEN}✅ Ollama ejecutándose${NC}"
            return 0
        fi
        echo -e "${YELLOW}⚠️  Ollama no instalado. Instálalo desde https://ollama.com/${NC}"
        return 0
    fi
}

start_backend() {
    echo -e "${BLUE}⚙️  Iniciando Backend (Python/FastAPI)...${NC}"

    cd "$PROJECT_DIR/backend"

    if [ -d "venv" ]; then
        source venv/bin/activate
    fi

    export PYTHONPATH="$PROJECT_DIR/backend:$PYTHONPATH"
    export WEBUI_SECRET_KEY="dev-secret-key-change-in-production"

    uvicorn open_webui.main:app --reload --host 0.0.0.0 --port 7860 \
        > /tmp/dev-backend.log 2>&1 &
    BACKEND_PID=$!

    echo "$BACKEND_PID" > /tmp/dev-backend.pid

    sleep 4

    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend ejecutándose (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${RED}❌ Error al iniciar backend${NC}"
        cat /tmp/dev-backend.log
        exit 1
    fi
}

start_frontend() {
    echo -e "${BLUE}🎨 Iniciando Frontend (Svelte/Vite)...${NC}"

    cd "$PROJECT_DIR"

    npm run dev > /tmp/dev-frontend.log 2>&1 &
    FRONTEND_PID=$!

    echo "$FRONTEND_PID" > /tmp/dev-frontend.pid

    sleep 6

    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend ejecutándose (PID: $FRONTEND_PID)${NC}"
    else
        echo -e "${RED}❌ Error al iniciar frontend${NC}"
        cat /tmp/dev-frontend.log
        exit 1
    fi
}

stop() {
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"

    [ -f /tmp/dev-frontend.pid ] && kill $(cat /tmp/dev-frontend.pid) 2>/dev/null || true
    [ -f /tmp/dev-backend.pid ] && kill $(cat /tmp/dev-backend.pid) 2>/dev/null || true

    rm -f /tmp/dev-frontend.pid /tmp/dev-backend.pid

    fuser -k 5173/tcp 2>/dev/null || true
    fuser -k 7860/tcp 2>/dev/null || true

    if command -v docker &> /dev/null; then
        docker stop ollama-dev 2>/dev/null || true
        docker rm ollama-dev 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Servicios detenido${NC}"
}

status() {
    echo -e "${CYAN}📊 Estado del Entorno Local${NC}"
    echo ""

    lsof -i:5173 > /dev/null 2>&1 && echo -e "${GREEN}✅ Frontend:5173${NC}" || echo -e "${RED}❌ Frontend:5173${NC}"
    lsof -i:7860 > /dev/null 2>&1 && echo -e "${GREEN}✅ Backend:7860${NC}" || echo -e "${RED}❌ Backend:7860${NC}"
    curl -s http://localhost:11434/api/version > /dev/null 2>&1 && echo -e "${GREEN}✅ Ollama:11434${NC}" || echo -e "${YELLOW}⚠️ Ollama:11434${NC}"
}

main() {
    case "${1:-start}" in
        start|"")
            echo -e "${CYAN}⚡ Iniciando Entorno de Desarrollo Local${NC}"
            echo ""
            echo "Verificando puertos..."
            check_port 5173 || true
            check_port 7860 || true
            echo ""

            start_ollama
            start_backend
            start_frontend

            echo ""
            echo "==================================="
            echo -e "${GREEN}🎉 Entorno listo!${NC}"
            echo "==================================="
            echo ""
            echo -e "${BLUE}🌐 Frontend:  http://localhost:5173${NC}"
            echo -e "${BLUE}⚙️  Backend:   http://localhost:7860${NC}"
            echo -e "${BLUE}📚 API Docs:  http://localhost:7860/docs${NC}"
            echo -e "${BLUE}🤖 Ollama:    http://localhost:11434${NC}"
            echo ""
            echo "Logs: tail -f /tmp/dev-frontend.log /tmp/dev-backend.log"
            ;;
        backend)
            start_backend
            ;;
        frontend)
            start_frontend
            ;;
        ollama)
            start_ollama
            ;;
        stop)
            stop
            ;;
        status)
            status
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
