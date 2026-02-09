import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../audio/presentation/pages/audio_page.dart';
import '../../../audio/presentation/widgets/persistent_mini_player.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../learning/presentation/pages/learning_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../progress/presentation/widgets/progress_header_card.dart';
import '../../../quran/presentation/pages/surah_list_page.dart';
import '../widgets/tawakkal_bottom_dock_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _selectTab(int index) {
    if (_index == index) {
      return;
    }
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(onSelectTab: _selectTab),
          const _QuranTab(),
          const _TabPage(title: 'Belajar', child: LearningPage()),
          const _TabPage(title: 'Audio', showHeader: false, child: AudioPage()),
          const _TabPage(title: 'Profil', child: ProfilePage()),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersistentMiniPlayer(
            onOpenPlayer: () {
              _selectTab(3);
            },
          ),
          TawakkalBottomDockNav(selectedIndex: _index, onSelected: _selectTab),
        ],
      ),
    );
  }
}

class _QuranTab extends StatelessWidget {
  const _QuranTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: const [
          _SectionHeader(title: 'Quran'),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: ProgressHeaderCard(),
          ),
          Expanded(child: SurahListPage()),
        ],
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({
    required this.title,
    required this.child,
    this.showHeader = true,
  });

  final String title;
  final Widget child;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (showHeader) _SectionHeader(title: title),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
