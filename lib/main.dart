import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:padelero/app/router.dart';
import 'package:padelero/app/theme.dart';
import 'package:padelero/features/settings/pro_provider.dart';
import 'package:padelero/services/ads_service.dart';
import 'package:padelero/services/iap_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Solicitar ATT antes de inicializar anuncios (obligatorio en iOS 14.5+)
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // Pequeña pausa para que la app termine de renderizar
      await Future.delayed(const Duration(milliseconds: 500));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  await AdsService.initialize();
  AdsService.loadInterstitial();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const IapInitializer(child: PadeleroApp()),
    ),
  );
}

/// Inicializa IAP al arranque y restaura compras anteriores.
class IapInitializer extends ConsumerStatefulWidget {
  const IapInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IapInitializer> createState() => _IapInitializerState();
}

class _IapInitializerState extends ConsumerState<IapInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class PadeleroApp extends ConsumerWidget {
  const PadeleroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Padelero',
      debugShowCheckedModeBanner: false,
      theme: appDarkTheme,
      routerConfig: router,
    );
  }
}
