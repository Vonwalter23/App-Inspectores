# 🤖 AGENTE.md - Sistema Integral para Inspectores de Tránsito de Trelew

> **Este archivo contiene todo el conocimiento del proyecto. Un agente de IA debe leerlo para entender el sistema completo, su arquitectura, tecnologías, y poder continuar con el desarrollo o mantenimiento.**

---

## 📊 ESTADO DEL PROYECTO (22 Jun 2026)

| Componente | Estado | Notas |
|------------|--------|-------|
| Firebase Project | ✅ Configurado | `app-inspectores-trelew-499913` |
| Firestore Rules | ✅ Desplegado | Seguridad activa |
| Firestore Indexes | ✅ Desplegado | - |
| Chat IA | ✅ Funcional | Directo a Groq API (sin Cloud Functions) |
| Panel Web Admin | ✅ Código listo | Requiere deploy |
| App Android | ✅ Código listo | Requiere compilación |
| Cloud Functions | ❌ No disponible | Requiere billing |

### Proyecto Firebase
- **ID:** `app-inspectores-trelew-499913`
- **Plan:** Spark (GRATIS)
- **Storage:** Pendiente inicialización manual

### Cuenta de Servicio
- **Email:** `firebase-deploy@app-inspectores-trelew-499913.iam.gserviceaccount.com`
- **Roles:** Firebase Admin, Cloud Functions Admin, Cloud Storage Admin

### Decisiones Importantes
1. **Chat IA directo:** La app llama directamente a Groq API (no usa Cloud Functions)
2. **RAG en cliente:** Búsqueda de fragmentos en Firestore desde el cliente
3. **Sin Cloud Functions:** No se usa por requerimiento de billing

---

## 📋 TABLA DE CONTENIDOS

