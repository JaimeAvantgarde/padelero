import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kProKey = 'padelero_pro';

/// Provider de SharedPreferences para persistir el estado PRO.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in main.dart (runApp before)',
  );
});

/// Estado PRO: sin anuncios, historial ilimitado, etc.
/// Por ahora es una simulación de compra (guardado local).
final isProProvider = StateNotifierProvider<ProNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProNotifier(prefs);
});

class ProNotifier extends StateNotifier<bool> {
  ProNotifier(this._prefs) : super(_prefs.getBool(_kProKey) ?? false);

  final SharedPreferences _prefs;

  /// Activa o desactiva PRO (persiste en local).
  /// Lo llama IapService cuando la compra se completa o se restaura.
  Future<void> setPro(bool value) async {
    await _prefs.setBool(_kProKey, value);
    state = value;
  }

  /// Solo para pruebas: restablece PRO sin reembolso.
  Future<void> resetPro() async {
    await setPro(false);
  }
}
