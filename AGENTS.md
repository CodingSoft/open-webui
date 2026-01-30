# Directrices para Agentes de Open WebUI

Este documento proporciona directrices para herramientas de codificación agentivas (como opencode) que trabajan en la base de código de Open WebUI.

**Repositorio:** https://github.com/codingsoft/open-webui

## Organización

**CodingSoft** es la organización responsable de este fork y mantenimiento del proyecto Open WebUI. La organización se enfoca en:

- Mantenimiento continuo y mejoras del código base
- Implementación de características personalizadas para clientes empresariales
- Soporte extendido y servicios profesionales
- Desarrollo de soluciones basadas en Open WebUI para casos de uso específicos

Para más información sobre los servicios y soluciones de CodingSoft, visita [https://codingsoft.org](https://codingsoft.org)

## Personalización de Enlaces y Recursos

### Documentación
- **URL de documentación principal:** Actualizar todas las referencias de documentación a usar dominios y rutas específicas de CodingSoft
- **Enlaces de ayuda:** Reemplazar enlaces genéricos de soporte con URLs de CodingSoft (ej: `https://docs.codingsoft.org/open-webui`)
- **URL de aplicación principal:** Usar `https://webui.codingsoft.org` como URL principal de la aplicación

### Imágenes Docker
- **Registro de contenedores:** Usar el registro de CodingSoft para imágenes Docker:
  - `ghcr.io/codingsoft/open-webui:main` (imagen principal)
  - `ghcr.io/codingsoft/open-webui:cuda` (con soporte CUDA)
  - `ghcr.io/codingsoft/open-webui:ollama` (con Ollama integrado)
  - `ghcr.io/codingsoft/open-webui:dev` (versión de desarrollo)

### Configuración de Contenedores
- **Variables de entorno personalizadas:**
  ```bash
  # Ejemplo de configuración para cliente empresarial
  docker run -d -p 3000:8080 \
    -e BRAND_NAME="EmpresaCliente" \
    -e BRAND_LOGO="/path/to/logo.png" \
    -e PRIMARY_COLOR="#ff5733" \
    -e SUPPORT_URL="https://soporte.empresacliente.com" \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/codingsoft/open-webui:main
  ```

### Paquetes y Dependencias
- **Repositorio de paquetes privado:** Configurar acceso a paquetes privados de CodingSoft cuando sea necesario
- **Versiones personalizadas:** Usar versiones específicas de paquetes mantenidas por CodingSoft

### Personalización de API
- **Endpoints personalizados:** Añadir rutas de API específicas para clientes:
  ```python
  # Ejemplo en FastAPI
  @app.get("/api/v1/empresa/clientes")
  async def get_clientes_empresa():
      # Lógica personalizada para cliente
      pass
  ```

### Configuración de Branding en Código
- **Variables de entorno para branding:**
  ```javascript
  // En archivos de configuración frontend
  const brandConfig = {
    appName: import.meta.env.VITE_BRAND_NAME || 'Open WebUI',
    logoPath: import.meta.env.VITE_BRAND_LOGO || '/logo.png',
    primaryColor: import.meta.env.VITE_PRIMARY_COLOR || '#3b82f6',
    supportUrl: import.meta.env.VITE_SUPPORT_URL || 'https://docs.codingsoft.org'
  };
  ```

### Personalización de Mensajes y Textos
- **Sobrescritura de traducciones:** Crear archivos de traducción específicos para clientes en `src/lib/i18n/locales/`
- **Mensajes personalizados:** Añadir claves específicas de cliente en archivos JSON de traducción

### Configuración de Telemetría
- **Endpoints de telemetría personalizados:**
  ```python
  # Configuración de telemetría para cliente
  TELEMETRY_ENDPOINT = "https://telemetria.codingsoft.com/api/v1/events"
  CLIENT_ID = "empresa-cliente-123"
  ```

### Consideraciones para Personalización
1. **Mantenimiento de compatibilidad:** Asegurar que personalizaciones no rompan actualizaciones futuras
2. **Documentación:** Mantener documentación actualizada de todas las personalizaciones
3. **Pruebas:** Crear pruebas específicas para funcionalidades personalizadas
4. **Seguridad:** Revisar permisos y acceso para características personalizadas
5. **Rendimiento:** Validar que personalizaciones no impacten negativamente el rendimiento

## Configuración de Entornos de Desarrollo Personalizados

### Configuración Básica para Clientes Empresariales

**Estructura de directorios recomendada:**
```
/proyecto-cliente/
├── config/              # Configuraciones específicas del cliente
│   ├── branding/        # Assets de branding
│   ├── env/             # Variables de entorno
│   └── plugins/         # Plugins personalizados
├── src/                 # Código fuente personalizado
│   ├── components/      # Componentes UI personalizados
│   ├── stores/          # Stores personalizados
│   └── utils/           # Utilidades específicas
└── tests/               # Pruebas específicas del cliente
```

**Configuración de entorno con Docker Compose:**
```yaml
# docker-compose.client.yml
version: '3.8'

services:
  webui:
    image: ghcr.io/codingsoft/open-webui:main
    container_name: client-webui
    ports:
      - "3000:8080"
    volumes:
      - ./config/branding:/app/backend/static/branding
      - ./data:/app/backend/data
    environment:
      - BRAND_NAME=NombreCliente
      - PRIMARY_COLOR:#ff5733
      - SUPPORT_URL=https://soporte.cliente.com
      - CUSTOM_PLUGINS=/app/backend/static/plugins
    restart: always

  ollama:
    image: ollama/ollama
    container_name: client-ollama
    volumes:
      - ollama-data:/root/.ollama
    restart: always

volumes:
  ollama-data:
```

### Configuración de Variables de Entorno

**Archivo .env personalizado:**
```bash
# config/env/.env.client

# Configuración de branding
VITE_BRAND_NAME="Nombre Empresa"
VITE_BRAND_LOGO="/branding/logo-cliente.png"
VITE_PRIMARY_COLOR="#ff5733"
VITE_SECONDARY_COLOR="#4a4a4a"
VITE_SUPPORT_URL="https://soporte.empresa.com"

# Configuración de API
VITE_API_BASE_URL="https://api.empresa.com"
VITE_CUSTOM_ENDPOINTS="https://api.empresa.com/custom"

# Configuración de características
VITE_FEATURE_FLAG_ANALYTICS=true
VITE_FEATURE_FLAG_CUSTOM_DASHBOARD=true
VITE_FEATURE_FLAG_ENTERPRISE_AUTH=true

# Configuración de telemetría
VITE_TELEMETRY_ENDPOINT="https://telemetria.codingsoft.org/api/v1/events"
VITE_CLIENT_ID="empresa-cliente-123"
```

### Personalización de Build para Clientes

**Configuración de Vite personalizada:**
```javascript
// vite.client.config.js
import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import path from 'path'

export default defineConfig({
  plugins: [svelte()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@client': path.resolve(__dirname, './config/client')
    }
  },
  define: {
    'process.env': {
      CLIENT_ID: process.env.VITE_CLIENT_ID,
      CUSTOM_FEATURES: process.env.VITE_CUSTOM_FEATURES
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `
          @import "./config/client/styles/variables.scss";
          @import "./config/client/styles/mixins.scss";
        `
      }
    }
  },
  build: {
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, 'index.html'),
        dashboard: path.resolve(__dirname, 'config/client/dashboard.html')
      }
    }
  }
})
```

### Configuración de Backend Personalizado

**Extensión de FastAPI para clientes:**
```python
# backend/open_webui/apps/client/routers/custom.py
from fastapi import APIRouter, Depends
from open_webui.models.users import get_current_user
from open_webui.utils.auth import verify_client_access

router = APIRouter(
    prefix="/api/v1/client",
    tags=["client"],
    dependencies=[Depends(verify_client_access)]
)

@router.get("/custom-data")
async def get_client_custom_data(current_user: dict = Depends(get_current_user)):
    """
    Endpoint personalizado para datos específicos del cliente
    """
    from open_webui.models.client import ClientData
    
    client_data = ClientData.get_data_for_user(current_user['id'])
    return {
        "status": "success",
        "data": client_data,
        "client_specific": True
    }

@router.post("/custom-action")
async def perform_client_action(
    action_data: dict,
    current_user: dict = Depends(get_current_user)
):
    """
    Acción personalizada para flujos de trabajo específicos
    """
    from open_webui.services.client import ClientService
    
    result = ClientService.perform_action(
        user_id=current_user['id'],
        action_data=action_data
    )
    
    return {
        "status": "success",
        "result": result
    }
```

### Configuración de Pruebas para Entornos Personalizados

**Configuración de pruebas con pytest:**
```python
# backend/open_webui/test/conftest.py
import pytest
from fastapi.testclient import TestClient
from open_webui.main import app

@pytest.fixture(scope="module")
def client():
    """Client de prueba con configuración personalizada"""
    # Configuración específica del cliente
    app.state.client_config = {
        "client_id": "test-client-123",
        "custom_features": ["analytics", "dashboard"]
    }
    
    with TestClient(app) as c:
        yield c

@pytest.fixture(scope="function")
def client_db():
    """Base de datos de prueba con datos específicos del cliente"""
    from open_webui.models.client import setup_test_data
    
    # Configurar datos de prueba específicos
    test_data = setup_test_data(
        client_id="test-client-123",
        custom_schemas=True
    )
    
    yield test_data
    
    # Limpiar después de las pruebas
    test_data.cleanup()
```

### Scripts de Despliegue Personalizados

**Script de despliegue para entornos empresariales:**
```bash
#!/bin/bash
# deploy-client.sh

# Configuración del cliente
CLIENT_NAME="empresa-cliente"
ENVIRONMENT="production"
VERSION="1.2.3"

# Despliegue de backend
echo "Desplegando backend personalizado..."
docker build -t ${CLIENT_NAME}-backend \
  --build-arg CLIENT_ID=${CLIENT_NAME} \
  --build-arg ENVIRONMENT=${ENVIRONMENT} \
  -f Dockerfile.client .

# Despliegue de frontend
echo "Construyendo frontend personalizado..."
npm run build:client

docker build -t ${CLIENT_NAME}-frontend \
  --build-arg VITE_BRAND_NAME="${CLIENT_NAME}" \
  --build-arg VITE_PRIMARY_COLOR="#ff5733" \
  -f Dockerfile.frontend .

# Despliegue con Docker Stack
echo "Desplegando stack..."
docker stack deploy -c docker-compose.${ENVIRONMENT}.yml ${CLIENT_NAME}-stack

# Verificación
echo "Verificando despliegue..."
sleep 30
curl -s https://${CLIENT_NAME}.webui.codingsoft.org/health | jq .

echo "Despliegue completado para ${CLIENT_NAME} v${VERSION}"
```

### Consideraciones para Entornos Personalizados

1. **Aislamiento de configuraciones:**
   - Mantener configuraciones específicas del cliente en directorios separados
   - Usar variables de entorno con prefijos específicos (ej: `CLIENT_`)
   - Evitar mezclar código base con personalizaciones

2. **Gestión de secretos:**
   - Usar herramientas como Vault o AWS Secrets Manager
   - Nunca commitear secretos en el repositorio
   - Rotar secretos regularmente

3. **Control de versiones:**
   - Mantener un registro de cambios para cada cliente
   - Usar tags específicos para versiones de clientes
   - Documentar dependencias específicas

4. **Monitorización personalizada:**
   - Configurar alertas específicas para cada cliente
   - Crear dashboards personalizados
   - Implementar logging estructurado con contexto de cliente

5. **Actualizaciones:**
   - Proceso de actualización documentado para cada cliente
   - Pruebas de regresión automatizadas
   - Plan de rollback claro y probado

## Gestión de Releases y Control de Versiones

### Estrategia de Versionado

**Sistema de versionado SemVer:**
- `MAJOR.MINOR.PATCH` (ej: `1.2.3`)
- `MAJOR`: Cambios incompatibles con versiones anteriores
- `MINOR`: Nuevas funcionalidades compatibles
- `PATCH`: Correcciones de bugs compatibles

**Versionado para clientes empresariales:**
- Usar sufijos específicos: `1.2.3-client123`
- Tags de pre-release: `1.2.3-beta.1`, `1.2.3-rc.1`
- Versiones LTS: `1.2.3-lts.1` para soporte extendido

### Proceso de Creación de Releases

**Preparación del release:**
```bash
# 1. Actualizar versión en package.json
npm version 1.2.3 -m "Release v1.2.3"

# 2. Actualizar CHANGELOG.md
git add CHANGELOG.md package.json

# 3. Crear tag de release
git tag -a v1.2.3 -m "Release v1.2.3"

# 4. Push de tag a repositorio
git push origin v1.2.3
```

**Creación de release en GitHub:**
```bash
# Usar GitHub CLI
gh release create v1.2.3 \
  --title "Release v1.2.3" \
  --notes "$(cat CHANGELOG.md | head -20)" \
  --target main
```

### Automatización de Releases

**GitHub Actions para releases:**
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            dist/*
            backend/dist/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Trabajo con Registro de Contenedores

### Autenticación y Configuración

**Autenticación con GitHub Container Registry:**
```bash
# Login en GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Configurar permisos para organización
docker logout ghcr.io
```

**Configuración de Docker para múltiples registros:**
```json
# ~/.docker/config.json
{
  "auths": {
    "ghcr.io": {
      "auth": "BASE64_ENCODED_CREDENTIALS"
    },
    "docker.io": {
      "auth": "BASE64_ENCODED_CREDENTIALS"
    }
  }
}
```

### Construcción y Publicación de Imágenes

**Construcción de imágenes personalizadas:**
```bash
# Construir imagen base
docker build -t ghcr.io/codingsoft/open-webui:main .

# Construir imagen con CUDA
docker build -t ghcr.io/codingsoft/open-webui:cuda --build-arg CUDA=1 .

# Construir imagen con Ollama
docker build -t ghcr.io/codingsoft/open-webui:ollama --build-arg OLLAMA=1 .
```

**Publicación de imágenes:**
```bash
# Publicar imagen
docker push ghcr.io/codingsoft/open-webui:main

# Publicar múltiples tags
docker tag ghcr.io/codingsoft/open-webui:main ghcr.io/codingsoft/open-webui:1.2.3
docker push ghcr.io/codingsoft/open-webui:1.2.3
```

### Gestión de Imágenes en GHCR

**Listar imágenes en el registro:**
```bash
# Usar GitHub CLI
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/codingsoft/packages/container/open-webui/versions
```

**Eliminar imágenes antiguas:**
```bash
# Eliminar versión específica
gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/codingsoft/packages/container/open-webui/versions/123456
```

### Estrategias de Versionado de Imágenes

1. **Versionado semántico:**
   - `ghcr.io/codingsoft/open-webui:v1.2.3`
   - `ghcr.io/codingsoft/open-webui:v1.2.3-client123`

2. **Tags de release:**
   - `ghcr.io/codingsoft/open-webui:main` (última versión estable)
   - `ghcr.io/codingsoft/open-webui:dev` (versión de desarrollo)

3. **Tags de características:**
   - `ghcr.io/codingsoft/open-webui:cuda` (con soporte CUDA)
   - `ghcr.io/codingsoft/open-webui:ollama` (con Ollama integrado)

4. **Tags de commit:**
   - `ghcr.io/codingsoft/open-webui:sha-abc1234` (versión específica)

### Seguridad en el Registro de Contenedores

1. **Escaneo de vulnerabilidades:**
   ```bash
   # Usar Trivy para escaneo
docker run --rm aquasec/trivy image ghcr.io/codingsoft/open-webui:main
   ```

2. **Firmado de imágenes:**
   ```bash
   # Usar Cosign para firmar imágenes
cosign sign --key cosign.key ghcr.io/codingsoft/open-webui:main
   ```

3. **Políticas de retención:**
   - Mantener últimas 5 versiones principales
   - Mantener últimas 3 versiones menores por release mayor
   - Eliminar imágenes no etiquetadas después de 30 días

### Integración con CI/CD

**Ejemplo de workflow para construcción y publicación:**
```yaml
# .github/workflows/docker-build.yml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/codingsoft/open-webui
          tags: |
            type=ref,event=branch
            type=ref,event=tag
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Mejores Prácticas para Gestión de Contenedores

1. **Optimización de imágenes:**
   - Usar imágenes base mínimas (alpine)
   - Multi-stage builds para reducir tamaño
   - Limpiar caché y archivos temporales

2. **Etiquetado consistente:**
   - Mantener consistencia en naming de tags
   - Documentar estrategia de versionado
   - Usar tags inmutables para releases

3. **Documentación:**
   - Mantener README actualizado con instrucciones de uso
   - Documentar variables de entorno requeridas
   - Incluir ejemplos de docker-compose.yml

4. **Monitoreo:**
   - Configurar alertas para pulls de imágenes
   - Monitorear uso de almacenamiento en GHCR
   - Auditar permisos de acceso regularmente

## Comandos de Construcción/Linting/Pruebas

### Frontend (Svelte/TypeScript)

**Desarrollo:**
```bash
npm run dev              # Iniciar servidor de desarrollo
npm run dev:5050         # Iniciar en el puerto 5050
```

**Construcción:**
```bash
npm run build           # Construcción para producción
npm run build:watch     # Construcción en modo observación
npm run preview         # Vista previa de la construcción de producción
```

**Linting:**
```bash
npm run lint            # Ejecutar todos los linters (frontend + tipos + backend)
npm run lint:frontend   # ESLint para código frontend
npm run lint:types      # Verificación de tipos TypeScript
```

**Formateo:**
```bash
npm run format          # Formatear todos los archivos frontend
npm run format:backend  # Formatear código Python backend con black
```

**Pruebas:**
```bash
npm run test:frontend   # Ejecutar pruebas frontend con vitest
npm run cy:open         # Abrir ejecutor de pruebas Cypress
```

**Ejecución de Pruebas Individuales:**
```bash
npx vitest run <test-file>  # Ejecutar prueba específica de vitest
npx cypress run --spec "cypress/e2e/<test-file>.cy.js"  # Ejecutar prueba específica de Cypress
```

### Backend (Python/FastAPI)

**Pruebas:**
```bash
# Instalar dependencias de prueba primero
pip install pytest pytest-asyncio

# Ejecutar todas las pruebas backend
pytest backend/open_webui/test/

# Ejecutar archivo de prueba individual
pytest backend/open_webui/test/apps/webui/routers/test_auths.py

# Ejecutar prueba específica
pytest backend/open_webui/test/apps/webui/routers/test_auths.py::TestAuths::test_get_session_user

# Ejecutar con salida detallada
pytest -v backend/open_webui/test/
```

**Linting:**
```bash
npm run lint:backend    # Ejecutar pylint en código backend
```

## Directrices de Estilo de Código

### TypeScript/JavaScript

**Importaciones:**
- Usar importaciones absolutas desde el alias `@/` para archivos del proyecto
- Agrupar importaciones: built-ins, externas, archivos del proyecto
- Ordenar importaciones alfabéticamente dentro de los grupos
- Sin importaciones comodín

**Formateo:**
- Sangría de 2 espacios
- Comillas simples para strings
- Comas finales en objetos/arrays multiline
- Punto y coma opcional (Prettier lo maneja)
- Longitud máxima de línea: 100 caracteres

**Tipos:**
- Usar interfaces TypeScript para tipos complejos
- Preferir `type` sobre `interface` para tipos simples
- Siempre anotar parámetros de funciones y tipos de retorno
- Usar genéricos apropiadamente

**Convenciones de Nomenclatura:**
- PascalCase para componentes (ej., `MyComponent.svelte`)
- camelCase para variables y funciones
- UPPER_CASE para constantes
- Prefijar variables booleanas con `is`, `has`, `can`, etc.
- Usar nombres descriptivos (evitar abreviaturas)

**Manejo de Errores:**
- Usar try/catch para operaciones asíncronas
- Proporcionar mensajes de error significativos
- Registrar errores apropiadamente
- Manejar casos límite con gracia

### Python (Backend)

**Importaciones:**
- Seguir el orden de importación PEP 8
- Agrupar: biblioteca estándar, terceros, locales
- Ordenar alfabéticamente dentro de los grupos
- Sin importaciones comodín

**Formateo:**
- Usar formateador black (longitud de línea 100)
- Comillas simples para strings
- Comas finales en estructuras multiline
- Espaciado consistente alrededor de operadores

**Tipos:**
- Usar hints de tipos Python
- Anotar firmas de funciones
- Usar `Optional` para tipos anulables
- Preferir `List`, `Dict`, etc. del módulo `typing`

**Convenciones de Nomenclatura:**
- snake_case para variables y funciones
- CamelCase para nombres de clases
- UPPER_CASE para constantes
- Prefijar miembros privados con `_`
- Usar nombres descriptivos

**Manejo de Errores:**
- Usar tipos de excepción específicos
- Proporcionar contexto en mensajes de error
- Usar `raise from` para encadenamiento de excepciones
- Registrar excepciones apropiadamente

### Componentes Svelte

**Estructura:**
```svelte
<script lang="ts">
  // Lógica del componente
</script>

<!-- Marcado del componente -->
<style>
  /* Estilos del componente (con alcance por defecto) */
</style>
```

**Mejores Prácticas:**
- Usar declaraciones reactivas (`$:`) para estado derivado
- Preferir stores para estado global
- Usar acciones para manipulaciones DOM
- Mantener componentes enfocados y pequeños
- Usar slots para composición

## Estructura del Proyecto

```
/
├── backend/              # Backend Python FastAPI
│   ├── open_webui/       # Código principal backend
│   │   ├── apps/         # Módulos de aplicación
│   │   ├── models/       # Modelos de base de datos
│   │   ├── test/         # Pruebas backend
│   │   └── ...
│   └── requirements.txt  # Dependencias Python
│
├── src/                  # Código Svelte frontend
│   ├── lib/              # Componentes y utilidades reutilizables
│   │   ├── components/   # Componentes UI
│   │   ├── stores/       # Stores Svelte
│   │   ├── utils/        # Funciones utilitarias
│   │   └── i18n/         # Internacionalización
│   ├── routes/           # Rutas de páginas
│   └── app.d.ts          # Declaraciones de tipos
│
├── static/              # Activos estáticos
├── tests/               # Archivos de prueba
└── package.json          # Configuración del proyecto
```

## Enfoque de Pruebas

### Pruebas Frontend
- **Vitest**: Pruebas unitarias para utilidades y componentes
- **Cypress**: Pruebas end-to-end para flujos de usuario
- Los archivos de prueba deben estar colocados junto a los archivos fuente
- Usar nombres de prueba descriptivos
- Probar tanto caminos felices como casos límite

### Pruebas Backend
- **Pytest**: Marco de pruebas Python
- **pytest-asyncio**: Para soporte de pruebas asíncronas
- Archivos de prueba en el directorio `backend/open_webui/test/`
- Seguir el patrón AAA (Arreglar, Actuar, Afirmar)
- Usar mocking para dependencias externas

## Internacionalización (i18n)

- Archivos de traducción en `src/lib/i18n/locales/`
- Usar formato JSON para traducciones
- Seguir códigos de idioma ISO 639
- Mantener consistencia en claves de traducción
- Usar `i18n.t('key')` para traducciones en código

## Flujo de Trabajo con Git

- Usar ramas de características para nuevo trabajo
- Escribir mensajes de commit descriptivos
- Referenciar issues en commits (ej., "Fixes #123")
- Mantener commits enfocados y pequeños
- Usar pull requests para revisión de código

## Comandos Comunes

**Instalar dependencias:**
```bash
npm install           # Dependencias frontend
pip install -e .      # Backend en modo desarrollo
```

**Ejecutar frontend y backend:**
```bash
# Terminal 1: Backend
cd backend && python -m open_webui.main

# Terminal 2: Frontend
npm run dev
```

**Actualizar traducciones:**
```bash
npm run i18n:parse    # Analizar y actualizar archivos de traducción
```

## Consejos de Depuración

**Frontend:**
- Usar herramientas de desarrollo del navegador
- Revisar la consola para errores
- Usar declaraciones `debugger`
- Habilitar inspector Svelte en modo desarrollo

**Backend:**
- Usar documentación interactiva de FastAPI
- Revisar logs del servidor
- Usar depurador Python (pdb)
- Habilitar logging detallado

## Consideraciones de Rendimiento

- Minimizar re-renders en componentes Svelte
- Usar memoización para computaciones costosas
- Optimizar consultas a base de datos
- Implementar caching adecuado
- Usar carga diferida para componentes pesados

## Personalización de Branding

Open WebUI ofrece opciones de personalización de branding para adaptar la interfaz a las necesidades de tu organización:

**Configuración de Branding:**
- **Nombre de la Aplicación**: Cambia el nombre que aparece en la interfaz
- **Logotipo**: Reemplaza el logotipo por defecto con tu propio logotipo
- **Colores**: Personaliza la paleta de colores para que coincida con tu identidad corporativa
- **Favicon**: Configura un favicon personalizado
- **Título del Documento**: Modifica el título que aparece en la pestaña del navegador

**Archivos de Configuración:**
- Los ajustes de branding se encuentran típicamente en archivos de configuración como `app.config.js` o `branding.config.json`
- Busca variables como `APP_NAME`, `LOGO_PATH`, `PRIMARY_COLOR`, etc.

**Personalización de CSS:**
- Para cambios más avanzados, puedes modificar los archivos CSS en `src/lib/styles/`
- Usa variables CSS para mantener la consistencia:
  ```css
  :root {
    --primary-color: #tu-color-primario;
    --secondary-color: #tu-color-secundario;
    --accent-color: #tu-color-de-acento;
  }
  ```

**Consideraciones:**
- Mantén una relación de contraste adecuada para accesibilidad
- Prueba tu branding en diferentes tamaños de pantalla
- Considera tanto el modo claro como el modo oscuro
- Documenta tus cambios de branding para futuras referencias
