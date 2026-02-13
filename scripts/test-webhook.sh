#!/bin/bash
# test-webhook.sh - Test webhook notifications

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

WEBHOOK_URL="${1:-${WEBHOOK_URL}}"

if [ -z "$WEBHOOK_URL" ]; then
    echo -e "${RED}❌ Error: Se requiere URL de webhook${NC}"
    echo ""
    echo "Uso: ./test-webhook.sh <webhook_url>"
    echo ""
    echo "Ejemplo:"
    echo "  ./test-webhook.sh https://discord.com/api/webhooks/1234567890/abcdefg"
    echo ""
    echo "O configura la variable de entorno:"
    echo "  export WEBHOOK_URL='https://...'
    echo "  ./test-webhook.sh"
    exit 1
fi

echo -e "${CYAN}🧪 Testeando webhook...${NC}"
echo ""

# Datos de prueba
PAYLOAD='{
  "event": "test",
  "repository": "CodingSoft/open-webui",
  "message": "Test notification from CodingSoft Open WebUI",
  "timestamp": "'"$(date -Iseconds)"'",
  "status": "success"
}'

echo -e "${YELLOW}Enviando payload:${NC}"
echo "$PAYLOAD" | jq .
echo ""

# Enviar webhook
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$WEBHOOK_URL")

echo -e "${CYAN}Respuesta del servidor:${NC} HTTP $RESPONSE"
echo ""

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 204 ]; then
    echo -e "${GREEN}✅ Webhook enviado exitosamente!${NC}"
    exit 0
else
    echo -e "${RED}❌ Error al enviar webhook (HTTP $RESPONSE)${NC}"
    echo ""
    echo "Posibles causas:"
    echo "  - URL incorrecta"
    echo "  - Webhook no válido"
    echo "  - Servidor no disponible"
    exit 1
fi
