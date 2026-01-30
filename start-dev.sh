#!/bin/bash
# start-dev.sh - Script de inicio rápido para desarrollo

echo "🚀 INICIANDO ENTORNO DE DESARROLLO..."
echo "==================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar si un puerto está libre
check_port() {
    if lsof -i:$1 > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Puerto $1 ocupado${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Puerto $1 libre${NC}"
        return 0
    fi
}

# Verificar prerrequisitos
echo -e "${BLUE}📋 Verificando prerrequisitos...${NC}"

# Verificar Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
else
    echo -e "${RED}❌ Node.js no encontrado${NC}"
    exit 1
fi

# Verificar Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✅ Python: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ Python no encontrado${NC}"
    exit 1
fi

# Verificar Docker (opcional)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
    DOCKER_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️  Docker no encontrado (Ollama no se iniciará)${NC}"
    DOCKER_AVAILABLE=false
fi

# Verificar puertos
echo -e "${BLUE}🔌 Verificando puertos...${NC}"
check_port 5173
check_port 7860
check_port 11434

# Iniciar Ollama con Docker (si está disponible)
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo -e "${BLUE}🐳 Iniciando Ollama con Docker...${NC}"
    
    # Verificar si el contenedor ya existe
    if docker ps -a --format '{{.Names}}' | grep -q "^ollama$"; then
        # Verificar si está ejecutándose
        if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
            echo -e "${GREEN}✅ Ollama ya está ejecutándose${NC}"
        else
            echo -e "${YELLOW}🔄 Reiniciando contenedor Ollama...${NC}"
            docker start ollama
        fi
    else
        # Crear y ejecutar nuevo contenedor
        docker run -d \
            --name ollama \
            -p 11434:11434 \
            -v ollama:/root/.ollama \
            ollama/ollama:latest
        
        echo -e "${GREEN}✅ Contenedor Ollama creado${NC}"
        echo -e "${YELLOW}⏳ Esperando que Ollama esté listo...${NC}"
        sleep 5
    fi
    
    # Verificar que Ollama está responding
    for i in {1..10}; do
        if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Ollama está respondiendo${NC}"
            break
        fi
        if [ $i -eq 10 ]; then
            echo -e "${RED}❌ Ollama no responde después de 10 intentos${NC}"
        fi
        sleep 2
    done
fi

# Iniciar Backend
echo -e "${BLUE}⚙️  Iniciando Backend...${NC}"
cd /Users/codingsoft/GitHub/open-webui/backend

# Verificar si el entorno virtual existe
if [ -d "venv" ]; then
    source venv/bin/activate
    echo -e "${GREEN}✅ Entorno virtual activado${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró entorno virtual, usando Python del sistema${NC}"
fi

# Iniciar servidor backend en background
uvicorn open_webui.main:app --reload --host 0.0.0.0 --port 7860 > /tmp/backend.log 2>&1 &
BACKEND_PID=$!

# Verificar que el backend inició
sleep 3
if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Backend ejecutándose (PID: $BACKEND_PID)${NC}"
else
    echo -e "${RED}❌ Error al iniciar backend${NC}"
    cat /tmp/backend.log
    exit 1
fi

# Iniciar Frontend
echo -e "${BLUE}🎨 Iniciando Frontend...${NC}"
cd /Users/codingsoft/GitHub/open-webui

# Iniciar servidor frontend en background
npm run dev > /tmp/frontend.log 2>&1 &
FRONTEND_PID=$!

# Verificar que el frontend inició
sleep 5
if ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Frontend ejecutándose (PID: $FRONTEND_PID)${NC}"
else
    echo -e "${RED}❌ Error al iniciar frontend${NC}"
    cat /tmp/frontend.log
    exit 1
fi

# Resumen
echo ""
echo "==================================="
echo -e "${GREEN}🎉 ENTORNO DE DESARROLLO INICIADO!${NC}"
echo "==================================="
echo ""
echo -e "${BLUE}🌐 FRONTEND:${NC}   http://localhost:5173"
echo -e "${BLUE}⚙️  BACKEND:${NC}    http://localhost:7860"
echo -e "${BLUE}📚 API DOCS:${NC}  http://localhost:7860/docs"
echo -e "${BLUE}🤖 OLLAMA:${NC}     http://localhost:11434"
echo ""
echo -e "${YELLOW}📝 Logs:${NC}"
echo "   Backend:  tail -f /tmp/backend.log"
echo "   Frontend: tail -f /tmp/frontend.log"
echo ""
echo -e "${YELLOW}🛑 Para detener:${NC}"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo ""

# Guardar PIDs para referencia
echo "$BACKEND_PID" > /tmp/dev-backend.pid
echo "$FRONTEND_PID" > /tmp/dev-frontend.pid

# Mantener script ejecutándose
echo -e "${BLUE}📋 Presiona Ctrl+C para detener todos los servicios${NC}"

# Manejo de señales
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"
    
    if [ -f /tmp/dev-backend.pid ]; then
        kill $(cat /tmp/dev-backend.pid) 2>/dev/null
        echo -e "${GREEN}✅ Backend detenido${NC}"
    fi
    
    if [ -f /tmp/dev-frontend.pid ]; then
        kill $(cat /tmp/dev-frontend.pid) 2>/dev/null
        echo -e "${GREEN}✅ Frontend detenido${NC}"
    fi
    
    exit 0
}

trap cleanup INT TERM

# Esperar indefinidamente
wait
