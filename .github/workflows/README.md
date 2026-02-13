# Documentación de Workflows de GitHub Actions

## Resumen Ejecutivo

Este repositorio contiene **7 workflows activos** y **5 workflows deshabilitados**. Los workflows están diseñados para automatizar el proceso de CI/CD del proyecto Open WebUI.

## Workflows Activos (7)

### 1. `docker-build-codingsoft.yml` ⭐ PRINCIPAL

**Propósito:** Construir y publicar imágenes Docker en GitHub Container Registry (GHCR)

**¿Cuándo se ejecuta?**

- Push a `main` o `dev`
- Tags que empiezan con `v*` (ej: v1.2.3)
- Pull requests a `main` o `dev`

**¿Qué hace?**

```yaml
Construye 3 variantes de imagen Docker:
├─ slim (estándar)
├─ cuda (con soporte GPU NVIDIA)
└─ ollama (con Ollama integrado)

Pasos para cada variante:
1. Checkout del código
2. Configurar Docker Buildx
3. Extraer metadatos (tags, labels)
4. Login en GHCR
5. Build de la imagen
6. Push a ghcr.io/codingsoft/open-webui
7. Escaneo de vulnerabilidades (Trivy)
8. Attest de seguridad
9. Comentario en PR (si aplica)
10. Crear manifest multi-arquitectura
```

**Permisos requeridos:**

- `contents: read`
- `packages: write`
- `attestations: write`
- `id-token: write`

**¿Es necesario?** ✅ **SÍ** - Es el pipeline Docker principal

---

### 2. `build-release.yml`

**Propósito:** Crear releases versionados en GitHub automáticamente

**¿Cuándo se ejecuta?**

- Push a `main` (solo si hay cambios en `package.json`)

**¿Qué hace?**

```yaml
1. Verifica cambios en package.json
2. Extrae número de versión de package.json
3. Extrae notas del CHANGELOG.md
4. Crea un release en GitHub
5. Sube el código como artifact
6. Dispara docker-build-codingsoft.yml
```

**Flujo de trabajo:**

```
Push a main + cambio en package.json
    ↓
build-release.yml corre
    ↓
Crea release vX.X.X
    ↓
Dispara docker-build-codingsoft.yml
    ↓
Imagen Docker taggeada con vX.X.X
```

**¿Es necesario?** ✅ **SÍ** - Si quieres automatizar releases versionados

---

### 3. `format-build-frontend.yaml`

**Propósito:** Validar y formatear código frontend (Svelte/TypeScript)

**¿Cuándo se ejecuta?**

- Push a `main` o `dev` (ignora cambios en backend/)
- Pull requests a `main` o `dev` (ignora cambios en backend/)

**Jobs:**

#### Job: build

```yaml
1. Checkout del código
2. Setup Node.js 22
3. npm install --force
4. npm run format (formatea código)
5. npm run i18n:parse (actualiza traducciones)
6. Verifica cambios sin commitear (git diff --exit-code)
7. npm run build (construye producción)
```

#### Job: test-frontend

```yaml
1. Checkout del código
2. Setup Node.js 22
3. npm ci --force
4. npm run test:frontend (ejecuta vitest)
```

**¿Es necesario?** ✅ **SÍ** - Garantiza calidad de código frontend

---

### 4. `format-backend.yaml`

**Propósito:** Validar y formatear código backend (Python)

**¿Cuándo se ejecuta?**

- Push a `main` o `dev` (solo cambios en backend/)
- Pull requests a `main` o `dev` (solo cambios en backend/)

**¿Qué hace?**

```yaml
Matrix de Python:
├─ Python 3.11.x
└─ Python 3.12.x

Pasos:
1. Checkout del código
2. Setup Python ${{ matrix.python-version }}
3. Instala dependencias (pip, black)
4. npm run format:backend (formatea Python)
5. Verifica cambios sin commitear (git diff --exit-code)
```

**¿Es necesario?** ✅ **SÍ** - Mantiene consistencia en código Python

---

