import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/widgets/progress_header_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ProgressHeaderCard(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profil', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Nama: ${user?.displayName ?? '-'}'),
                Text(
                  'Status: ${user?.isGuest ?? true ? 'Guest' : 'Terautentikasi'}',
                ),
                if (user?.email != null) Text('Email: ${user!.email}'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
