# 🔔 Webhooks - CodingSoft Open WebUI

Sistema de notificaciones automáticas para releases, builds de Docker y eventos del repositorio.

---

## 📡 Webhooks Configurados

### 1. Discord Notifications

**Events:**
- ✅ Nuevo release publicado
- ✅ Build de Docker exitoso
- ❌ Build de Docker fallido

**Configuración:**
```yaml
# .github/workflows/webhook-notifications.yml
env:
  DISCORD_WEBHOOK_ID: ${{ secrets.DISCORD_WEBHOOK_ID }}
  DISCORD_WEBHOOK_TOKEN: ${{ secrets.DISCORD_WEBHOOK_TOKEN }}
```

### 2. Generic Webhook

**Events:**
- Workflow runs completados

**Configuración:**
```yaml
env:
  GENERIC_WEBHOOK_URL: ${{ secrets.GENERIC_WEBHOOK_URL }}
```

---

## ⚙️ Configuración de Secrets

### GitHub Secrets

1. Ve a: https://github.com/CodingSoft/open-webui/settings/secrets/actions

2. Agrega los siguientes secrets:

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `DISCORD_WEBHOOK_ID` | ID del webhook de Discord | `1234567890` |
| `DISCORD_WEBHOOK_TOKEN` | Token del webhook de Discord | `abcdefghijklmnop` |
| `GENERIC_WEBHOOK_URL` | URL de webhook genérico | `https://api.example.com/webhook` |

### Obtener Webhook de Discord

1. Ve a tu servidor de Discord
2. Edit Server Settings → Integrations → Webhooks
3. Crea un nuevo webhook
4. Copia el **Webhook URL**

Ejemplo de URL:
```
https://discord.com/api/webhooks/1234567890/abcdefghijklmnopqrstuvwxyz
```

- **Webhook ID:** `1234567890`
- **Webhook Token:** `abcdefghijklmnopqrstuvwxyz`

---

## 🎨 Formato de Notificaciones

### Release Published

```
🎉 **New Release Published!**

📦 **Repository:** CodingSoft/open-webui
🏷️ **Tag:** v0.7.3
📝 **Name:** Release v0.7.3
🌐 **URL:** https://github.com/CodingSoft/open-webui/releases/tag/v0.7.3
```

### Build Success

```
✅ **Docker Build Successful!**

📦 **Repository:** CodingSoft/open-webui
🔧 **Workflow:** Docker Build & Publish to GHCR
📊 **Run:** #42
🔗 **Details:** https://github.com/CodingSoft/open-webui/actions/runs/1234567890
```

### Build Failure

```
❌ **Docker Build Failed!**

📦 **Repository:** CodingSoft/open-webui
🔧 **Workflow:** Docker Build & Publish to GHCR
📊 **Run:** #42
🔗 **Logs:** https://github.com/CodingSoft/open-webui/actions/runs/1234567890
```

---

## 🧪 Testear Webhooks

### Usando el Script

```bash
# Test con URL directa
./scripts/test-webhook.sh "https://discord.com/api/webhooks/1234567890/token"

# O con variable de entorno
export WEBHOOK_URL="https://discord.com/api/webhooks/1234567890/token"
./scripts/test-webhook.sh
```

### Usando curl

```bash
# Test básico
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"test": true}' \
  "https://discord.com/api/webhooks/1234567890/token"

# Test con formato completo
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "event": "release",
    "repository": "CodingSoft/open-webui",
    "tag": "v0.7.2",
    "url": "https://github.com/CodingSoft/open-webui/releases/tag/v0.7.2"
  }' \
  "$WEBHOOK_URL"
```

---

## 🔧 Webhooks Adicionales

### Slack

```yaml
# .github/workflows/slack-notification.yml
name: Slack Notification

on: [release_published]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send to Slack
        uses: 8398a7/action-slack@v3
        with:
          status: success
          channel: '#deployments'
          text: "🎉 New release: ${{ github.event.release.tag_name }}"
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Email (SendGrid)

```yaml
# .github/workflows/email-notification.yml
name: Email Notification

