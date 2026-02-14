import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padelero/features/settings/pro_provider.dart';
import 'package:padelero/services/iap_service.dart';

final iapServiceProvider = Provider<IapService>((ref) {
  final proNotifier = ref.read(isProProvider.notifier);
  final service = IapService(proNotifier);
  ref.onDispose(() => service.dispose());
  return service;
});
