# Guía de Releases - CodingSoft Open WebUI

## Tabla de Contenidos

1. [Resumen del Proceso](#resumen-del-proceso)
2. [Versionado](#versionado)
3. [Procedimiento de Release](#procedimiento-de-release)
4. [Imágenes Docker](#imágenes-docker)
5. [GitHub Releases](#github-releases)
6. [Seguridad](#seguridad)
7. [Automatización CI/CD](#automatización-cicd)
8. [Rollback](#rollback)

---

## Resumen del Proceso

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO DE RELEASE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. prepare        → Actualiza versiones en package.json        │
│  2. changelog      → Genera entrada en CHANGELOG.md              │
│  3. commit         → Crea commit de release                      │
│  4. tag            → Crea tag de git (vX.X.X)                   │
│  5. build          → Construye imágenes Docker locales          │
│  6. scan           → Escanea con Trivy (opcional)              │
│  7. sign           → Firma con Cosign (opcional)                │
│  8. github-release → Crea release en GitHub                      │
│  9. git push       → Push código + tags                         │
│                                                                 │
│  ⇨ GitHub Actions publica imágenes automáticamente             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Versionado

### Sistema de Versionado

Usamos **SemVer** (Semantic Versioning):

```
MAJOR.MINOR.PATCH
   │     │     │
   │     │     └─ Correcciones de bugs (backward compatible)
   │     └────── Nuevas funcionalidades (backward compatible)
   └───────────── Cambios incompatibles
```

### Ejemplos

| Versión         | Significado                  |
| --------------- | ---------------------------- |
| `0.7.2`         | Patch 2 de la versión 0.7    |
| `0.8.0`         | Nueva versión menor          |
| `1.0.0`         | Primera versión estable      |
| `1.2.3-clientA` | Personalizada para cliente A |

### Tags de Git

- **Release:** `v1.2.3`
- **Pre-release:** `v1.2.3-beta.1`, `v1.2.3-rc.1`

---

## Procedimiento de Release

### Método 1: Script Automatizado (Recomendado)

```bash
# Ejecutar proceso completo
./scripts/release.sh all 0.7.3

# Luego hacer push
git push origin main --tags
```

### Método 2: Paso a Paso

```bash
# 1. Preparar versión
./scripts/release.sh prepare 0.7.3

# 2. Editar CHANGELOG.md manualmente si es necesario
nano CHANGELOG.md

# 3. Crear commit
./scripts/release.sh commit

# 4. Crear tag
./scripts/release.sh tag

# 5. Construir imágenes
./scripts/release.sh build

# 6. (Opcional) Escanear vulnerabilidades
./scripts/release.sh scan

# 7. (Opcional) Firmar imágenes
./scripts/release.sh sign

# 8. Crear GitHub Release
./scripts/release.sh github-release

# 9. Push
git push origin main --tags
```

### Método 3: Manual

```bash
# Actualizar versión
sed -i 's/"version": ".*"/"version": "0.7.3"/' package.json

# Commit
git add .
git commit -m "Release v0.7.3"

# Tag
git tag -a v0.7.3 -m "Release v0.7.3"

# Push
git push origin main --tags
```

---

## Imágenes Docker

### Variantes Publicadas

| Variante   | Tag                                           | Descripción            |
| ---------- | --------------------------------------------- | ---------------------- |
| **Slim**   | `ghcr.io/codingsoft/open-webui:v0.7.3`        | Ligera, CPU only       |
| **CUDA**   | `ghcr.io/codingsoft/open-webui:v0.7.3-cuda`   | Con soporte NVIDIA GPU |
| **Ollama** | `ghcr.io/codingsoft/open-webui:v0.7.3-ollama` | Con Ollama integrado   |

### Tags Adicionales

| Tag              | Uso                           |
| ---------------- | ----------------------------- |
| `:latest`        | Última versión estable        |
| `:latest-slim`   | Latest slim variant           |
| `:latest-cuda`   | Latest CUDA variant           |
| `:latest-ollama` | Latest Ollama variant         |
| `:sha-abc1234`   | Versión específica por commit |

### Construcción Local

```bash
# Slim
docker build -t ghcr.io/codingsoft/open-webui:v0.7.3 \
  --build-arg USE_SLIM=true .

# CUDA
docker build -t ghcr.io/codingsoft/open-webui:v0.7.3-cuda \
  --build-arg USE_CUDA=true \
  --build-arg USE_CUDA_VER=cu128 .

# Ollama
docker build -t ghcr.io/codingsoft/open-webui:v0.7.3-ollama \
  --build-arg USE_OLLAMA=true .
```

### Publicación Manual

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin

# Push
docker push ghcr.io/codingsoft/open-webui:v0.7.3
docker push ghcr.io/codingsoft/open-webui:v0.7.3-slim
docker push ghcr.io/codingsoft/open-webui:v0.7.3-cuda
docker push ghcr.io/codingsoft/open-webui:v0.7.3-ollama
```

---

## GitHub Releases

### Creación Automática

El workflow `build-release.yml` crea releases automáticamente cuando:

- Se hace push de un tag `v*`

### Contenido del Release

- **Título:** Release v0.7.3
- **Descripción:** CHANGELOG.md (entrada más reciente)
- **Assets:** Código fuente (ZIP/TAR)

### Release Notes Incluidos

```markdown
## 🐳 Docker Images Published

Available images:

- `ghcr.io/codingsoft/open-webui:v0.7.3` (slim)
- `ghcr.io/codingsoft/open-webui:v0.7.3-cuda` (CUDA)
- `ghcr.io/codingsoft/open-webui:v0.7.3-ollama` (Ollama)

Pull command:
docker pull ghcr.io/codingsoft/open-webui:v0.7.3
```

---

## Seguridad

### Escaneo de Vulnerabilidades

Usamos **Trivy** para escanear imágenes:

```bash
./scripts/release.sh scan
```

**Criterios:**

- CRITICAL → Bloquea release
- HIGH → Requiere revisión

### Firmado de Imágenes

Usamos **Cosign** para firmar:

```bash
./scripts/release.sh sign
```

**Verificación:**

```bash
cosign verify ghcr.io/codingsoft/open-webui:v0.7.3
```

### Análisis de Código

**Frontend (ESLint):**

```bash
npm run lint:frontend
```

**Backend (Pylint):**

```bash
npm run lint:backend
```

**Types (TypeScript):**

```bash
npm run lint:types
```

---

## Automatización CI/CD

### GitHub Actions Workflows

| Workflow                      | Trigger         | Descripción              |
| ----------------------------- | --------------- | ------------------------ |
| `build-release.yml`           | Push tag `v*`   | Crea GitHub Release      |
| `docker-publish-ghcr.yml`     | Push tag `v*`   | Publica imágenes a GHCR  |
| `docker-build-codingsoft.yml` | Push a main/dev | Build y scan de imágenes |

### Flujo de CI/CD

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Commit    │ ──▶ │  Push PR    │ ──▶ │  Lint/Test  │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Deploy    │ ◀── │   Review   │ ◀── │   Build     │
│  Producción │     │             │     │   Docker    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                              ┌────────────────┴────────────────┐
                              ▼                                 ▼
                      ┌─────────────┐                   ┌─────────────┐
                      │   Push Tag  │                   │  Trivy Scan │
                      │   v*        │                   │             │
                      └──────┬──────┘                   └──────┬──────┘
                             │                                 │
                             ▼                                 ▼
                      ┌─────────────┐                   ┌─────────────┐
                      │  GitHub     │                   │   Cosign    │
                      │  Release    │                   │   Sign      │
                      └─────────────┘                   └─────────────┘
```

### Configuración de Secrets

En GitHub → Settings → Secrets:

| Secret               | Descripción          |
| -------------------- | -------------------- |
| `GITHUB_TOKEN`       | Auto-generado        |
| `COSIGN_PRIVATE_KEY` | Para firmar imágenes |

---

## Rollback

### Rollback de Código

```bash
# Ver commits recientes
git log --oneline -10

# Revertir a commit anterior
git revert <commit-hash>

# O resetear (cuidado)
git reset --hard <commit-hash>
git push --force
```

### Rollback de Tag

```bash
# Eliminar tag remoto
git push origin :refs/tags/v0.7.3

# Recrear tag
git tag -a v0.7.3 <commit-hash> -m "Release v0.7.3"
git push origin v0.7.3
```

### Rollback de Docker Images

```bash
# Ver versiones anteriores
docker pull ghcr.io/codingsoft/open-webui:v0.7.2

# Re-etiquetar como latest
docker tag ghcr.io/codingsoft/open-webui:v0.7.2 ghcr.io/codingsoft/open-webui:latest
docker push ghcr.io/codingsoft/open-webui:latest
```

### Rollback de GitHub Release

1. Ir a Releases → Editar release
2. Eliminar release (no elimina el tag)
3. Recrear si es necesario

---

## Checklist de Release

### Antes del Release

- [ ] Tests pasan localmente
- [ ] Linting sin errores
- [ ] CHANGELOG.md actualizado
- [ ] No hay secretos en el código
- [ ] Documentación actualizada

### Durante el Release

- [ ] Versión actualizada en package.json
- [ ] Tag creado correctamente
- [ ] Imágenes construidas sin errores
- [ ] Trivy scan sin vulnerabilidades críticas
- [ ] GitHub Release creado

### Después del Release

- [ ] CI/CD workflows completados
- [ ] Imágenes publicadas en GHCR
- [ ] Release verificado en GitHub
- [ ] Notificación a stakeholders
- [ ] Documentación de cambios distribuidos

---

## Comandos Rápidos

| Acción           | Comando                          |
| ---------------- | -------------------------------- |
| Ver versión      | `./scripts/release.sh version`   |
| Listar tags      | `./scripts/release.sh list-tags` |
| Release completo | `./scripts/release.sh all 0.7.3` |
| Solo build       | `./scripts/release.sh build`     |
| Solo scan        | `./scripts/release.sh scan`      |
| Limpiar imágenes | `./scripts/release.sh cleanup`   |

---

## Soporte

- **Issues:** https://github.com/codingsoft/open-webui/issues
- **Documentación:** https://docs.webui.codingsoft.org
- **Discord:** https://discord.gg/codingsoft
