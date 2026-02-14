import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:padelero/features/settings/pro_provider.dart';
import 'package:padelero/services/iap_provider.dart';
import 'package:padelero/services/iap_service.dart';
import 'package:padelero/shared/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final iap = ref.watch(iapServiceProvider);
    final product = iap.products?.where((p) => p.id == kProProductId).firstOrNull;
    final price = product?.price;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Padelero PRO (compra in-app real: Apple / Google)
          Card(
            color: isPro ? AppColors.success.withOpacity(0.15) : AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPro ? Icons.workspace_premium : Icons.star_outline,
                        color: isPro ? AppColors.accent : Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Padelero PRO',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPro
                                  ? 'Sin anuncios · Historial ilimitado'
                                  : 'Sin anuncios, historial ilimitado y más',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isPro) ...[
                    if (kDebugMode)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(isProProvider.notifier).resetPro();
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Restablecer (solo pruebas)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _isPurchasing
                          ? null
                          : () async {
                              setState(() => _isPurchasing = true);
                              try {
                                await iap.purchasePro();
                              } finally {
                                if (mounted) setState(() => _isPurchasing = false);
                              }
                            },
                      icon: _isPurchasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart_checkout, size: 20),
                      label: Text(
                        price != null ? 'Comprar PRO · $price' : 'Comprar PRO',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isRestoring
                          ? null
                          : () async {
                              setState(() => _isRestoring = true);
                              try {
                                await iap.restorePurchases();
                              } finally {
                                if (mounted) setState(() => _isRestoring = false);
                              }
                            },
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore, size: 20),
                      label: const Text('Restaurar compras'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: Text(
              'Versión',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '1.0.0',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.white70),
            title: Text(
              'Tema oscuro',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Por defecto (recomendado en pista)',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
            title: Text(
              'Política de privacidad',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
            onTap: () => _openUrl('https://jaimeavantgarde.github.io/padelero/privacy-policy.html'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.white70),
            title: Text(
              'Términos de uso',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
            onTap: () => _openUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          ),
          const Divider(color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.tagline,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
