#!/bin/bash
# release-manager.sh - Script de gestión de releases para CodingSoft Open WebUI

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función de ayuda
show_help() {
    echo -e "${CYAN}🚀 CodingSoft Open WebUI - Release Manager${NC}"
    echo ""
    echo "Uso: ./release-manager.sh [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  version              Mostrar versión actual"
    echo "  prepare <version>    Preparar nueva versión (ej: 0.7.3)"
    echo "  changelog            Actualizar CHANGELOG.md"
    echo "  tag                  Crear tag de git"
    echo "  build                Construir imágenes Docker"
    echo "  publish              Publicar a registries"
    echo "  all <version>        Ejecutar todo el proceso de release"
    echo ""
    echo "Ejemplos:"
    echo "  ./release-manager.sh all 0.7.3"
    echo "  ./release-manager.sh prepare 0.7.3"
    echo ""
}

# Mostrar versión actual
version() {
    echo -e "${GREEN}📦 Versión Actual${NC}"
    echo ""
    
    # Frontend
    local frontend_version=$(grep '"version"' package.json | head -1 | sed 's/.*: "\(.*\)"/\1/')
    echo -e "${BLUE}Frontend:${NC}  ${frontend_version}"
    
    # Backend
    local backend_version=$(grep 'version = ' pyproject.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
    echo -e "${BLUE}Backend:${NC}   ${backend_version}"
    
    # Git
    echo ""
    echo -e "${BLUE}Git Tags:${NC}"
    git tag --sort=-version:refname | head -5
}

# Preparar nueva versión
prepare_version() {
    local new_version=$1
    
    if [ -z "$new_version" ]; then
        echo -e "${RED}❌ Error: Debes especificar una versión${NC}"
        echo "Uso: ./release-manager.sh prepare <version>"
        exit 1
    fi
    
    echo -e "${CYAN}📝 Preparando versión ${new_version}${NC}"
    echo ""
    
    # Actualizar package.json
    echo -e "${YELLOW}Actualizando package.json...${NC}"
    sed -i '' "s/\\"version\\": \\".*\\"/\\"version\\": \\"${new_version}\\"/" package.json
    
    # Actualizar pyproject.toml
    echo -e "${YELLOW}Actualizando pyproject.toml...${NC}"
    sed -i '' "s/version = \\".*\\"/version = \\"${new_version}\\"/" pyproject.toml
    
    echo ""
    echo -e "${GREEN}✅ Versión ${new_version} preparada${NC}"
}

# Actualizar CHANGELOG
update_changelog() {
    echo -e "${CYAN}📝 Actualizando CHANGELOG.md${NC}"
    echo ""
    
    # Obtener versión actual
    local version=$(grep '"version"' package.json | sed 's/.*: "\(.*\)"/\1/')
    local date=$(date +%Y-%m-%d)
    
    # Crear entrada de changelog
    local changelog_entry="## [${version}] - ${date}

### Added

- 🚀 Nueva funcionalidad agregada

### Changed

- 🔄 Cambios en funcionalidades existentes

### Fixed

- 🐛 Correcciones de bugs

### Security

- 🔐 Actualizaciones de seguridad
"
    
    # Insertar después del header
    local temp_file=$(mktemp)
    head -7 CHANGELOG.md > "$temp_file"
    echo "$changelog_entry" >> "$temp_file"
    tail -n +8 CHANGELOG.md >> "$temp_file"
    mv "$temp_file" CHANGELOG.md
    
    echo -e "${GREEN}✅ CHANGELOG.md actualizado${NC}"
}

# Crear tag
create_tag() {
    echo -e "${CYAN}🏷️ Creando tag de git${NC}"
    echo ""
    
    # Obtener versión
    local version=$(grep '"version"' package.json | sed 's/.*: "\(.*\)"/\1/')
    local tag="v${version}"
    
    # Verificar si ya existe
    if git rev-parse "${tag}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  El tag ${tag} ya existe${NC}"
        read -p "¿Deseas eliminarlo y crear uno nuevo? (s/n): " confirm
        if [ "$confirm" = "s" ]; then
            git tag -d "$tag"
        else
            exit 1
        fi
    fi
    
    # Crear tag
    git tag -a "$tag" -m "Release ${tag}"
    
    echo -e "${GREEN}✅ Tag ${tag} creado${NC}"
}

# Construir imágenes Docker
build_docker() {
    echo -e "${CYAN}🐳 Construyendo imágenes Docker${NC}"
    echo ""
    
    local version=$(grep '"version"' package.json | sed 's/.*: "\(.*\)"/\1/')
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no encontrado${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Construyendo imagen estándar...${NC}"
    docker build -t "ghcr.io/codingsoft/open-webui:v${version}" .
    docker tag "ghcr.io/codingsoft/open-webui:v${version}" "ghcr.io/codingsoft/open-webui:latest"
    
    echo ""
    echo -e "${GREEN}✅ Imágenes construidas${NC}"
}

# Proceso completo de release
release_all() {
    local new_version=$1
    
    if [ -z "$new_version" ]; then
        echo -e "${RED}❌ Error: Debes especificar una versión${NC}"
        echo "Uso: ./release-manager.sh all <version>"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 INICIANDO PROCESO COMPLETO DE RELEASE${NC}"
    echo "=========================================="
    echo ""
    
    # 1. Preparar versión
    echo -e "${YELLOW}1/4 Preparando versión...${NC}"
    ./release-manager.sh prepare "$new_version"
    
    # 2. Git add y commit
    echo -e "${YELLOW}2/4 Haciendo commit...${NC}"
    git add .
    git commit -m "Release v${new_version}"
    
    # 3. Crear tag
    echo -e "${YELLOW}3/4 Creando tag...${NC}"
    ./release-manager.sh tag
    
    # 4. Build
    echo -e "${YELLOW}4/4 Construyendo Docker...${NC}"
    ./release-manager.sh build
    
    echo ""
    echo "=========================================="
    echo -e "${GREEN}🎉 RELEASE COMPLETADO${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo "  git push origin main --tags"
}

# Main
case "${1:-help}" in
    version)
        version
        ;;
    prepare)
        prepare_version "${2}"
        ;;
    changelog)
        update_changelog
        ;;
    tag)
        create_tag
        ;;
    build)
        build_docker
        ;;
    all)
        release_all "${2}"
        ;;
    *)
        show_help
        ;;
esac