### 5. `release-pypi.yml` ⚠️ OPCIONAL

**Propósito:** Publicar el paquete en PyPI

**¿Cuándo se ejecuta?**

- Push a `main`
- Push a `pypi-release`

**¿Qué hace?**

```yaml
1. Checkout del código (fetch-depth: 0)
2. Instala Git
3. Setup Node.js 22
4. Setup Python 3.11
5. Instala build
6. python -m build . (construye paquete)
7. Publica en PyPI usando trusted publishing
```

**Permisos requeridos:**

- `id-token: write` (para trusted publishing)

**Environment:** pypi

**¿Es necesario?** ⚠️ **OPCIONAL** - Solo si quieres distribuir como paquete pip

**Configuración adicional:**

- Debes configurar "Trusted Publishing" en PyPI
- URL: https://pypi.org/p/open-webui

---

### 6. `deploy-to-hf-spaces.yml` ⚠️ OPCIONAL

**Propósito:** Desplegar demo en HuggingFace Spaces

**¿Cuándo se ejecuta?**

- Push a `dev` o `main`
- Manual (workflow_dispatch)

**¿Qué hace?**

```yaml
1. Verifica que HF_TOKEN esté configurado
2. Checkout con LFS
3. Elimina historial git
4. Agrega frontmatter YAML al README
5. Configura git
6. Inicializa nuevo repo
7. Configura Git LFS (para archivos grandes)
8. Elimina archivos demo/banner
9. Commite cambios
10. Push force a HuggingFace Spaces
```

**Secrets requeridos:**

- `HF_TOKEN` (token de HuggingFace)

**¿Es necesario?** ⚠️ **OPCIONAL** - Solo si quieres demo público en HuggingFace

**URL de destino:** https://huggingface.co/spaces/open-webui/open-webui

---

### 7. `webhook-notifications.yml` ⚠️ OPCIONAL

**Propósito:** Enviar notificaciones a Discord

**¿Cuándo se ejecuta?**

- Cuando se publica un release
- Cuando terminan los workflows Docker (éxito o fallo)

**Jobs:**

#### notify-release

Notifica cuando se publica un nuevo release

#### notify-build-success

Notifica éxito en build Docker (color verde)

#### notify-build-failure

Notifica fallo en build Docker (color rojo)

#### generic-webhook

Envía webhook genérico con información del workflow

**Secrets requeridos:**

- `DISCORD_WEBHOOK_ID`
- `DISCORD_WEBHOOK_TOKEN`
- `GENERIC_WEBHOOK_URL`

**¿Es necesario?** ⚠️ **OPCIONAL** - Solo si usas Discord para notificaciones

---

## Workflows Deshabilitados (5)

Los siguientes workflows han sido renombrados con extensión `.disabled` para que no se ejecuten:

| Archivo                            | Razón                                                       |
| ---------------------------------- | ----------------------------------------------------------- |
| `docker-publish-ghcr.yml.disabled` | Duplicado de `docker-build-codingsoft.yml`                  |
| `codespell.disabled`               | Chequeo de ortografía (no crítico)                          |
| `integration-test.disabled`        | Tests de integración (demorados)                            |
| `lint-backend.disabled`            | Linting de backend (reemplazado por format-backend)         |
| `lint-frontend.disabled`           | Linting de frontend (reemplazado por format-build-frontend) |

---

## Diagrama de Dependencias

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUJO DE TRABAJO                          │
└─────────────────────────────────────────────────────────────────┘

1. DESARROLLO (Push a dev)
   ↓
   ├─► format-build-frontend.yaml ━━┓
   ├─► format-backend.yaml ━━━━━━━━┫
   └─► docker-build-codingsoft.yml ━┛ (build sin push en PR)

2. PULL REQUEST (PR a main)
   ↓
   ├─► format-build-frontend.yaml ━━┓
   ├─► format-backend.yaml ━━━━━━━━┫ Validación
   └─► docker-build-codingsoft.yml ━┛ (build sin push)

