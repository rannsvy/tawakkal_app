import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// HTML Colors
const Color _primaryPurple = Color(0xFFA855F7);
const Color _gold = Color(0xFFD97706);
const Color _cream = Color(0xFFFEF3C7);
const Color _bgLight = Color(0xFFFAFAFA);
const Color _bgDark = Color(0xFF000000);
const Color _surfaceDark = Color(0xFF121212);

class UniversalLoadingView extends StatefulWidget {
  const UniversalLoadingView({
    super.key,
    this.message = 'Preparing your daily path',
    this.progress,
    this.primaryIcon = Icons.bedtime_rounded,
    this.showPercentage = true,
    this.padding = const EdgeInsets.all(24),
    this.randomSeed,
  });

  final String message;
  final double? progress;
  final IconData primaryIcon;
  final bool showPercentage;
  final EdgeInsetsGeometry padding;
  final int? randomSeed;

  @override
  State<UniversalLoadingView> createState() => _UniversalLoadingViewState();
}

class _UniversalLoadingViewState extends State<UniversalLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;

  Timer? _messageTimer;
  int _messageIndex = 0;
  late math.Random _random;
  late List<String> _taskMessages;
  late String _dailyTip;

  @override
  void initState() {
    super.initState();

    // Rotation takes 3 seconds
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Pulse animation takes 1.5 seconds
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Message fade transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Fully visible initially
    );

    _random = widget.randomSeed == null
        ? math.Random()
        : math.Random(widget.randomSeed);
    _refreshTaskContent(resetMessageIndex: true);
    _startMessageTimer();
  }

  @override
  void didUpdateWidget(covariant UniversalLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final seedChanged = oldWidget.randomSeed != widget.randomSeed;
    final messageChanged = oldWidget.message != widget.message;
    if (!seedChanged && !messageChanged) {
      return;
    }

    if (seedChanged) {
      _random = widget.randomSeed == null
          ? math.Random()
          : math.Random(widget.randomSeed);
    }

    _refreshTaskContent(resetMessageIndex: true);
    _startMessageTimer();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startMessageTimer() {
    _messageTimer?.cancel();
    if (_taskMessages.length <= 1) {
      return;
    }

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _fadeController.reverse().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _messageIndex = (_messageIndex + 1) % _taskMessages.length;
        });
        _fadeController.forward();
      });
    });
  }

  void _refreshTaskContent({required bool resetMessageIndex}) {
    final taskContent = _resolveTaskContent(widget.message);
    _taskMessages = _dedupeMessages(taskContent.messages);
    if (_taskMessages.isEmpty) {
      _taskMessages = <String>[widget.message];
    }
    if (resetMessageIndex) {
      _messageIndex = 0;
    }
    _dailyTip = taskContent.tips[_random.nextInt(taskContent.tips.length)];
  }

  List<String> _dedupeMessages(List<String> messages) {
    final seen = <String>{};
    final deduped = <String>[];
    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      deduped.add(trimmed);
    }
    return deduped;
  }

  _TaskContent _resolveTaskContent(String taskMessage) {
    final normalized = taskMessage.toLowerCase();
    final isIndonesian =
        normalized.contains('menyiapkan') ||
        normalized.contains('hasil') ||
        normalized.contains('ayat');

    if (normalized.contains('quiz')) {
      return _TaskContent(
        messages: <String>[
          taskMessage,
          isIndonesian
              ? 'Menyusun pertanyaan berdasarkan ayat terpilih...'
              : 'Building quiz questions from selected ayat...',
          isIndonesian
              ? 'Menyiapkan feedback AI yang relevan...'
              : 'Preparing relevant AI feedback...',
          isIndonesian
              ? 'Menata alur kuis agar tetap seimbang...'
              : 'Balancing question flow for better pacing...',
        ],
        tips: <String>[
          isIndonesian
              ? 'Baca ayat sampai selesai sebelum memilih jawaban.'
              : 'Read the full ayah context before choosing an answer.',
          isIndonesian
              ? 'Tandai kata kunci ayat untuk mempercepat analisis pilihan.'
              : 'Use key terms from the ayah to narrow answer options.',
          isIndonesian
              ? 'Utamakan jawaban yang paling sesuai konteks ayat.'
              : 'Prioritize answers that best match the ayah context.',
        ],
      );
    }

    if (normalized.contains('finaliz') || normalized.contains('hasil')) {
      return _TaskContent(
        messages: <String>[
          taskMessage,
          isIndonesian
              ? 'Menghitung skor dan merangkum jawaban...'
              : 'Calculating your score and summary...',
          isIndonesian
              ? 'Merapikan insight belajar berbasis AI...'
              : 'Refining AI-powered study insights...',
        ],
        tips: <String>[
          isIndonesian
              ? 'Perhatikan pola salah untuk menentukan fokus belajar berikutnya.'
              : 'Review repeated mistakes to choose your next focus area.',
          isIndonesian
              ? 'Fokus pada ayat yang belum konsisten sebelum lanjut ke level berikutnya.'
              : 'Revisit ayat you missed before moving to harder levels.',
          isIndonesian
              ? 'Jaga ritme latihan singkat tapi konsisten setiap hari.'
              : 'Short, consistent review sessions build stronger retention.',
        ],
      );
    }

    if (normalized.contains('audio') ||
        normalized.contains('download') ||
        normalized.contains('unduh')) {
      return const _TaskContent(
        messages: <String>[
          'Preparing audio resources...',
          'Optimizing recitation stream quality...',
          'Finalizing offline playback support...',
        ],
        tips: <String>[
          'Download your most-played surahs first for smoother offline listening.',
          'Use one reciter consistently to improve memorization rhythm.',
          'Replaying short ranges often helps lock pronunciation patterns.',
        ],
      );
    }

    return _TaskContent(
      messages: <String>[
        taskMessage,
        isIndonesian
            ? 'Menyinkronkan progres belajar di latar belakang...'
            : 'Syncing your learning progress in the background...',
        isIndonesian
            ? 'Menyiapkan tampilan berikutnya...'
            : 'Preparing the next screen...',
      ],
      tips: <String>[
        isIndonesian
            ? 'Konsistensi harian kecil lebih efektif daripada sesi panjang yang jarang.'
            : 'Small daily consistency beats occasional long sessions.',
        isIndonesian
            ? 'Ulangi ayat yang sama beberapa kali untuk memperkuat pemahaman.'
            : 'Repeat the same ayah a few times to strengthen recall.',
        isIndonesian
            ? 'Gunakan terjemahan sebagai penguat makna, bukan pengganti tadabbur.'
            : 'Use translations to support meaning, not replace reflection.',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? _bgDark : _bgLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox.expand(
        key: const Key('universal-loading-root'),
        child: Stack(
          children: [
            // Background subtle pulses
            const _BackgroundPulses(),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: widget.padding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Particle Loading Orb
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _rotationController,
                            _pulseController,
                          ]),
                          builder: (context, child) {
                            return _LoadingOrbit(
                              rotationValue: _rotationController.value,
                              pulseValue: _pulseController.value,
                            );
                          },
                        ),
                        const SizedBox(height: 64),

                        // Cycling Text
                        AnimatedBuilder(
                          animation: _fadeController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeController.value,
                              child: Text(
                                _taskMessages[_messageIndex],
                                key: const Key('universal-loading-message'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                  color: isDark ? _cream : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Daily Tip Glassmorphism Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? _surfaceDark
                                : Colors.white.withValues(alpha: 0.5),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_rounded,
                                    color: _gold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DAILY TIP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _dailyTip,
                                key: const Key('universal-loading-daily-tip'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Version and Status
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  'v2.4.0 • Connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskContent {
  const _TaskContent({required this.messages, required this.tips});

  final List<String> messages;
  final List<String> tips;
}

// Background animated pulses as seen in the absolute HTML layer
class _BackgroundPulses extends StatefulWidget {
  const _BackgroundPulses();

  @override
  State<_BackgroundPulses> createState() => _BackgroundPulsesState();
}

class _BackgroundPulsesState extends State<_BackgroundPulses>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Opacity(
            opacity: 0.2,
            child: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: 40,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _primaryPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 200,
                  right: 60,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _pulseController.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 150,
                  left: 80,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 1.0 - _pulseController.value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: _primaryPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadingOrbit extends StatelessWidget {
  const _LoadingOrbit({required this.rotationValue, required this.pulseValue});

  final double rotationValue;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    // Layout size identical to 120px HTML
    const double size = 120.0;

    // Create 8 particles
    final particles = List.generate(8, (index) {
      // Calculate delay fraction
      // According to CSS, duration is 1.5s, each delayed by 0.18s
      // 0.18/1.5 = 0.12
      final delayFraction = index * 0.12;

      // Compute effective time for this particle (0 to 1)
      double t = (pulseValue - delayFraction) % 1.0;
      if (t < 0) t += 1.0;

      // Triangle pulse value: 0 -> 1 -> 0
      double phase = t <= 0.5 ? (t * 2) : (2 - (t * 2));

      return _Particle(index: index, phase: phase);
    });

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Underlying large purple glow (from HTML background blur)
          Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Center core tiny glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryPurple.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Rotating particles
          Transform.rotate(
            angle: rotationValue * 2 * math.pi,
            child: Stack(children: particles),
          ),
        ],
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({required this.index, required this.phase});

  final int index;
  final double phase;

  @override
  Widget build(BuildContext context) {
    // Calculate angle for this index: 8 items -> 45 degrees step -> pi/4
    // Start top -> subtract pi/2
    final double angle = (index * math.pi / 4) - (math.pi / 2);

    // Radius of the circle (120px / 2 = 60). Radius to center of 12px particle is about 54.
    const double radius = 54.0;

    final double dx = math.cos(angle) * radius;
    final double dy = math.sin(angle) * radius;

    final double scale = 0.6 + (0.6 * phase); // 0.6 -> 1.2
    final double opacity =
        0.3 + (0.7 * phase); // Adjusted slightly for flutter visual punch

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _primaryPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryPurple.withValues(alpha: 0.8),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
