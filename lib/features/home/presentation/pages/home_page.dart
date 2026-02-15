import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../audio/presentation/pages/audio_page.dart';
import '../../../audio/presentation/widgets/persistent_mini_player.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../learning/presentation/pages/learning_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../quran/presentation/pages/surah_list_page.dart';
import '../widgets/tawakkal_bottom_dock_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialTabIndex = 0});

  static const routeName = 'home';
  final int initialTabIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final GlobalKey _bodyContentKey = GlobalKey();
  final GlobalKey _bottomChromeKey = GlobalKey();
  bool _isOverlapMeasureScheduled = false;
  double _belajarBottomOverlayOverlap = 0;

  @override
  void initState() {
    super.initState();
    _index = _coerceTabIndex(widget.initialTabIndex);
    _scheduleBottomOverlayOverlapMeasurement();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      setState(() {
        _index = _coerceTabIndex(widget.initialTabIndex);
      });
      _scheduleBottomOverlayOverlapMeasurement();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleBottomOverlayOverlapMeasurement();
  }

  void _selectTab(int index) {
    if (_index == index) {
      return;
    }
    setState(() {
      _index = _coerceTabIndex(index);
    });
    _scheduleBottomOverlayOverlapMeasurement();
  }

  void _scheduleBottomOverlayOverlapMeasurement() {
    if (_isOverlapMeasureScheduled) {
      return;
    }
    _isOverlapMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isOverlapMeasureScheduled = false;
      _recalculateBottomOverlayOverlap();
    });
  }

  void _recalculateBottomOverlayOverlap() {
    if (!mounted) {
      return;
    }

    final bodyContext = _bodyContentKey.currentContext;
    final bottomChromeContext = _bottomChromeKey.currentContext;
    if (bodyContext == null || bottomChromeContext == null) {
      return;
    }

    final bodyObject = bodyContext.findRenderObject();
    final bottomChromeObject = bottomChromeContext.findRenderObject();
    if (bodyObject is! RenderBox || bottomChromeObject is! RenderBox) {
      return;
    }
    if (!bodyObject.hasSize || !bottomChromeObject.hasSize) {
      return;
    }

    final bodyTop = bodyObject.localToGlobal(Offset.zero).dy;
    final bodyBottom = bodyTop + bodyObject.size.height;
    final bottomChromeTop = bottomChromeObject.localToGlobal(Offset.zero).dy;
    final overlap = math.max(0.0, bodyBottom - bottomChromeTop);

    if ((overlap - _belajarBottomOverlayOverlap).abs() <= 0.5) {
      return;
    }

    setState(() {
      _belajarBottomOverlayOverlap = overlap;
    });
  }

  int _coerceTabIndex(int index) {
    if (index < 0) {
      return 0;
    }
    if (index > 4) {
      return 4;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: isDark
                  ? Colors.black
                  : TawakkalColors.backgroundLight,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: isDark
                  ? Colors.black
                  : TawakkalColors.backgroundLight,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SizedBox.expand(
          key: _bodyContentKey,
          child: Stack(
            children: [
              RichPageBackground(
                child: ScrollConfiguration(
                  behavior: const _HomeTabScrollBehavior(),
                  child: IndexedStack(
                    index: _index,
                    children: [
                      DashboardPage(onSelectTab: _selectTab),
                      const _QuranTab(),
                      _TabPage(
                        title: 'Belajar',
                        child: LearningPage(
                          bottomOverlayOverlap: _belajarBottomOverlayOverlap,
                        ),
                      ),
                      const _TabPage(
                        title: 'Audio',
                        showHeader: false,
                        child: AudioPage(),
                      ),
                      const _TabPage(title: 'Profil', child: ProfilePage()),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.viewPaddingOf(context).top,
                child: ColoredBox(
                  color: isDark ? Colors.black : TawakkalColors.backgroundLight,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _scheduleBottomOverlayOverlapMeasurement();
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: Column(
                  key: _bottomChromeKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PersistentMiniPlayer(
                      onOpenPlayer: () {
                        _selectTab(3);
                      },
                    ),
                    TawakkalBottomDockNav(
                      selectedIndex: _index,
                      onSelected: _selectTab,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _HomeTabScrollBehavior extends MaterialScrollBehavior {
  const _HomeTabScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _QuranTab extends StatelessWidget {
  const _QuranTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(bottom: false, child: SurahListPage());
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
