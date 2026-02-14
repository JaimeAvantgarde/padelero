import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:padelero/features/settings/pro_provider.dart';

/// ID del producto en App Store Connect y Google Play Console.
/// Debe coincidir exactamente con el que crees en ambas tiendas.
const String kProProductId = 'padelero_pro';

/// Servicio de compras in-app (Apple / Google).
/// Actualiza ProNotifier cuando la compra se completa o se restaura.
class IapService {
  IapService(this._proNotifier) {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('IapService purchaseStream error: $e'),
    );
  }

  final ProNotifier _proNotifier;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final InAppPurchase _iap = InAppPurchase.instance;

  /// Productos disponibles (precio, nombre). Null hasta que se carguen.
  List<ProductDetails>? products;

  /// Inicializa y comprueba compras anteriores (restore al abrir app).
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    await _loadProducts();
    await _checkPastPurchases();
  }

  Future<void> _loadProducts() async {
    try {
      const ids = <String>{kProProductId};
      final response = await _iap.queryProductDetails(ids);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IapService: products not found: ${response.notFoundIDs}');
      }
      products = response.productDetails;
    } catch (e) {
      debugPrint('IapService loadProducts error: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != kProProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _proNotifier.setPro(true);
          if (purchase.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('IapService purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  /// Comprueba compras anteriores (al iniciar app o tras restaurar).
  Future<void> _checkPastPurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
      // El resultado llega por purchaseStream y actualiza _proNotifier
    } catch (e) {
      debugPrint('IapService checkPastPurchases error: $e');
    }
  }

  /// Lanza el flujo de compra de PRO (Apple/Google).
  /// Muestra el diálogo nativo de pago.
  Future<bool> purchasePro() async {
    if (!await _iap.isAvailable()) return false;
    if (products == null || products!.isEmpty) await _loadProducts();
    final product = products?.where((p) => p.id == kProProductId).firstOrNull;
    if (product == null) return false;

    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restaurar compras (cambio de dispositivo o reinstalación).
  Future<void> restorePurchases() async {
    if (!await _iap.isAvailable()) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
