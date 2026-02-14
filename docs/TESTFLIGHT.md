# Subir Padelero App a TestFlight (iOS)

## 0. Crear la app en App Store Connect (solo la primera vez)

Para poder subir el build, la app debe existir en App Store Connect con el **mismo Bundle ID** que el proyecto:

1. Entra en [App Store Connect](https://appstoreconnect.apple.com) → **Mis apps** → **+** → **Nueva app**.
2. **Plataformas:** iOS.
3. **Nombre:** **Padelero App** (este nombre debe ser único en la App Store).
4. **Idioma principal:** Español (o el que prefieras).
5. **Id. de paquete de la app:** selecciona **app.padelero** (debe coincidir con el Bundle Identifier de Xcode).
6. **ID de SKU:** puede ser `padelero-app-001` o cualquier identificador interno único.
7. Crea la app. Ya puedes subir el archivo desde Xcode.

## 1. Abrir en Xcode

El proyecto ya está configurado para abrir en Xcode:

```bash
open ios/Runner.xcworkspace
```

(Siempre abre el `.xcworkspace`, no el `.xcodeproj`, para que CocoaPods esté bien resuelto.)

## 2. Icono de la app

El icono de la app (logo Padelero) está configurado en:

- **`ios/Runner/Assets.xcassets/AppIcon.appiconset/`**
  - `Icon-App-1024x1024@1x.png` — icono 1024×1024 (generado desde tu SVG).
  - `Contents.json` — configurado en modo “Single Size” (solo 1024×1024).

El SVG original está en **`assets/images/logo.svg`** por si quieres reexportar el icono más adelante.

## 3. Antes de archivar

En Xcode:

1. **Selecciona el target Runner** y revisa:
   - **Signing & Capabilities:** equipo de desarrollo y perfil de distribución (Automático o manual).
   - **Bundle Identifier:** `app.padelero` (debe coincidir con el id. de paquete en App Store Connect).
   - **Version / Build:** coherentes con lo que quieras subir (ej. 1.0.0 / 1).

2. **Selecciona “Any iOS Device (arm64)”** como destino (no un simulador).

3. **Product → Archive.**

## 4. Después del Archive

1. Se abrirá el **Organizer** con el archivo recién creado.
2. Pulsa **Distribute App**.
3. Elige **App Store Connect** → **Upload**.
4. Sigue el asistente (opciones por defecto suelen ser válidas).
5. Cuando termine la subida, en [App Store Connect](https://appstoreconnect.apple.com) → tu app → **TestFlight** aparecerá el build al cabo de unos minutos (procesamiento).

## 5. TestFlight

1. En App Store Connect → **TestFlight**.
2. En el build recién procesado:
   - Añade **información de exportación** si te lo pide.
   - **Probar en el exterior** (opcional): rellena los datos y envía a revisión de beta.
   - **Probar en el interior:** añade probadores internos (cuenta de desarrollador).
3. Los probadores reciben la invitación por correo o desde la app TestFlight.

## 6. Build desde terminal (opcional)

```bash
cd /Users/jaimeparejaarco/Desktop/padelero
flutter build ipa
```

El `.ipa` estará en `build/ios/ipa/`. Luego puedes subirlo con **Transporter** (App Store) o abrir el `.xcarchive` en Xcode y usar **Distribute App** como arriba.

---

**Resumen:** Crea la app en App Store Connect con nombre **Padelero App** y id. de paquete **app.padelero**. Luego abre `ios/Runner.xcworkspace` en Xcode, revisa firma y Bundle ID `app.padelero`, haz **Product → Archive**, **Distribute App** → App Store Connect → Upload. Configura probadores en TestFlight.