3. RELEASE (Push a main + cambio package.json)
   ↓
   ├─► build-release.yml ━━━━━━━━┓
   │   └─► Crea release vX.X.X  ┃
   │   └─► Dispara Docker build ┃
   │                             ┃
   ├─► docker-build-codingsoft.yml (taggea con vX.X.X)
   │                             ┃
   ├─► release-pypi.yml (opcional)    ┃
   ├─► deploy-to-hf-spaces.yml (opcional)┃
   │                             ┃
   └─► webhook-notifications.yml ━━━━━━━━┛ (notifica resultados)
```

---

## Secrets Necesarios

### Automáticos (no requieren configuración)

| Secret         | Uso                                                 |
| -------------- | --------------------------------------------------- |
| `GITHUB_TOKEN` | Todos los workflows (proporcionado automáticamente) |

### Manuales (requieren configuración en Settings > Secrets)

| Secret                  | Workflow              | Descripción                  |
| ----------------------- | --------------------- | ---------------------------- |
| `HF_TOKEN`              | deploy-to-hf-spaces   | Token de HuggingFace         |
| `DISCORD_WEBHOOK_ID`    | webhook-notifications | ID del webhook Discord       |
| `DISCORD_WEBHOOK_TOKEN` | webhook-notifications | Token del webhook Discord    |
| `GENERIC_WEBHOOK_URL`   | webhook-notifications | URL de webhook personalizado |

---

## Matriz de Necesidad

| Workflow                    | Prioridad  | ¿Esencial? | Razón                      |
| --------------------------- | ---------- | ---------- | -------------------------- |
| docker-build-codingsoft.yml | ⭐⭐⭐⭐⭐ | SÍ         | Pipeline Docker principal  |
| format-build-frontend.yaml  | ⭐⭐⭐⭐   | SÍ         | Calidad de código frontend |
| format-backend.yaml         | ⭐⭐⭐⭐   | SÍ         | Calidad de código backend  |
| build-release.yml           | ⭐⭐⭐     | SÍ         | Automatización de releases |
| release-pypi.yml            | ⭐⭐       | OPCIONAL   | Distribución PyPI          |
| deploy-to-hf-spaces.yml     | ⭐⭐       | OPCIONAL   | Demo público               |
| webhook-notifications.yml   | ⭐         | OPCIONAL   | Notificaciones Discord     |

---

## Configuración Mínima Recomendada

Para un funcionamiento óptimo, mantén activos:

1. ✅ `docker-build-codingsoft.yml`
2. ✅ `format-build-frontend.yaml`
3. ✅ `format-backend.yaml`
4. ✅ `build-release.yml`

Los demás son opcionales según tus necesidades.

---

## Troubleshooting

### Error 403 Forbidden en Docker

**Causa:** Dos workflows intentando publicar la misma imagen simultáneamente
**Solución:** Asegúrate de tener solo un workflow de Docker activo (usamos `docker-build-codingsoft.yml`)

### Workflows no se ejecutan

**Causa posible:** Rama incorrecta o paths ignorados
**Verificar:**

- Los workflows de frontend solo corren si NO hay cambios en backend/
- Los workflows de backend solo corren si hay cambios en backend/

### Fallo en release-pypi.yml

**Causa:** Trusted publishing no configurado
**Solución:** Configurar en https://pypi.org/manage/account/publishing/

---

## Historial de Cambios

- **2026-02-06**: Eliminado `docker-publish-ghcr.yml` (duplicado)
- **2026-02-06**: Actualizadas versiones de actions a v5/v6
- **2026-02-05**: Corregidos nombres duplicados de workflows
- **2026-02-05**: Deshabilitado workflow upstream conflictivo

---

## Notas Adicionales

- Todos los workflows usan `ubuntu-latest` como runner
- El formateo falla si hay cambios sin commitear después del format
- Los workflows de Docker usan caché (gha) para acelerar builds
- Las imágenes se publican en: `ghcr.io/codingsoft/open-webui`

---

**Última actualización:** 6 de Febrero, 2026
**Mantenido por:** CodingSoft
