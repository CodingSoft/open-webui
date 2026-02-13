# 🐳 Docker Images Guide - CodingSoft Open WebUI

## 📦 Imágenes Disponibles

Todas las imágenes se publican automáticamente en **GitHub Container Registry** (GHCR).

```
ghcr.io/codingsoft/open-webui
```

### Tags Disponibles

| Tag             | Descripción                   | Tamaño |
| --------------- | ----------------------------- | ------ |
| `latest`        | Última versión estable (slim) | ~500MB |
| `v0.7.2`        | Versión específica            | ~500MB |
| `v0.7.2-slim`   | Versión específica slim       | ~500MB |
| `v0.7.2-cuda`   | Con soporte GPU NVIDIA        | ~2GB   |
| `v0.7.2-ollama` | Con Ollama integrado          | ~3GB   |
| `latest-cuda`   | Latest con CUDA               | ~2GB   |
| `latest-ollama` | Latest con Ollama             | ~3GB   |

---

## 🚀 Uso Rápido

### Imagen Estándar (Slim)

```bash
# Pull
docker pull ghcr.io/codingsoft/open-webui:latest

# Run
docker run -d \
  -p 3000:8080 \
  -v open-webui-data:/app/backend/data \
  --name open-webui \
  ghcr.io/codingsoft/open-webui:latest
```

Acceso: http://localhost:3000

### Con CUDA (GPU NVIDIA)

```bash
# Pull
docker pull ghcr.io/codingsoft/open-webui:latest-cuda

# Run con GPU
docker run -d \
  --gpus all \
  -p 3000:8080 \
  -v open-webui-data:/app/backend/data \
  --name open-webui-cuda \
  ghcr.io/codingsoft/open-webui:latest-cuda
```

### Con Ollama Integrado

```bash
# Pull
docker pull ghcr.io/codingsoft/open-webui:latest-ollama

# Run con Ollama
docker run -d \
  -p 3000:8080 \
  -p 11434:11434 \
  -v open-webui-data:/app/backend/data \
  -v ollama-data:/root/.ollama \
  --name open-webui-ollama \
  ghcr.io/codingsoft/open-webui:latest-ollama
```

Acceso:

- WebUI: http://localhost:3000
- Ollama API: http://localhost:11434

---

## 🐳 Docker Compose

### Estándar

```yaml
# docker-compose.yml
version: '3.8'

services:
  webui:
    image: ghcr.io/codingsoft/open-webui:latest
    container_name: codingsoft-webui
    ports:
      - '3000:8080'
    volumes:
      - webui-data:/app/backend/data
    restart: unless-stopped

volumes:
  webui-data:
```

```bash
docker-compose up -d
```

### Con Ollama

```yaml
# docker-compose.yml
version: '3.8'

services:
  webui:
    image: ghcr.io/codingsoft/open-webui:latest-ollama
    container_name: codingsoft-webui
    ports:
      - '3000:8080'
      - '11434:11434'
    volumes:
      - webui-data:/app/backend/data
      - ollama-data:/root/.ollama
    environment:
      - OLLAMA_BASE_URL=http://localhost:11434
    restart: unless-stopped

volumes:
  webui-data:
  ollama-data:
```

```bash
docker-compose -f docker-compose.yml up -d
```

---

## 🔧 Configuración Avanzada

### Variables de Entorno

```bash
docker run -d \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://ollama:11434 \
  -e OPENAI_API_KEY=your-key-here \
  -e WEBUI_SECRET_KEY=your-secret-key \
  -v open-webui-data:/app/backend/data \
  --name open-webui \
  ghcr.io/codingsoft/open-webui:latest
```

### Configuración Completa

```yaml
# docker-compose.advanced.yml
version: '3.8'

services:
  webui:
    image: ghcr.io/codingsoft/open-webui:latest
    container_name: codingsoft-webui
    ports:
      - '3000:8080'
    volumes:
      - ./branding:/app/backend/static/branding
      - webui-data:/app/backend/data
    environment:
      - WEBUI_NAME=CodingSoft WebUI
      - WEBUI_SECRET_KEY=${{ secrets.WEBUI_SECRET_KEY }}
      - OLLAMA_BASE_URL=http://ollama:11434
      - OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }}
      - DEFAULT_MODELS=llama3.2:latest
      - ENABLE_LOG=true
    restart: unless-stopped
    depends_on:
      - ollama

  ollama:
    image: ollama/ollama:latest
    container_name: codingsoft-ollama
    volumes:
      - ollama-data:/root/.ollama
    restart: unless-stopped

volumes:
  webui-data:
  ollama-data:
```

---

## 🔐 Autenticación en GHCR

### Docker Login

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

### GitHub Actions

El workflow CI/CD usa `GITHUB_TOKEN` automáticamente.

---

## 📊 Multi-Platform Builds

Las imágenes se buildan para:

- `linux/amd64` (x86_64)
- `linux/arm64` (Apple Silicon, AWS Graviton)

---

## 🔒 Seguridad

### Escaneo de Vulnerabilidades

Cada imagen se escanea con Trivy antes de publicar.

### Firmado de Imágenes

Las imágenes incluyen attestations de procedencia.

```bash
# Verificar procedencia
cosign verify ghcr.io/codingsoft/open-webui:latest
```

---

## 📈 Optimización

### Build Local con Cache

```bash
# Habilitar cache de BuildKit
export DOCKER_BUILDKIT=1

# Build con cache
docker build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t ghcr.io/codingsoft/open-webui:dev \
  .
```

---

## 🧪 Testing

### Test Local

```bash
# Build imagen
docker build -t test-webui .

# Run tests
docker run --rm test-webui /bin/bash -c "cd /app && pytest"
```

---

## 📝 Notas

- Las imágenes se publican automáticamente con cada release
- Las etiquetas `latest` se actualizan con cada push a `main`
- Versiones anteriores se mantienen para rollback
- Scanning crítico aplica a releases (tags `v*`)

---

## 🔗 Enlaces

- **Registry:** https://github.com/orgs/codingsoft/packages?repo_name=open-webui
- **Workflow:** https://github.com/CodingSoft/open-webui/actions/workflows/docker-publish-ghcr.yml
- **Issues:** https://github.com/CodingSoft/open-webui/issues
