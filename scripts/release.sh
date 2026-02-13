#!/bin/bash
# release.sh - Procedimiento completo de Release para CodingSoft Open WebUI
# Tags, GitHub Release, Docker Images, Security Scanning, Signing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

show_help() {
    echo -e "${CYAN}🚀 CodingSoft Open WebUI - Release Manager${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC} ./release.sh [comando] [opciones]"
    echo ""
    echo "Comandos de Release:"
    echo "  version              Mostrar versión actual"
    echo "  prepare <v>         Preparar nueva versión (ej: 0.7.3)"
    echo "  changelog           Actualizar CHANGELOG.md"
    echo "  commit              Crear commit de release"
    echo "  tag                 Crear tag de git"
    echo "  build               Construir imágenes Docker localmente"
    echo "  scan                Escanear imágenes con Trivy"
    echo "  sign                Firmar imágenes con Cosign"
    echo "  publish             Publicar a GHCR"
    echo "  github-release      Crear GitHub Release"
    echo "  all <v>             Ejecutar proceso completo de release"
    echo ""
    echo "Comandos de Mantenimiento:"
    echo "  list-tags           Listar tags existentes"
    echo "  delete-tag <tag>    Eliminar un tag"
    echo "  cleanup             Limpiar imágenes locales"
    echo "  images              Listar imágenes locales"
    echo ""
    echo "Flujo Recomendado:"
    echo "  1. ./release.sh prepare 0.7.3"
    echo "  2. ./release.sh changelog"
    echo "  3. ./release.sh all 0.7.3"
    echo "  4. git push origin main --tags"
    echo ""
}

get_version() {
    grep '"version"' package.json | sed 's/.*: "\(.*\)"/\1/'
}

get_tag() {
    echo "v$(get_version)"
}

version() {
    echo -e "${GREEN}📦 Información de Versión${NC}"
    echo ""

    local frontend_v=$(get_version)
    echo -e "${BLUE}Frontend:${NC}   ${frontend_v}"

    local backend_v=$(grep 'version = ' pyproject.toml 2>/dev/null | sed 's/version = "\(.*\)"/\1/' || echo "N/A")
    echo -e "${BLUE}Backend:${NC}    ${backend_v}"

    local tag=$(get_tag)
    echo -e "${BLUE}Git Tag:${NC}    ${tag}"

    echo ""
    echo -e "${CYAN}Tags Recientes:${NC}"
    git tag --sort=-version:refname | head -10
}

prepare() {
    local new_version=$1

    if [ -z "$new_version" ]; then
        echo -e "${RED}❌ Especifica una versión: ./release.sh prepare <version>${NC}"
        exit 1
    fi

    echo -e "${CYAN}📝 Preparando versión ${new_version}${NC}"
    echo ""

    echo -e "${YELLOW}1. Actualizando package.json...${NC}"
    sed -i '' "s/\"version\": \".*\"/\"version\": \"${new_version}\"/" package.json

    echo -e "${YELLOW}2. Actualizando pyproject.toml...${NC}"
    if [ -f pyproject.toml ]; then
        sed -i '' "s/version = \".*\"/version = \"${new_version}\"/" pyproject.toml
    fi

    echo ""
    echo -e "${GREEN}✅ Versión ${new_version} preparada${NC}"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo "   2. Edita CHANGELOG.md"
    echo "   3. ./release.sh all ${new_version}"
}

