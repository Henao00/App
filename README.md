# 📱 T&M — Cotizador de Porones

App móvil (Android & iOS) en **Flutter** para cotizar materiales de construcción
en Colombia, con **PDF profesional**, historial de seguimiento y funciona 100% offline.

---

## 🚀 Requisitos y ejecución

- **Flutter 3.35+** (probado con 3.47) — https://flutter.dev/docs/get-started/install
- Android Studio o VS Code con la extensión Flutter
- Para iOS: macOS + Xcode

```bash
flutter pub get         # dependencias
flutter run             # ejecutar en dispositivo/emulador
flutter analyze         # análisis estático
flutter test            # pruebas unitarias
flutter build apk --release
flutter build ios --release
```

APK de salida: `build/app/outputs/flutter-apk/app-release.apk`

---

## ✨ Funcionalidades

| Módulo | Descripción |
|--------|-------------|
| 🚀 Onboarding | Introducción de 3 pasos solo la primera vez |
| 🏠 Inicio (dashboard) | Métricas (total, este mes, promedio), precios, últimas cotizaciones |
| 📋 Cotizar | Catálogo filtrable + búsqueda; carrito; cálculo `m³ = m² × grosor` |
| 🧱 Materiales | Porones (m²/m³), cemento, arena, varilla por diámetro, ladrillo, bloque, pintura, estuco, variables propios |
| 📁 Historial | Búsqueda, filtro por mes, orden, **detalle con materiales**, estados (borrador/enviada/aceptada/rechazada) |
| 🔁 Duplicar | Repetir una cotización existente en un toque |
| 🖨️ PDF | Con precios o solo lista de materiales, con marca de empresa |
| 📤 Compartir | PDF por WhatsApp/correo, exportar historial a **CSV**, respaldo JSON |
| ⚙️ Config | Precios por material, materiales propios, **datos de empresa**, respaldo, borrar historial |

---

## 📐 Fórmula de conversión

```
Volumen (m³) = Área de la plancha (m²) × Grosor del porón (m)

Ejemplo:  50 m² × 0.25 m = 12.5 m³
```

El grosor es configurable por cotización (chips: 20/25/30/35/40 cm) y tiene un
valor por defecto editable en Configuración.

---

## 🏗️ Arquitectura

Arquitectura por capas, estado local con `setState` (sin dependencias de gestión
de estado) y persistencia detrás de una interfaz para poder migrar a la nube.

```
lib/
  main.dart                     ← arranque, onboarding-gate y navegación
  models/
    cotizacion.dart             ← Cotizacion, MaterialItem, MaterialPreset, AppPrecios, estado
    empresa.dart                ← datos de la empresa (marca del PDF)
  services/
    storage_service.dart        ← TmStore (interfaz) + StorageService (SharedPreferences)
    pdf_service.dart            ← generación/compartición de PDF
  utils/
    formatters.dart             ← formato y parseo es-CO centralizados
  widgets/widgets.dart          ← TmCard, TmInput, TmButton, TmBadge, TmEmptyState…
  screens/
    onboarding_screen.dart
    home_screen.dart
    cotizador_screen.dart
    historial_screen.dart
    config_screen.dart
test/                           ← pruebas unitarias (modelos, storage, formateo)
```

**Preparado para la nube:** las pantallas dependen de la interfaz `TmStore`.
Basta con crear una implementación (Firebase/Supabase) y sustituirla en la
construcción, sin tocar la UI.

---

## 🔐 Firma de producción (Android)

Por defecto compila con la firma de *debug*. Para firmar de verdad:

1. Copia `android/key.properties.example` a `android/key.properties`.
2. Genera un keystore y completa los datos:

```bash
keytool -genkey -v -keystore %USERPROFILE%\tm-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tm
```

`applicationId` / `namespace`: **com.tm.porones**. `key.properties` y los
`.jks`/`.keystore` están en `.gitignore`.

---

## 💰 Modelo comercial (propuesta)

| Plan | Incluye |
|------|---------|
| **Free** | Historial local, PDF básico, catálogo |
| **Pro** | Marca propia sin restricción, export CSV/Excel, métricas, clientes ilimitados, respaldo en nube |
| **Empresa** | Multi-usuario, catálogo de precios compartido, roles |

---

## 🔮 Roadmap

- ☁️ Sincronización en la nube + autenticación (usando `TmStore`)
- 💾 Copias de seguridad automáticas
- 📊 Reportes avanzados y exportación a Excel
- 🎨 Tema claro (la identidad actual es oscura por diseño)
- 🤖 Estimación de materiales desde una descripción de obra

---

## 📦 Dependencias

```yaml
shared_preferences   # almacenamiento local offline
google_fonts         # tipografías Syne + DM Sans
pdf + printing       # generación, impresión y compartir PDF
intl                 # formato de moneda/fecha es-CO
uuid                 # IDs únicos
share_plus           # compartir CSV y respaldos
```
