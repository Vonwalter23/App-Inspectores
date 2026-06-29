# Mensaje para nueva conversación - App Inspectores v2

## Contexto

Necesito crear una app Android para inspectores de tránsito de Trelew, Chubut, Argentina.

## Proyecto existente

El panel web YA EXISTE y funciona correctamente en:
- Repositorio: https://github.com/Vonwalter23/App-Inspectores
- Panel web: https://vonwalter23.github.io/App-Inspectores/

## Documentación requerida

El archivo `creacionapp.md` en el repositorio GitHub contiene TODAS las instrucciones detalladas:
- URL: https://github.com/Vonwalter23/App-Inspectores/blob/expo-dev/creacionapp.md
- Rama: `expo-dev`

Este archivo incluye:
- Instalación de Java 17
- Instalación de Android SDK
- Pasos para crear proyecto Expo
- Configuración de Firebase
- Errores comunes y soluciones
- Comandos de compilación

## Nueva app a crear

### Datos:
- **Package Name:** `com.municipalidad.trelew.inspectores.v2`
- **Nombre App:** `App Inspectores Trelew v2`
- **Proyecto Firebase:** `inspectores-app`
- **Rama Git:** `app-android-v2`
- **Tecnología:** Expo + React Native + TypeScript + Firebase

### Requisitos:
1. Login con Google (usando @react-native-google-signin/google-signin)
2. Registro de usuarios en Firestore
3. Flujo: Login → Pendiente → Admin aprueba → Home
4. Compatible con panel web existente

## Pasos a seguir:

1. **LEER primero el archivo creacionapp.md** del repositorio
2. Clonar el repositorio o descargar el archivo
3. Seguir las instrucciones paso a paso del archivo
4. Crear nueva rama `app-android-v2`
5. Implementar login con Google
6. Compilar APK con Java 17
7. Probar conexión con panel web

## Credenciales

Las credenciales de Firebase se proporcionarán cuando se creen los proyectos.

## Importante

- Mantener el panel web EXACTAMENTE como está
- NO modificar nada en la rama main/expo-dev
- Trabajar en la nueva rama app-android-v2
- Compilar siempre con Java 17 en servidor

¿Alguna duda? Consulta el archivo creacionapp.md para información detallada.
