import 'package:flutter/material.dart';

import '../../../audio/presentation/pages/audio_page.dart';
import '../../../audio/presentation/widgets/persistent_mini_player.dart';
import '../../../learning/presentation/pages/learning_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../progress/presentation/widgets/progress_header_card.dart';
import '../../../quran/presentation/pages/surah_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Quran', 'Murottal', 'Belajar', 'Profil'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(
        index: _index,
        children: const [
          _QuranTab(),
          AudioPage(),
          LearningPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersistentMiniPlayer(
            onOpenPlayer: () {
              setState(() {
                _index = 1;
              });
            },
          ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) {
              setState(() {
                _index = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Quran',
              ),
              NavigationDestination(
                icon: Icon(Icons.headphones_outlined),
                selectedIcon: Icon(Icons.headphones),
                label: 'Audio',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Belajar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuranTab extends StatelessWidget {
  const _QuranTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: ProgressHeaderCard(),
        ),
        Expanded(child: SurahListPage()),
      ],
    );
  }
}
