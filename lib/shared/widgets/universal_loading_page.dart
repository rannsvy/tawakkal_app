import 'package:flutter/material.dart';

import 'universal_loading_view.dart';

class UniversalLoadingPage extends StatelessWidget {
  const UniversalLoadingPage({
    super.key,
    this.message = 'Preparing your daily path',
    this.progress,
    this.primaryIcon = Icons.bedtime_rounded,
    this.showPercentage = true,
  });

  final String message;
  final double? progress;
  final IconData primaryIcon;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: UniversalLoadingView(
        message: message,
        progress: progress,
        primaryIcon: primaryIcon,
        showPercentage: showPercentage,
      ),
    );
  }
}
