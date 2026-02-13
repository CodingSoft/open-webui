#!/bin/bash
# Script para configurar GitHub Container Registry (GHCR)
# Ejecutar como administrador de la organización CodingSoft

set -e

echo "🔧 Configurando GitHub Container Registry para CodingSoft/open-webui"
echo ""

# Verificar que Docker esté disponible
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

# Solicitar token
echo "📝 Para crear el token, ve a: https://github.com/settings/tokens/new"
echo "   Selecciona estos scopes:"
echo "   ✅ repo"
echo "   ✅ write:packages"
echo "   ✅ read:packages"
echo "   ✅ delete:packages (opcional)"
echo ""
read -sp "🔑 Ingresa tu GitHub Personal Access Token: " GITHUB_TOKEN
echo ""
echo ""

# Login en GHCR
echo "🔐 Iniciando sesión en GHCR..."
echo $GITHUB_TOKEN | docker login ghcr.io -u codingsoft --password-stdin

# Crear imagen inicial
echo ""
echo "📦 Creando paquete inicial..."
docker pull alpine:latest
docker tag alpine:latest ghcr.io/codingsoft/open-webui:init
docker push ghcr.io/codingsoft/open-webui:init

# Limpiar
docker rmi ghcr.io/codingsoft/open-webui:init

echo ""
echo "✅ Paquete inicial creado exitosamente"
echo ""
echo "⚙️  PASO IMPORTANTE - Configurar permisos:"
echo "   1. Ve a: https://github.com/orgs/CodingSoft/packages/container/open-webui/settings"
echo "   2. En 'Manage Actions access' haz clic en 'Add repository'"
echo "   3. Selecciona: CodingSoft/open-webui"
echo "   4. Rol: Write (para que los workflows puedan pushear)"
echo "   5. Guarda los cambios"
echo ""
echo "🚀 Después de configurar los permisos, el workflow debería funcionar"
echo ""
echo "📝 Para verificar, ejecuta en tu terminal local:"
echo "   gh run list --repo CodingSoft/open-webui --workflow=docker-build-codingsoft.yml"