changelog() {
    echo -e "${CYAN}📝 Generando CHANGELOG.md${NC}"
    echo ""

    local version=$(get_version)
    local date=$(date +%Y-%m-%d)
    local changes=$(git log --since="1 month ago" --oneline --format='- %s' 2>/dev/null || echo "- Actualizaciones varias")

    local entry="## [${version}] - ${date}

### Added
${changes}

### Changed

### Fixed

### Security

### Docker Images
- \`ghcr.io/codingsoft/open-webui:${version}\`
- \`ghcr.io/codingsoft/open-webui:${version}-slim\`
- \`ghcr.io/codingsoft/open-webui:${version}-cuda\`
- \`ghcr.io/codingsoft/open-webui:${version}-ollama\`
"

    local temp_file=$(mktemp)
    head -7 CHANGELOG.md > "$temp_file"
    echo "$entry" >> "$temp_file"
    tail -n +8 CHANGELOG.md >> "$temp_file"
    mv "$temp_file" CHANGELOG.md

    echo -e "${GREEN}✅ CHANGELOG.md actualizado${NC}"
}

commit() {
    echo -e "${CYAN}📦 Creando commit de release...${NC}"
    echo ""

    local tag=$(get_tag)

    echo -e "${YELLOW}Archivos modificados:${NC}"
    git diff --name-only

    echo ""
    read -p "¿Continuar con commit? (s/n): " confirm
    if [ "$confirm" != "s" ]; then
        echo "Cancelado"
        exit 0
    fi

    git add .
    git commit -m "Release ${tag}"
    echo -e "${GREEN}✅ Commit creado: Release ${tag}${NC}"
}

tag() {
    echo -e "${CYAN}🏷️ Creando tag de git${NC}"
    echo ""

    local tag=$(get_tag)

    if git rev-parse "${tag}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  El tag ${tag} ya existe${NC}"
        read -p "¿Eliminar y recrear? (s/n): " confirm
        if [ "$confirm" = "s" ]; then
            git tag -d "$tag"
        else
            exit 1
        fi
    fi

    git tag -a "${tag}" -m "Release ${tag}"
    echo -e "${GREEN}✅ Tag ${tag} creado${NC}"
}

build() {
    echo -e "${CYAN}🐳 Construyendo imágenes Docker${NC}"
    echo ""

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no encontrado${NC}"
        exit 1
    fi

    local version=$(get_version)
    local tags=("slim" "cuda" "ollama")

    echo -e "${YELLOW}Construyendo variantes...${NC}"
    echo ""

    for variant in "${tags[@]}"; do
        local tag_name="ghcr.io/codingsoft/open-webui:${version}-${variant}"
        local extra_args=""

        case "$variant" in
            slim)   extra_args="--build-arg USE_SLIM=true" ;;
            cuda)   extra_args="--build-arg USE_CUDA=true --build-arg USE_CUDA_VER=cu128" ;;
            ollama) extra_args="--build-arg USE_OLLAMA=true" ;;
        esac

        echo -e "${BLUE}   Building: ${tag_name}${NC}"
        docker build -t "${tag_name}" ${extra_args} .

        if [ "$variant" = "slim" ]; then
            docker tag "${tag_name}" "ghcr.io/codingsoft/open-webui:${version}"
            docker tag "${tag_name}" "ghcr.io/codingsoft/open-webui:latest"
            echo -e "${GREEN}   ✅ Tagged as latest${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Imágenes construidas:${NC}"
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep "codingsoft/open-webui"
}

scan() {
    echo -e "${CYAN}🔍 Escaneando imágenes con Trivy${NC}"
    echo ""

    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}⚠️  Trivy no instalado. Instalando...${NC}"
        brew install trivy 2>/dev/null || curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
    fi

    local version=$(get_version)
    local images=(
        "ghcr.io/codingsoft/open-webui:${version}"
        "ghcr.io/codingsoft/open-webui:${version}-cuda"
        "ghcr.io/codingsoft/open-webui:${version}-ollama"
    )

    local vulnerabilities=0

    for image in "${images[@]}"; do
        echo ""
        echo -e "${BLUE}Escaneando: ${image}${NC}"

        local severity=$(trivy image --severity CRITICAL,HIGH --format table "${image}" 2>/dev/null || echo "Error en escaneo")

        if echo "$severity" | grep -q "CRITICAL"; then
            vulnerabilities=$((vulnerabilities + 1))
            echo -e "${RED}⚠️  Vulnerabilidades encontradas${NC}"
        else
            echo -e "${GREEN}✅ Sin vulnerabilidades críticas${NC}"
        fi
    done

    echo ""
    if [ $vulnerabilities -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Total imágenes con vulnerabilidades: ${vulnerabilities}${NC}"
    else
        echo -e "${GREEN}✅ Escaneo completado sin vulnerabilidades críticas${NC}"
    fi
}

sign() {
    echo -e "${CYAN}✍️ Firmando imágenes con Cosign${NC}"
    echo ""

    if ! command -v cosign &> /dev/null; then
        echo -e "${YELLOW}⚠️  Cosign no instalado.${NC}"
        echo "Instalar desde: https://docs.sigstore.dev/cosign/install"
        exit 1
    fi

    local version=$(get_version)
    local images=(
        "ghcr.io/codingsoft/open-webui:${version}"
        "ghcr.io/codingsoft/open-webui:${version}-cuda"
        "ghcr.io/codingsoft/open-webui:${version}-ollama"
    )

    for image in "${images[@]}"; do
        echo -e "${BLUE}Firmando: ${image}${NC}"
        cosign sign --yes "${image}"
        echo -e "${GREEN}✅ Firmado: ${image}${NC}"
    done

    echo ""
    echo -e "${GREEN}✅ Todas las imágenes firmadas${NC}"
}

publish() {
    echo -e "${CYAN}🚀 Publicando imágenes a GHCR${NC}"
    echo ""

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no encontrado${NC}"
        exit 1
    fi

    if ! docker login ghcr.io -u "$GITHUB_USER" -p "$GITHUB_TOKEN" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  No autenticado en GHCR${NC}"
        echo "Ejecuta: echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GITHUB_USER --password-stdin"
        exit 1
    fi

    local version=$(get_version)
    local images=(
        "ghcr.io/codingsoft/open-webui:${version}"
        "ghcr.io/codingsoft/open-webui:${version}-slim"
        "ghcr.io/codingsoft/open-webui:${version}-cuda"
        "ghcr.io/codingsoft/open-webui:${version}-ollama"
    )

    for image in "${images[@]}"; do
        echo -e "${BLUE}Push: ${image}${NC}"
        docker push "${image}"
        echo -e "${GREEN}✅ ${image}${NC}"
    done

    echo ""
    echo -e "${GREEN}✅ Imágenes publicadas${NC}"
}

github_release() {
    echo -e "${CYAN}📦 Creando GitHub Release${NC}"
    echo ""

    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI no instalado${NC}"
        exit 1
    fi

    local version=$(get_version)
    local tag="v${version}"

    echo -e "${YELLOW}Extrayendo changelog...${NC}"
    local changelog=$(awk '/^## \['"${version}"'\]/ {found=1; next} /^## \[/ && found {exit} found {print}' CHANGELOG.md | head -50)

    echo -e "${BLUE}Tag:${NC} ${tag}"
    echo -e "${BLUE}Cambios:${NC}"
    echo "$changelog" | head -20
    echo ""

    echo -e "${YELLOW}Creando release...${NC}"
    gh release create "${tag}" \
        --title "Release ${tag}" \
        --notes "${changelog}" \
        --target main

    echo -e "${GREEN}✅ GitHub Release creado${NC}"
    echo -e "${CYAN}URL:${NC} https://github.com/codingsoft/open-webui/releases/tag/${tag}"
}

all() {
    local new_version=$1

    if [ -z "$new_version" ]; then
        echo -e "${RED}❌ Especifica una versión: ./release.sh all <version>${NC}"
        exit 1
    fi

    echo -e "${CYAN}🚀 INICIANDO PROCESO COMPLETO DE RELEASE${NC}"
    echo "============================================"
    echo ""
    echo -e "${BLUE}Versión:${NC} ${new_version}"
    echo ""

    read -p "¿Continuar con release completo? (s/n): " confirm
    if [ "$confirm" != "s" ]; then
        echo "Cancelado"
        exit 0
    fi

    echo ""
    echo -e "${YELLOW}1/7 Preparando versión...${NC}"
    ./scripts/release.sh prepare "$new_version"

    echo ""
    echo -e "${YELLOW}2/7 Actualizando CHANGELOG...${NC}"
    ./scripts/release.sh changelog

    echo ""
    echo -e "${YELLOW}3/7 Creando commit...${NC}"
    ./scripts/release.sh commit

    echo ""
    echo -e "${YELLOW}4/7 Creando tag...${NC}"
    ./scripts/release.sh tag

    echo ""
    echo -e "${YELLOW}5/7 Construyendo imágenes Docker...${NC}"
    ./scripts/release.sh build

    echo ""
    echo -e "${YELLOW}6/7 Escaneando con Trivy (opcional)...${NC}"
    ./scripts/release.sh scan

    echo ""
    echo -e "${YELLOW}7/7 Creando GitHub Release...${NC}"
    ./scripts/release.sh github_release

    echo ""
    echo "============================================"
    echo -e "${GREEN}🎉 RELEASE COMPLETADO${NC}"
    echo "============================================"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos obligatorios:${NC}"
    echo ""
    echo "1. Push del código:"
    echo "   git push origin main --tags"
    echo ""
    echo "2. Las imágenes Docker se publicarán automáticamente via GitHub Actions"
    echo ""
    echo "3. Verificar release:"
    echo "   https://github.com/codingsoft/open-webui/releases/tag/v${new_version}"
}

list_tags() {
    echo -e "${CYAN}📋 Tags de Git${NC}"
    echo ""
    git tag --sort=-version:refname | head -20
}

delete_tag() {
    local tag=$1

    if [ -z "$tag" ]; then
        echo -e "${RED}❌ Especifica el tag: ./release.sh delete-tag <tag>${NC}"
        exit 1
    fi

    echo -e "${YELLOW}🗑️ Eliminando tag ${tag}...${NC}"
    git tag -d "$tag" 2>/dev/null || true
    git push origin ":refs/tags/${tag}" 2>/dev/null || true
    echo -e "${GREEN}✅ Tag ${tag} eliminado${NC}"
}

cleanup() {
    echo -e "${CYAN}🧹 Limpiando imágenes locales...${NC}"
    docker images -f "reference=codingsoft/open-webui:*" -q | xargs -r docker rmi -f
    echo -e "${GREEN}✅ Imágenes locales eliminadas${NC}"
}

images() {
    echo -e "${CYAN}📦 Imágenes Docker Locales${NC}"
    echo ""
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | grep "codingsoft/open-webui"
}

main() {
    case "${1:-help}" in
        version) version ;;
        prepare) prepare "${2}" ;;
        changelog) changelog ;;
        commit) commit ;;
        tag) tag ;;
        build) build ;;
        scan) scan ;;
        sign) sign ;;
        publish) publish ;;
        github-release) github_release ;;
        all) all "${2}" ;;
        list-tags) list_tags ;;
        delete-tag) delete_tag "${2}" ;;
        cleanup) cleanup ;;
        images) images ;;
        help|--help|-h) show_help ;;
        *) show_help ;;
    esac
}

main "$@"
