import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../providers/auth_providers.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  static const routeName = 'auth-gate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue>(authControllerProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null && context.mounted) {
        context.go('/home');
      }
    });

    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const <Color>[
                    TawakkalColors.backgroundDark,
                    Color(0xFF151E1C),
                  ]
                : const <Color>[
                    TawakkalColors.backgroundLight,
                    Color(0xFFE8F1E6),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: TawakkalColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'توكل',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belajar Al-Quran dengan tenang, bertahap, dan bermakna.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TawakkalColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .continueAsGuest();
                        },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Mulai sebagai Guest'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle();
                        },
                  icon: const Icon(Icons.login),
                  label: const Text('Masuk dengan Google'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => _showEmailSignInDialog(context, ref),
                  child: const Text('Masuk dengan Email'),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${state.error}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEmailSignInDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Masuk dengan Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(authControllerProvider.notifier)
                    .signInWithEmail(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Masuk'),
            ),
          ],
        );
      },
    );
  }
}