1. [Resumen del Proyecto](#-resumen-del-proyecto)
2. [Configuración de APIs y Credenciales](#-configuración-de-apis-y-credenciales)
3. [Arquitectura del Sistema](#-arquitectura-del-sistema)
4. [Modelo de Datos](#-modelo-de-datos-firestore)
5. [Flujo de Autenticación](#-flujo-de-autenticación)
6. [Sistema RAG (Asistente Legal IA)](#-sistema-rag-asistente-legal-ia)
7. [Funcionalidades por Rol](#-funcionalidades-por-rol)
8. [Estructura del Código](#-estructura-del-código)
9. [Seguridad](#-seguridad)
10. [Costos y Límites](#-costos-y-límites)
11. [Comandos de Desarrollo](#-comandos-de-desarrollo)
12. [Solución de Problemas](#-solución-de-problemas)
13. [Futuras Mejoras](#-futuras-mejoras)

---

## 🎯 RESUMEN DEL PROYECTO

### Nombre
**Sistema Integral para Inspectores de Tránsito de Trelew**

### Objetivo
Plataforma compuesta por:
- **Aplicación Android (APK)** - Para inspectores de tránsito
- **Panel Web Administrativo** - Para administradores

### Ubicación
Trelew, Chubut, Argentina

### Tecnologías Core
| Componente | Tecnología |
|------------|------------|
| App Móvil | Flutter 3.16+ / Dart 3.2+ |
| Backend | Firebase (Auth, Firestore, Functions, FCM) |
| AI | Groq API (Llama 3.1) |
| Maps | Google Maps JavaScript API |
| Storage | Google Drive API |
| Hosting | Firebase Hosting |

---

## 🔐 CONFIGURACIÓN DE APIS Y CREDENCIALES

### Firebase Project
```
Project ID: app-inspectores-trelew
Project Number: 946555132852
Database URL: https://app-inspectores-trelew-default-rtdb.firebaseio.com
```

### Firebase Web Config
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyCbOI6ePQm4a24qXK3bMSmfztC_FHD88bY",
  authDomain: "app-inspectores-trelew.firebaseapp.com",
  databaseURL: "https://app-inspectores-trelew-default-rtdb.firebaseio.com",
  projectId: "app-inspectores-trelew",
  storageBucket: "app-inspectores-trelew.firebasestorage.app",
  messagingSenderId: "946555132852",
  appId: "1:946555132852:web:f54dd2762f4c47b19fb0e1",
  measurementId: "G-8LF98EX6Q7"
};
```

### Google OAuth 2.0 Credentials
```
Client ID: ${GOOGLE_OAUTH_CLIENT_ID}
Client Secret: ${GOOGLE_OAUTH_CLIENT_SECRET}
```

### Google Maps API Key
```
AIzaSyBpKbl3vRcqNRwcMm3f8qOOPGpb43qXQZE
```

### Groq API
```
API Key: ${GROQ_API_KEY}
Model: llama-3.1-8b-instant
Endpoint: https://api.groq.com/openai/v1/chat/completions
```

### Google Drive
```
Folder ID: 11U5_4AceI_l7cEEkEjaEk_WLUsXSi1Jz
Folder Name: App Inspectores
```

### Android Package
```
Package Name: com.municipalidad.trelew.inspectores
google-services.json: Configurado en android/app/
```

---

## 🏗️ ARQUITECTURA DEL SISTEMA

### Diagrama de Componentes
```
┌────────────────────────────────────────────────────────────────────┐
│                     SISTEMA INSPECTORES TRELEW                      │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌──────────────────┐        ┌──────────────────┐              │
│   │   APP ANDROID     │        │   PANEL WEB      │              │
│   │   (Flutter)       │        │   (HTML/JS)      │              │
│   │                   │        │                   │              │
│   │ • Login Google    │        │ • Dashboard       │              │
│   │ • Chat IA         │        │ • Gestión Users   │              │
│   │ • Mensajería      │        │ • Gestión Docs    │              │
│   │ • Geolocalización │        │ • Mapa Real-Time  │              │
│   │ • Notificaciones  │        │ • Logs           │              │
│   └────────┬─────────┘        └────────┬─────────┘              │
│            │                            │                        │
│            └──────────┬─────────────────┘                        │
│                       │                                            │
│                       ▼                                            │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │                    FIREBASE BACKEND                        │   │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐  │   │
│   │  │   Auth  │ │Firestore│ │Functions│ │ Cloud Messaging │  │   │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘  │   │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────────────────────────┐ │   │
│   │  │ Storage │ │ Hosting │ │       Firestore Rules       │ │   │
│   │  └─────────┘ └─────────┘ └─────────────────────────────┘ │   │
│   └──────────────────────────────────────────────────────────┘   │
│                       │                                          │
│   ┌───────────────────┼───────────────────┐                     │
│   │                   │                   │                     │
│   ▼                   ▼                   ▼                     │
│ ┌────────┐      ┌───────────┐      ┌────────────┐              │
│ │  Groq  │      │Google     │      │ Google     │              │
│ │   AI   │      │Drive API  │      │ Maps API   │              │
│ └────────┘      └───────────┘      └────────────┘              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Capas de la Aplicación Flutter
```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER               │
│  (Pages, Widgets, UI Components)        │
├─────────────────────────────────────────┤
│         BUSINESS LOGIC LAYER             │
│  (Services, State Management)            │
├─────────────────────────────────────────┤
│            DATA LAYER                    │
│  (Repositories, Firebase SDK)           │
├─────────────────────────────────────────┤
│         EXTERNAL SERVICES                │
│  (Firebase, Google APIs, Groq)          │
└─────────────────────────────────────────┘
```

---

## 🗄️ MODELO DE DATOS (FIRESTORE)

### Colecciones Principales

#### 1. `users` - Usuarios del Sistema
```typescript
interface User {
  uid: string;                    // Firebase Auth UID
  email: string;                  // Email de Google
  nombre: string;                 // Nombre
  apellido: string;              // Apellido
  credencial: string;            // Número de credencial (4 cifras)
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  rol: 'inspector' | 'admin';
  fotoUrl?: string;              // Foto de perfil
  fcmToken?: string;            // Token FCM
  fechaRegistro: Timestamp;
  fechaActualizacion: Timestamp;
  ultimoAcceso?: Timestamp;
}
```

#### 2. `ubicaciones` - Ubicación en Tiempo Real
```typescript
interface Ubicacion {
  uid: string;
  nombre: string;
  apellido: string;
  credencial: string;
  latitud: number;              // -43.2489 (Trelew)
  longitud: number;              // -65.3050 (Trelew)
  precision: number;             // Precisión GPS en metros
  activo: boolean;              // Si está transmitiendo
  timestamp: Timestamp;          // Última actualización
}
```

#### 3. `mensajes` - Mensajería Interna
```typescript
interface Mensaje {
  mensajeId: string;
  remitenteId: string;
  remitenteNombre: string;
  remitenteCredencial: string;
  contenido: string;             // Texto del mensaje
  tipo: 'texto' | 'audio';     // Tipo de mensaje
  audioUrl?: string;            // URL del audio
  mencion: string[];            // @usuario o @todos
  mencionUsuarios: string[];     // UIDs mencionados
  leidoPor: string[];            // Quiénes lo leyeron
  timestamp: Timestamp;
}
```

#### 4. `documentos` - Índice de Documentos Legales (RAG)
```typescript
interface Documento {
  documentoId: string;
  nombre: string;                // Título
  tipo: 'ley' | 'ordenanza' | 'resolucion' | 'reglamento';
  categoria?: string;            // Ej: "Tránsito"
  numero?: string;               // Ej: "Ordenanza 1234/2024"
  driveFileId: string;           // ID en Google Drive
  driveFileUrl: string;          // URL para visualizar
  nombreOriginal: string;
  tamanhoBytes: number;
  estado: 'pendiente' | 'indexando' | 'indexado' | 'error';
  totalFragmentos: number;
  subidoPor: string;             // UID admin
  fechaCarga: Timestamp;
  fragmentos: {
    [fragmentoId: string]: {
      texto: string;             // Chunk de 500 caracteres
      pagina: number;
      inicioChar: number;
      embedding?: number[];      // Vector (para RAG avanzado)
    }
  };
}
```

#### 5. `logs` - Registro de Actividad
```typescript
interface Log {
  logId: string;
  accion: string;                // Ej: "login", "usuario_aprobado"
  tipo: 'auth' | 'mensaje' | 'documento' | 'sistema' | 'ubicacion';
  usuarioId: string;
  usuarioNombre: string;
  detalles: string;
  timestamp: Timestamp;
}
```

#### 6. `requests` - Solicitudes de Acceso
```typescript
interface Request {
  requestId: string;              // = UID del usuario
  uid: string;
  email: string;
  nombre: string;
  apellido: string;
  credencial: string;
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  adminId?: string;               // Admin que respondió
  adminNombre?: string;
  respuestaMotivo?: string;
  adminResponse?: Timestamp;
  timestamp: Timestamp;
}
```

---

## 🔑 FLUJO DE AUTENTICACIÓN

### Diagrama de Flujo
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│INSPECTOR │────▶│ GOOGLE   │────▶│FIREBASE │
│ LOGIN    │     │ SIGN IN  │     │ AUTH    │
└──────────┘     └──────────┘     └────┬─────┘
                                      │
                         ┌────────────┴────────────┐
                         ▼                          ▼
                   ┌───────────┐              ┌───────────┐
                   │  EXISTE?  │              │ NEW USER │
                   │ user.doc  │              │          │
                   └─────┬─────┘              └─────┬─────┘
                         │                          │
                         ▼                          ▼
                   ┌───────────┐              ┌───────────┐
                   │CHECK STATUS│              │ CREATE   │
                   │approved?  │              │ REQUEST  │
                   └─────┬─────┘              │(pending) │
                         │                    └──────────┘
              ┌──────────┴──────────┐
              ▼                     ▼
        ┌───────────┐         ┌───────────┐
        │  APPROVED │         │ PENDING   │
        │           │         │           │
        │  → HOME   │         │ → WAITING │
        │   PAGE    │         │   SCREEN  │
        └───────────┘         └───────────┘

ADMIN: Revisa requests → Approve/Reject
       ↓
       Notificación FCM al inspector
```

### Estados del Usuario
1. **Nuevo usuario**: Se crea con estado "pendiente"
2. **Administrador**: Aprueba o rechaza desde el panel web
3. **Aprobado**: Puede usar la aplicación
4. **Rechazado**: No puede acceder (debe contactar admin)

---

## 🤖 SISTEMA RAG (ASISTENTE LEGAL IA)

### ¿Qué es RAG?
**Retrieval Augmented Generation** - Sistema que combina búsqueda de documentos con IA generativa.

### Flujo de Consulta
```
┌─────────────────────────────────────────────────────────────────┐
│                        CONSULTA RAG                              │
├─────────────────────────────────────────────────────────────────┤
│ 1. Inspector pregunta: "¿Cuál es la velocidad máxima?"            │
│                           ↓                                      │
│ 2. App → Cloud Function: /api/query-ai                          │
│                           ↓                                      │
│ 3. Buscar fragmentos relevantes en Firestore                     │
│    (búsqueda por keywords en fragmentos.indexados)             │
│                           ↓                                      │
│ 4. Construir contexto con fragmentos encontrados                  │
│                           ↓                                      │
│ 5. Enviar a Groq API con prompt del sistema                     │
│    Modelo: llama-3.1-8b-instant                               │
│                           ↓                                      │
│ 6. Respuesta formateada:                                        │
│    "Velocidad máxima: 40 km/h"                                  │
│    "📋 Norma: Ordenanza XXX"                                    │
│    "📌 Artículo: XX"                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Prompt del Sistema (Groq)
```markdown
Eres un asistente legal especializado en legislación de tránsito de 
Argentina, específicamente del municipio de Trelew, Chubut.

REGLAS:
1. SOLO responde usando información de los documentos oficiales
2. NUNCA inventes o uses conocimiento general del modelo
3. Si NO está en documentos: "No se encontró información en las normas cargadas."
4. Cite siempre la norma y artículo

FORMATO:
[Respuesta breve]

📋 Norma: [Nombre]
📌 Artículo: [Número]
```

### Indexación de Documentos
1. Admin sube PDF → Google Drive
2. Cloud Function extrae texto
3. Fragmenta en chunks de 500 caracteres
4. Guarda fragmentos en Firestore
5. Inspector puede consultar

---

## 👥 FUNCIONALIDADES POR ROL

### INSPECTOR (App Android)
| Funcionalidad | Descripción |
|---------------|-------------|
| 🔐 Login Google | Autenticación con cuenta Google |
| ⏳ Pantalla Espera | Muestra estado de solicitud |
| 🏠 Dashboard | Stats y accesos rápidos |
| 🤖 Chat IA Legal | Consulta normas con RAG |
| 💬 Mensajería | Canal interno con menciones @ |
| 🎤 Audio | Mensajes de voz (máx 30 seg) |
| 📍 Geolocalización | GPS cada 30 segundos |
| 🔔 Notificaciones | Alertas por menciones |
| 🌙 Modo Oscuro | Tema dark/light automático |

### ADMINISTRADOR (Panel Web)
| Funcionalidad | Descripción |
|---------------|-------------|
| 📊 Dashboard | Estadísticas del sistema |
| 👥 Gestión Usuarios | Aprobar/rechazar inspectores |
| 📄 Gestión Docs | Subir/eliminar/indexar PDFs |
| 🗺️ Mapa Tiempo Real | Ver inspectores en mapa |
| 📜 Logs | Registro de actividad |
| ⚙️ Config | Configuración general |

---

## 📁 ESTRUCTURA DEL CÓDIGO

### App Android (Flutter)
```
app_inspectores/
├── lib/
│   ├── main.dart                    # Entry point
│   └── src/
│       ├── auth/
│       │   ├── login_page.dart     # Login con Google
│       │   └── pending_page.dart   # Espera aprobación
│       ├── home/
│       │   └── home_page.dart      # Dashboard principal
│       ├── chat/
│       │   └── chat_page.dart      # Chat IA Legal
│       ├── mensajeria/
│       │   └── mensajes_page.dart  # Mensajería interna
│       ├── services/
│       │   ├── location_service.dart   # GPS tracking
│       │   ├── chat_service.dart      # RAG queries
│       │   ├── mensaje_service.dart   # Mensajes y audio
│       │   └── notification_service.dart # FCM
│       ├── widgets/
│       │   └── profile_drawer.dart # Menú lateral
│       └── theme/
│           └── app_theme.dart      # Material Design 3
├── android/
│   └── app/
│       ├── google-services.json   # Firebase config
│       └── src/main/
│           └── AndroidManifest.xml # Permisos
└── pubspec.yaml                   # Dependencias
```

### Panel Web Admin
```
panel_admin/
├── public/
│   ├── index.html                  # SPA completa
│   ├── css/
│   │   └── styles.css             # Estilos profesionales
│   └── js/
│       ├── firebase-config.js     # Config Firebase
│       └── app.js                # Lógica completa
└── functions/
    ├── package.json
    └── src/
        └── index.ts               # Cloud Functions (RAG, FCM)
```

### Backend Firebase
```
├── firebase.json                  # Config despliegue
├── firestore.rules                # Reglas de seguridad
├── firestore.indexes.json        # Índices compuestos
└── storage.rules                 # Reglas de Storage
```

---

## 🔒 SEGURIDAD

### Firestore Security Rules
```javascript
// Solo admins pueden ver logs
allow read: if isAdmin();

// Solo inspectores aprobados pueden crear mensajes
allow create: if isInspector();

// Usuarios solo modifican su propia ubicación
allow write: if isOwnData(userId);
```

### Principios
1. **Mínimo Privilegio**: Cada rol accede solo a lo necesario
2. **Validación de Estado**: Solo "aprobado" puede usar la app
3. **Separación de Roles**: Inspectores ≠ Administradores
4. **Validación de Datos**: Tipos y rangos verificados

### Storage Rules
- Audio: Solo el propio usuario puede subir
- Perfiles: Solo lectura pública, escritura privada
- Documentos: Solo admins pueden subir

---

## 💰 COSTOS Y LÍMITES

### Firebase Spark Plan (GRATIS)
| Servicio | Límite | Uso |
|----------|--------|-----|
| Authentication | Ilimitado | ✅ |
| Firestore | 1GB, 50K reads/día | ✅ |
| Storage | 5GB | ✅ |
| Cloud Functions | 2M invocaciones/mes | ✅ |
| Hosting | 10GB | ✅ |
| Cloud Messaging | Ilimitado | ✅ |

### Groq API (Free Tier)
- 30 requests/minuto
- 14,400 requests/día
- Suficiente para 60 inspectores

### Google Maps
- 28,000 map loads/mes (gratis)
- Excess: $7/1000 loads

### 💵 Costo Total Estimado: $0-5/mes

---

## 💻 COMANDOS DE DESARROLLO

### Flutter App
```bash
# Navegar al directorio
cd app_inspectores

# Instalar dependencias
flutter pub get

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Ejecutar en emulator
flutter run

# Limpiar cache
flutter clean
```

### Panel Web
```bash
# Navegar al directorio
cd panel_admin

# Inicializar Firebase (primera vez)
firebase init

# Desplegar todo
firebase deploy

# Desplegar solo hosting
firebase deploy --only hosting

# Ver logs de Functions
firebase functions:log
```

### Cloud Functions
```bash
cd panel_admin/functions

# Instalar dependencias
npm install

# Compilar TypeScript
npm run build

# Desplegar functions
firebase deploy --only functions

# Ejecutar localmente
npm run serve
```

### Firestore
```bash
# Desplegar reglas
firebase deploy --only firestore:rules

# Desplegar índices
firebase deploy --only firestore:indexes
```

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### Error: "No Firebase App has been created"
```bash
# Verificar google-services.json
ls android/app/google-services.json
```

### Error: "Location permissions denied"
- Verificar permisos en AndroidManifest.xml
- El usuario debe aceptar permisos de ubicación

### Error: "API key not valid"
- Verificar Google Maps API Key
- Revisar restricciones en Google Cloud Console

### Error: "User not approved"
- Verificar estado del usuario en Firestore
- El admin debe aprobar desde el panel web

### Error en Cloud Functions
```bash
# Ver logs
firebase functions:log

# Verificar API keys en configuración
```

---

## 🚀 FUTURAS MEJORAS

### Corto Plazo
- [ ] Agregar mensajes de audio
- [ ] Mejoras en el mapa
- [ ] Historial de consultas IA

### Mediano Plazo
- [ ] Soporte para iOS
- [ ] Reportes en PDF
- [ ] Chatbot más avanzado con embeddings reales

### Largo Plazo
- [ ] Módulo de multas
- [ ] Integración con sistema municipal
- [ ] Analytics avanzado

---

## 📞 SOPORTE

- **Email**: soporte@trelew.gob.ar
- **Teléfono**: 0800-XXX-XXXX
- **Horario**: Lunes a Viernes 8:00 - 14:00

---

## 📝 METADATOS

- **Versión**: 1.0.0
- **Fecha de Creación**: 2025
- **Desarrollado por**: OpenHands AI Agent
- **Para**: Municipalidad de Trelew
- **Licencia**: Propiedad de la Municipalidad de Trelew

---

*Este archivo se actualiza automáticamente con cada nueva funcionalidad o cambio significativo en el proyecto.*