on:
  release:
    types: [published]

jobs:
  send-email:
    runs-on: ubuntu-latest
    steps:
      - name: Send email
        run: |
          curl -X POST "https://api.sendgrid.com/v3/mail/send" \
            -H "Authorization: Bearer ${{ secrets.SENDGRID_API_KEY }}" \
            -d '{
              "personalizations": [{"to": [{"email": "team@codingsoft.org"}]}],
              "from": {"email": "noreply@codingsoft.org"},
              "subject": "New Release: ${{ github.event.release.tag_name }}",
              "content": [{"type": "text/plain", "value": "Check out the new release!"}]
            }'
```

### Custom Endpoint

```bash
# Ejemplo de endpoint simple en Node.js
const express = require('express');
const app = express();

app.post('/webhook', (req, res) => {
  const { event, repository, tag, url } = req.body;
  console.log(`[${event}] ${repository}: ${tag}`);
  // Process notification...
  res.sendStatus(200);
});

app.listen(3000);
```

---

## 📊 Eventos Soportados

### GitHub Actions

| Evento | Trigger |
|--------|---------|
| `release.published` | Nuevo release |
| `workflow_run.completed` | Workflow completado |
| `push` | Nuevo push a main/dev |

### Docker Events

| Evento | Trigger |
|--------|---------|
| `docker_build.success` | Build exitoso |
| `docker_build.failure` | Build fallido |
| `docker_push.success` | Push a registry |

---

## 🔒 Seguridad

### Verificación de Webhooks

```javascript
// Ejemplo de verificación de firma (Node.js)
const crypto = require('crypto');

function verifyWebhook(req, signature) {
  const secret = process.env.WEBHOOK_SECRET;
  const hmac = crypto.createHmac('sha256', secret);
  const digest = 'sha256=' + hmac.update(JSON.stringify(req.body)).digest('hex');
  
  return signature === digest;
}
```

### GitHub Secrets

- Nunca expongas tokens en código
- Usa GitHub Secrets para configuración sensible
- Rota tokens periódicamente

---

## 📝 Configuración de example

### Archivo de configuración local

```bash
# .env (no subir a git!)
DISCORD_WEBHOOK_ID=1234567890
DISCORD_WEBHOOK_TOKEN=abcdefghijklmnop
GENERIC_WEBHOOK_URL=https://api.example.com/webhook
```

### Agregar a GitHub

```bash
# Usar GitHub CLI
gh secret set DISCORD_WEBHOOK_ID --body "1234567890"
gh secret set DISCORD_WEBHOOK_TOKEN --body "token-aqui"
gh secret set GENERIC_WEBHOOK_URL --body "https://..."
```

---

## 🔗 Enlaces

- **GitHub Actions:** https://github.com/CodingSoft/open-webui/actions
- **Discord Webhooks:** https://discord.com/developers/docs/resources/webhook
- **GitHub Secrets:** https://docs.github.com/en/actions/security-guides/encrypted-secrets

---

## 🧪 Testing

### Verificar Workflow

```bash
# Listar workflows
gh workflow list --repo CodingSoft/open-webui

# Ver runs
gh run list --repo CodingSoft/open-webui --workflow webhook-notifications

# Ver logs
gh run view <run_id> --repo CodingSoft/open-webui --log
```

### Simular Evento

```bash
# Trigger manual
gh workflow run webhook-notifications.yml --ref dev --repo CodingSoft/open-webui
```

---

## 📈 Métricas

El workflow también puede enviar métricas a:

- **Datadog:** `https://api.datadoghq.com/api/v1/series`
- **Prometheus Pushgateway:** `http://pushgateway:9091/metrics/job/github`
- **Custom:** Cualquier endpoint HTTP

```yaml
# Ejemplo de envío de métricas
- name: Send metrics
  run: |
    curl -X POST "${{ secrets.METRICS_ENDPOINT }}" \
      -d "github.release.published=1"
```

---

**Configurado:** 2026-01-30
**Versión:** 1.0.0
