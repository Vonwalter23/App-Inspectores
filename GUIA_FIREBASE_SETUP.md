# 🚀 GUÍA PASO A PASO: CONFIGURACIÓN DE FIREBASE

## paso 1: Configuración desde Firebase Console

### 1.1 Crear Proyecto (si no existe)

1. Ve a: https://console.firebase.google.com/
2. Click en **"Crear proyecto"** o **"Add project"**
3. Nombre: `app-inspectores-trelew`
4. Desactiva Google Analytics (opcional)
5. Click **"Crear proyecto"**

### 1.2 Habilitar Authentication

1. En el menú lateral: **"Authentication"**
2. Click en **"Comenzar"** / **"Get started"**
3. Ve a la pestaña **"Sign-in method"**
4. Click en **"Google"**
5. Toggle: **"Habilitar"** ✅
6. Selecciona email y profile
7. Project support email: tu email
8. Click **"Guardar"**

### 1.3 Crear Firestore Database

1. En el menú lateral: **"Firestore Database"**
2. Click en **"Crear base de datos"**
3. Modo: **"Modo nativo"**
4. Ubicación: `southamerica-east1` (São Paulo - más cercano)
5. Click **"Habilitar"**
6. **Esperar** a que se cree

### 1.4 Habilitar Cloud Messaging

1. En el menú lateral: **"Messaging"**
2. Click en **"Comenzar"**
3. Acepta los términos
4. Listo ✅

### 1.5 Habilitar Storage

1. En el menú lateral: **"Storage"**
2. Click en **"Comenzar"**
3. Modo: **"Modo nativo"**
4. Ubicación: `southamerica-east1`
5. Click **"Siguiente"**
6. Click **"Listo"**

---

## PASO 2: Registrar Apps

### 2.1 Registrar App Android

1. Ve a **"Project Settings"** (ícono de engranaje)
2. Scroll hasta **"Tus apps"**
3. Click en **"Agregar app"** → **"Android"**
4. Android package name: `com.municipalidad.trelew.inspectores`
5. App nickname: `App Inspectores Trelew`
6. SHA-1 (opcional, para Google Sign In):
   ```
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
7. Click **"Registrar app"**
8. Descargar `google-services.json`
9. Guardar en: `app_inspectores/android/app/google-services.json`
10. Click **"Siguiente"** hasta **"Continuar"**

### 2.2 Registrar App Web

1. En Project Settings → **"Tus apps"**
2. Click **"Agregar app"** → **"Web"**
3. Nickname: `Panel Admin`
4. **NO** marcar Firebase Hosting
5. Click **"Registrar app"**
6. Copiar la configuración de Firebase:
```javascript
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  // etc.
};
```
7. Actualizar `panel_admin/public/js/firebase-config.js`

---

## PASO 3: Configurar Cloud Functions

### 3.1 Cambiar a Plan Blaze

1. Ve a **"Billing"** en Firebase Console
2. Click **"Cambiar de plan"**
3. Seleccionar **"Blaze"** (Pay as you go)
4. Vincular tarjeta de crédito (necesario para Functions)
5. **NOTA**: El tier gratuito cubre ~2M invocaciones/mes

### 3.2 Instalar dependencias de Functions

```bash
cd panel_admin/functions
npm install
```

### 3.3 Configurar cuenta de servicio

1. Ve a **"Project Settings"** → **"Usuarios y permisos"**
2. Click en **"Cuentas de servicio"**
3. Click **"Generar nueva clave privada"**
4. Guardar el archivo JSON (para desarrollo local)
5. **NOTA**: En producción, Firebase usa cuenta de servicio por defecto

---

## PASO 4: Desplegar Reglas de Seguridad

### 4.1 Desplegar Firestore Rules

```bash
# Desde la raíz del proyecto
firebase deploy --only firestore:rules
```

### 4.2 Desplegar Storage Rules

```bash
firebase deploy --only storage:rules
```

### 4.3 Desplegar Índices

```bash
firebase deploy --only firestore:indexes
```

---

## PASO 5: Crear Primer Usuario Admin

### 5.1 Método: Panel Web

Después de desplegar el panel web:

1. Abre el panel admin
2. Logueate con Google (tu cuenta)
3. **No tendrás acceso** todavía (estás pendiente)

### 5.2 Método: Firebase Console (Recomendado)

1. Ve a **Firestore Database**
2. Click **"Iniciar colección"**
3. Collection ID: `users`
4. Document ID: `TU_UID` (tu ID de Firebase Auth)
5. Agregar campos:
```
email: "tu@email.com"
nombre: "Tu"
apellido: "Nombre"
credencial: "0001"
estado: "aprobado"
rol: "admin"
fechaRegistro: timestamp (hoy)
```
6. Click **"Guardar"**

### 5.3 Obtener tu UID

Para obtener tu UID:
1. Logueate con Google en Authentication
2. Tu UID aparece en la lista de usuarios

---

## PASO 6: Desplegar Cloud Functions

### 6.1 Compilar TypeScript

```bash
cd panel_admin/functions
npm run build
```

### 6.2 Desplegar Functions

```bash
firebase deploy --only functions
```

---

## PASO 7: Desplegar Panel Web (Hosting)

### 7.1 Inicializar Firebase Hosting

```bash
firebase init hosting
```

Seleccionar:
- Proyecto: `app-inspectores-trelew`
- Directorio público: `panel_admin/public`
- Configurar como SPA: **No**
- Archivo: `index.html`

### 7.2 Desplegar

```bash
firebase deploy --only hosting
```

---

## PASO 8: Verificar Configuración

### Checklist de Verificación

- [ ] Authentication → Google habilitado
- [ ] Firestore → Database creada
- [ ] Storage → Habilitado
- [ ] Cloud Messaging → Configurado
- [ ] google-services.json → En android/app/
- [ ] Panel web → firebase-config.js actualizado
- [ ] Rules → Desplegadas
- [ ] Functions → Desplegadas
- [ ] Primer admin → Creado en Firestore
- [ ] Panel hosting → Desplegado

---

## 🔗 Links Importantes

- Firebase Console: https://console.firebase.google.com/
- Documentación Firestore: https://firebase.google.com/docs/firestore
- Firebase CLI: https://firebase.google.com/docs/cli
- Groq Console: https://console.groq.com/

---

## ⚠️ Solución de Problemas

### Error: "Permission denied"
- Verificar que tienes permisos de Owner/Editor en el proyecto

### Error: "Functions requires billing"
- Cambiar a plan Blaze (necesario para Cloud Functions)

### Error: "apiKey not valid"
- Verificar firebaseConfig en firebase-config.js

### Error: "Location not available"
- Firestore solo disponible en ciertas regiones
- Usar `southamerica-east1` o `us-central`
