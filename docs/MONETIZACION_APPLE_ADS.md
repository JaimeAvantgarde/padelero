# Cómo monetizar Padelero con anuncios (Apple / iOS)

## 1. Anuncios con Google AdMob (iOS y Android)

La app ya tiene integrado **Google Mobile Ads**: banner en Home e interstitial al volver del resumen del partido.

### Pasos para usar tus propios anuncios

1. **Crear cuenta en AdMob**  
   - [admob.google.com](https://admob.google.com)  
   - Inicia sesión con tu cuenta de Google.

2. **Dar de alta la app en AdMob**  
   - En AdMob: Apps → Añadir app.  
   - Elige “iOS” y pon el **Bundle ID** de tu app (ej. `com.tudominio.padelero`).  
   - Repite para Android con el package name de Android.

3. **Crear unidades de anuncios**  
   - **Banner**: en la app → Unidades de anuncios → Añadir unidad → Banner.  
   - **Interstitial**: Añadir unidad → Interstitial.  
   - Copia los **ID de unidad** (ej. `ca-app-pub-1234567890123456/1234567890`).

4. **Poner los IDs en el código**  
   - En `lib/services/ads_service.dart`, en la clase `AdUnitIds`, sustituye los IDs de prueba por los tuyos en la parte de producción (donde pone `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`).  
   - Usa los IDs de **banner** e **interstitial** que te haya dado AdMob para iOS y para Android.

5. **ID de aplicación**  
   - Ya está configurado: `ca-app-pub-5598736675820629~8566662091` en `ios/Runner/Info.plist` (GADApplicationIdentifier) y en `android/app/src/main/AndroidManifest.xml` (com.google.android.gms.ads.APPLICATION_ID).

6. **Banner**  
   - Tipo: Banner. Tamaño: estándar 320x50 (AdSize.banner). Emplazamiento: parte inferior de la pantalla Home.  
   - ID de bloque de anuncios ya configurado: `ca-app-pub-5598736675820629/1355210898` en `lib/services/ads_service.dart` (AdUnitIds.banner).

### Warnings de deprecación en iOS

Si al compilar en Xcode salen avisos de “deprecated” del plugin de AdMob:

- En Xcode: **Build Settings** del target Runner → busca **Other Warning Flags** → añade `-Wno-deprecated-declarations`.  
- O en `ios/Podfile`, dentro del `post_install` del target Runner, añade algo como:  
  `config.build_settings['OTHER_CFLAGS'] = '$(inherited) -Wno-deprecated-declarations'`  
  (según cómo tengas el Podfile).

Así la compilación no falla por esos warnings.

---

## 2. Requisitos de Apple para apps con anuncios

### App Tracking Transparency (ATT) – iOS 14.5+

Si en el futuro usas redes que rastrean para publicidad (por ejemplo algunos tipos de AdMob), Apple exige pedir permiso al usuario.

1. **Añadir la clave en Info.plist**  
   En `ios/Runner/Info.plist` añade (si aún no está):

   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>Usamos los datos para mostrarte anuncios más relevantes y mejorar la app.</string>
   ```

2. **Pedir permiso en código**  
   Antes de cargar anuncios que usen IDFA, puedes usar el paquete `app_tracking_transparency` y llamar a `requestTrackingAuthorization()`.  
   Para solo banner/interstitial básicos con los IDs de prueba o sin personalización por IDFA, no es obligatorio pedir ATT al inicio; cuando quieras maximizar ingresos con segmentación, entonces sí.

### Política de privacidad

- Apple y AdMob pueden pedir una **URL de política de privacidad** que explique que usas anuncios (AdMob) y qué datos recoges.  
- Crea una página web (o sección en tu web) con la política y pon esa URL en App Store Connect y en la configuración de AdMob.

---

## 3. Publicar en App Store (Apple)

1. **Cuenta de desarrollador**  
   - [developer.apple.com](https://developer.apple.com) → cuenta de Apple Developer (99 €/año).

2. **App Store Connect**  
   - Crea una nueva app, Bundle ID igual al del proyecto (ej. `com.tudominio.padelero`).  
   - Rellena nombre, descripción, capturas, etc.

3. **Subir la app**  
   - En tu Mac: `flutter build ipa`.  
   - Abre **Transporter** (o Xcode → Organizer) y sube el `.ipa` a App Store Connect.

4. **Envío a revisión**  
   - En App Store Connect, rellena todo lo que pida (privacidad, anuncios, etc.) y envía a revisión.  
   - Si usas ATT, asegúrate de que el texto de `NSUserTrackingUsageDescription` coincida con lo que hace la app.

---

## 4. Dónde se muestran los anuncios en Padelero

- **Banner**: parte inferior de la pantalla **Home** (siempre que la unidad de anuncios esté activa).  
- **Interstitial**: al pulsar “Inicio” o la “X” en la pantalla de **Resumen** del partido (después de terminar un partido).

Para no mostrar anuncios a usuarios de pago (versión PRO), en el futuro puedes comprobar si el usuario tiene PRO y, en ese caso, no llamar a `AdsService.showInterstitialIfLoaded()` ni mostrar el `AdBannerWidget`.

---

## 5. Resumen rápido

| Paso | Dónde |
|------|--------|
| Cuenta AdMob | admob.google.com |
| Crear app iOS/Android en AdMob | Panel AdMob → Apps |
| Crear unidades Banner e Interstitial | Panel AdMob → tu app → Unidades |
| Poner IDs en código | `lib/services/ads_service.dart` → `AdUnitIds` |
| Poner App ID en iOS | `ios/Runner/Info.plist` → `GADApplicationIdentifier` |
| Silenciar warnings iOS (opcional) | Xcode Build Settings o Podfile |
| Política de privacidad | Web + URL en App Store Connect y AdMob |
| Subir a Apple | `flutter build ipa` + Transporter |

Cuando cambies los IDs de prueba por los reales, la app empezará a mostrar tus anuncios y podrás ver estadísticas e ingresos en el panel de AdMob.
