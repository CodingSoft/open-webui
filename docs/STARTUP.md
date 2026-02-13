# Guía de Inicio - CodingSoft Open WebUI

## Métodos de Instalación y Desarrollo

Este documento describe todos los métodos disponibles para ejecutar el proyecto.

---

## Métodos de Desarrollo

### 1. Desarrollo Local (Rápido)

**Uso recomendado para:** Desarrollo diario, iteración rápida.

```bash
# Opción 1: Script maestro (menú interactivo)
./dev.sh

# Opción 2: Script directo
./dev:local.sh
```

**Qué inicia:**

- Frontend: http://localhost:5173 (Vite + Svelte)
- Backend: http://localhost:7860 (FastAPI + Uvicorn)
- Ollama: http://localhost:11434 (Docker)

**Requisitos:**

- Node.js 18+
- Python 3.11+
- Docker (para Ollama)

**Ventajas:**

- ⚡快速 (Fast startup)
- Hot reload en ambos frontend y backend
- Depuración directa

---

### 2. Desarrollo con Docker

**Uso recomendado:** Entorno aislado, similar a producción.

```bash
./dev.sh docker
# o directamente
./dev:docker.sh
```

**Qué inicia:**

- Contenedor Open WebUI: http://localhost:3000
- Ollama: http://localhost:11434

**Requisitos:**

- Docker
- Docker Compose

**Ventajas:**

- Entorno aislado
- Like-producción
- Sin dependencias locales de Python

---

### 3. Solo Backend

```bash
./dev.sh backend
# o
./dev:local.sh backend
```

**Puerto:** 7860

---

### 4. Solo Frontend

```bash
./dev.sh frontend
# o
./dev:local.sh frontend
```

**Puerto:** 5173

---

## Producción

### Deployment Producción

```bash
./scripts/deploy-prod.sh [comando]
```

**Comandos disponibles:**

| Comando                                      | Descripción                      |
| -------------------------------------------- | -------------------------------- |
| `./scripts/deploy-prod.sh install`           | Instalar y configurar producción |
| `./scripts/deploy-prod.sh start`             | Iniciar servicios                |
| `./scripts/deploy-prod.sh stop`              | Detener servicios                |
| `./scripts/deploy-prod.sh restart`           | Reiniciar servicios              |
| `./scripts/deploy-prod.sh status`            | Ver estado de servicios          |
| `./scripts/deploy-prod.sh logs`              | Ver logs                         |
| `./scripts/deploy-prod.sh update`            | Actualizar imágenes              |
| `./scripts/deploy-prod.sh backup`            | Crear backup                     |
| `./scripts/deploy-prod.sh restore <archivo>` | Restaurar backup                 |
| `./scripts/deploy-prod.sh cleanup`           | Limpiar recursos no utilizados   |

**Servicios iniciados:**

- WebUI: http://localhost:3000
- Redis: Cache y sesiones
- Ollama: http://localhost:11435
- Nginx: Reverse proxy (puerto 8080)

---

## Comparación de Métodos

| Característica | Local       | Docker    | Producción |
| -------------- | ----------- | --------- | ---------- |
| Frontend       | 5173        | 3000      | 3000       |
| Backend        | 7860        | Integrado | Integrado  |
| Ollama         | 11434       | 11434     | 11435      |
| Hot Reload     | ✅          | ❌        | ❌         |
| Aislamiento    | ❌          | ✅        | ✅         |
| Like-prod      | ❌          | ✅        | ✅         |
| Setup mínimo   | Node+Python | Docker    | Docker     |

---

## Docker Compose Archivos

| Archivo                     | Uso                    |
| --------------------------- | ---------------------- |
| `docker-compose.yaml`       | Desarrollo             |
| `docker-compose.prod.yml`   | Producción             |
| `docker-compose.gpu.yml`    | Producción con GPU     |
| `docker-compose.amdgpu.yml` | Producción con AMD GPU |

---

## Configuración de Producción

### 1. Crear archivo .env

```bash
cp .env.example .env
```

### 2. Configurar variables esenciales

```bash
# Security
WEBUI_SECRET_KEY=<tu-clave-secreta>
JWT_SECRET_KEY=<tu-jwt-secret>

# Ollama (opcional)
OLLAMA_BASE_URL=http://ollama:11434

# OpenAI (opcional)
OPENAI_API_KEY=<tu-api-key>
```

### 3. Iniciar producción

```bash
./scripts/deploy-prod.sh install
./scripts/deploy-prod.sh start
```

---

## Tips

### Verificar estado

```bash
# Desarrollo
./dev.sh status

# Producción
./scripts/deploy-prod.sh status
```

### Ver logs

```bash
# Desarrollo
./dev.sh logs

# Producción
./scripts/deploy-prod.sh logs
```

### Detener servicios

```bash
# Desarrollo
./dev.sh stop

# Producción
./scripts/deploy-prod.sh stop
```

---

## Requisitos Mínimos

### Desarrollo Local

- Node.js 18+
- Python 3.11+
- 4GB RAM
- Docker (recomendado para Ollama)

### Producción

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM (8GB recomendado)
- 10GB almacenamiento

---

## Solución de Problemas

### Puerto ocupado

```bash
# Ver qué usa el puerto
lsof -i:5173

# Matar proceso
fuser -k 5173/tcp
```

### Limpiar todo y empezar de nuevo

```bash
# Desarrollo
./dev:local.sh stop
rm -rf node_modules backend/venv

# Producción
./scripts/deploy-prod.sh down
docker system prune -af
```
