# SISTEMA INTEGRAL PARA INSPECTORES DE TRÁNSITO DE TRELEW

## DESCRIPCIÓN
Sistema completo para la gestión de inspectores de tránsito de la Municipalidad de Trelew, Chubut, Argentina.

## COMPONENTES
- App Android (Flutter) - Para inspectores
- Panel Web Admin (Firebase Hosting) - Para administradores  
- Backend Firebase Cloud Functions - Lógica serverless

## ROLES
- INSPECTOR (Android): Login, Chat IA, Mensajería, Geolocalización
- ADMIN (Web): Gestión usuarios, Documentos, Mapa, Logs

## TECNOLOGÍAS
- Flutter 3.16+ / Dart 3.2+
- Firebase (Auth, Firestore, Functions, FCM, Storage, Hosting)
- Groq API (Chat IA con RAG)
- Google Maps API
- Google Drive API

## CONFIGURACIÓN
Ver AGENTE.md para credenciales y configuración detallada.

## DESPLIEGUE
```bash
# Flutter
cd app_inspectores
flutter pub get
flutter build apk --debug

# Firebase
firebase deploy
```

## COSTOS ESTIMADOS: $0-5/mes

## LICENCIA
Propiedad de la Municipalidad de Trelew

## SOPORTE
Email: soporte@trelew.gob.ar
Teléfono: 0800-XXX-XXXX
Horario: Lunes a Viernes 8:00 - 14:00
