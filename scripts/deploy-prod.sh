#!/bin/bash
# deploy-prod.sh - Deploy CodingSoft Open WebUI to Production

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 CodingSoft Open WebUI - Production Deployment${NC}"
echo ""

# Funciones
show_help() {
    echo -e "${CYAN}Uso:${NC} ./deploy-prod.sh [comando]"
    echo ""
    echo "Comandos:"
    echo "  install      Instalar y configurar producción"
    echo "  start        Iniciar servicios"
    echo "  stop         Detener servicios"
    echo "  restart      Reiniciar servicios"
    echo "  status       Ver estado de servicios"
    echo "  logs         Ver logs"
    echo "  update       Actualizar imágenes"
    echo "  backup       Crear backup"
    echo "  restore      Restaurar backup"
    echo "  cleanup      Limpiar recursos"
}

install() {
    echo -e "${YELLOW}📦 Instalando producción...${NC}"
    echo ""
    
    # Verificar Docker y Docker Compose
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no instalado${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose no instalado${NC}"
        exit 1
    fi
    
    # Crear archivo .env si no existe
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Creando archivo .env desde .env.example...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Por favor edita el archivo .env con tus configuración${NC}"
        exit 1
    fi
    
    # Crear directorios necesarios
    mkdir -p nginx/ssl
    
    # Crear red de Docker
    echo -e "${YELLOW}Creando red de Docker...${NC}"
    docker network create webui-network 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}✅ Instalación completada${NC}"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo "  1. Edita el archivo .env con tus configuración"
    echo "  2. Configura SSL si es necesario"
    echo "  3. Ejecuta: ./deploy-prod.sh start"
}

start() {
    echo -e "${YELLOW}🚀 Iniciando servicios...${NC}"
    
    # Verificar .env
    if [ ! -f .env ]; then
        echo -e "${RED}❌ Archivo .env no encontrado${NC}"
        echo "Ejecuta: ./deploy-prod.sh install"
        exit 1
    fi
    
    # Verificar archivo .env
    if [ ! -f .env ]; then
        echo -e "${RED}❌ Archivo .env no encontrado${NC}"
        echo "Copia .env.example a .env y configúralo"
        exit 1
    fi

    # Pull imágenes
    echo -e "${YELLOW}Descargando imágenes...${NC}"
    docker compose -f docker-compose.prod.yml pull
    
    # Levantar servicios
    echo -e "${YELLOW}Levantando servicios...${NC}"
    docker compose -f docker-compose.prod.yml up -d
    
    echo ""
    echo -e "${GREEN}✅ Servicios iniciados${NC}"
    echo ""
    echo -e "${YELLOW}📊 Estado:${NC}"
    docker compose -f docker-compose.prod.yml ps
}

stop() {
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"
    docker compose -f docker-compose.prod.yml down
    echo -e "${GREEN}✅ Servicios detenido${NC}"
}

restart() {
    stop
    start
}

status() {
    echo -e "${CYAN}📊 Estado de Servicios${NC}"
    echo ""
    docker compose -f docker-compose.prod.yml ps
    echo ""
    echo -e "${CYAN}📈 Uso de Recursos${NC}"
    docker stats --no-stream $(docker ps --format '{{.Names}}' | grep -E '(webui|ollama|redis|nginx)')
}

logs() {
    echo -e "${CYAN}📋 Logs (Ctrl+C para salir)${NC}"
    echo ""
    docker compose -f docker-compose.prod.yml logs -f
}

update() {
    echo -e "${YELLOW}🔄 Actualizando imágenes...${NC}"

    # Verificar .env
    if [ ! -f .env ]; then
        echo -e "${RED}❌ Archivo .env no encontrado${NC}"
        exit 1
    fi

    # Pull imágenes
    docker compose -f docker-compose.prod.yml pull
    
    # Reiniciar servicios
    docker compose -f docker-compose.prod.yml up -d --no-deps
    
    echo -e "${GREEN}✅ Actualización completada${NC}"
}

backup() {
    echo -e "${YELLOW}💾 Creando backup...${NC}"
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup de base de datos
    echo -e "${YELLOW}Backup de base de datos...${NC}"
    docker cp codingsoft-webui:/app/backend/data/webui.db "$BACKUP_DIR/webui.db" 2>/dev/null || true
    
    # Backup de volumenes
    echo -e "${YELLOW}Backup de volúmenes...${NC}"
    docker run --rm -v webui-data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine tar czf /backup/webui-data.tar.gz -C /data . 2>/dev/null || true
    
    # Backup de Redis
    echo -e "${YELLOW}Backup de Redis...${NC}"
    docker exec codingsoft-redis redis-cli BGSAVE
    docker cp codingsoft-redis:/data/dump.rdb "$BACKUP_DIR/redis.rdb" 2>/dev/null || true
    
    # Comprimir backup completo
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar czf "$BACKUP_FILE" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
    rm -rf "$BACKUP_DIR"
    
    echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE${NC}"
}

restore() {
    echo -e "${YELLOW}🔄 Restaurando backup...${NC}"
    
    if [ -z "$2" ]; then
        echo -e "${RED}❌ Especifica el archivo de backup${NC}"
        echo "Uso: ./deploy-prod.sh restore backup.tar.gz"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ Archivo no encontrado: $BACKUP_FILE${NC}"
        exit 1
    fi
    
    # Detener servicios
    stop
    
    # Extraer backup
    TEMP_DIR=$(mktemp -d)
    tar xzf "$BACKUP_FILE" -C "$TEMP_DIR"
    
    # Restaurar volúmenes
    docker run --rm -v webui-data:/data -v "$TEMP_DIR":/backup alpine sh -c "cd /data && tar xzf /backup/webui-data.tar.gz"
    
    # Limpiar
    rm -rf "$TEMP_DIR"
    
    # Iniciar servicios
    start
    
    echo -e "${GREEN}✅ Backup restaurado${NC}"
}

cleanup() {
    echo -e "${YELLOW}🧹 Limpiando recursos no utilizados...${NC}"
    
    docker system prune -af
    docker volume prune -f
    
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Main
case "${1:-help}" in
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
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
    update)
        update
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$@"
        ;;
    cleanup)
        cleanup
        ;;
    *)
        show_help
        ;;
esac
