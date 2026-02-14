# Configurar compras in-app (PRO) en Apple y Google

La app usa el paquete oficial `in_app_purchase` y un **producto no consumible** con ID:

- **`padelero_pro`**

Ese mismo ID debe existir en App Store Connect (iOS) y en Google Play Console (Android). El precio y la moneda los defines en cada tienda.

---

## 1. Apple (App Store Connect)

1. Entra en [App Store Connect](https://appstoreconnect.apple.com) → tu app → **Funcionalidades** → **Compras in-app**.
2. Crea un producto:
   - **Tipo:** Compras in-app (no consumible).
   - **ID de referencia del producto:** `padelero_pro` (exactamente igual).
   - **Precio:** el que quieras (ej. 2,99 €).
3. Rellena nombre y descripción según los requisitos de Apple.
4. En **Acuerdos, impuestos y banca** asegúrate de tener un **Acuerdo de ventas de apps de pago** activo y la banca configurada.
5. Para probar en desarrollo:
   - En el dispositivo/simulador usa una cuenta de **Sandbox** (no tu Apple ID personal).
   - Crea una en: App Store Connect → **Usuarios y acceso** → **Sandbox** → **Probadores**.

Documentación: [In-App Purchase (Apple)](https://developer.apple.com/in-app-purchase/).

---

## 2. Google (Google Play Console)

1. Entra en [Google Play Console](https://play.google.com/console) → tu app → **Monetización** → **Productos** → **Compras en la aplicación**.
2. Crea un producto:
   - **Tipo:** Producto gestionado (no consumible).
   - **ID del producto:** `padelero_pro` (exactamente igual).
   - **Nombre** y **descripción** según requisitos de Google.
   - **Precio:** el que quieras (ej. 2,99 €).
3. Activa el producto cuando esté listo.
4. Para probar:
   - Añade tu cuenta de Gmail como **probador de licencias** en la pestaña de pruebas del producto.
   - O usa una cuenta añadida a la lista de **probadores internos** de la app.

Documentación: [Ventas en la aplicación (Google)](https://support.google.com/googleplay/android-developer/answer/1153481).

---

## 3. En la app (ya implementado)

- **Comprar PRO:** abre el flujo nativo de pago (Apple o Google) con el producto `padelero_pro`.
- **Restaurar compras:** llama a la tienda para recuperar compras anteriores (cambio de dispositivo o reinstalación). Si existe una compra de `padelero_pro`, se activa PRO de nuevo.
- Al abrir la app se llama a **restore** en segundo plano; si el usuario ya compró PRO, se activa sin hacer nada.

---

## 4. Resumen

| Dónde              | Qué hacer |
|--------------------|-----------|
| App Store Connect  | Crear producto no consumible con ID `padelero_pro`. |
| Google Play Console | Crear producto gestionado con ID `padelero_pro`. |
| Código             | ID definido en `lib/services/iap_service.dart` → `kProProductId = 'padelero_pro'`. |

Si en el futuro quieres suscripciones (ej. mensual/anual), crea productos de tipo suscripción en cada tienda y en el código usa `buyNonConsumable` para compra única o la API de suscripciones del paquete `in_app_purchase` para renovables.

---

## 5. Probar la compra en TestFlight (sin dinero real)

**Sí:** cuando subes la app a TestFlight, las compras in-app usan el entorno **Sandbox** de Apple. No se cobra dinero real.

- Tú (o los probadores) instaláis la app desde TestFlight.
- Al pulsar **Comprar PRO**, aparece el diálogo de pago de Apple pidiendo iniciar sesión: ahí hay que usar una **cuenta Sandbox**, no tu Apple ID normal.
- Crear cuenta Sandbox: [App Store Connect](https://appstoreconnect.apple.com) → **Usuarios y acceso** → **Sandbox** → **Probadores** → **+** (crear probador). Usa un email que no esté asociado a ningún Apple ID real (puede ser ficticio tipo `test1@tudominio.com`).
- En el iPhone: **Ajustes** → **App Store** → al final, **Cuenta Sandbox** (solo aparece si has intentado una compra en una app que usa Sandbox). Inicia sesión con esa cuenta Sandbox.
- La “compra” en TestFlight se procesa en Sandbox: ves el flujo completo (precio, confirmación, activación de PRO) pero **no se cobra nada**. Así compruebas que todo funciona antes de publicar.

Cuando la app esté **en la App Store** (versión en producción), las mismas compras pasan a ser reales y sí se cobra a los usuarios.

---

## 6. ¿Dónde me llega el dinero? (Apple)

El dinero de las compras in-app (y de la venta de la app, si la tienes de pago) te lo paga **Apple** a tu **cuenta bancaria**.

1. **Configuración obligatoria** (si aún no lo has hecho):
   - [App Store Connect](https://appstoreconnect.apple.com) → **Acuerdos, impuestos y banca**.
   - **Acuerdo de ventas de apps de pago:** firmado y activo.
   - **Información bancaria:** cuenta bancaria (IBAN, etc.) a la que quieres recibir los pagos.
   - **Información fiscal:** formulario (por ejemplo W-8BEN si estás fuera de EE. UU.) para impuestos.

2. **Dónde ver el dinero:**
   - **Ventas e ingresos:** App Store Connect → **Ventas y tendencias** (o **Apps** → tu app → **Actividad**).
   - **Pagos programados y recibidos:** App Store Connect → **Pagos e informes financieros** (o **Acuerdos, impuestos y banca** → **Pagos**). Ahí ves cuánto te debe Apple y cuándo se hará el pago.

3. **Cuándo te pagan:**
   - Apple suele pagar **una vez al mes** (por ejemplo, unos 45 días después del cierre del mes en el que se generaron las ventas).
   - El ingreso llega a la **cuenta bancaria** que hayas dado (transferencia / SEPA, etc.).

En resumen: el dinero va de los usuarios → Apple → tu banco. Todo se gestiona desde App Store Connect una vez que tienes acuerdo, banco y fiscalidad configurados.
