import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'universal_loading_view.dart';

class AsyncStateView<T> extends StatefulWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.useUniversalLoading = false,
    this.loadingMessage = 'Preparing your daily path',
    this.loadingProgress,
    this.loadingIcon = Icons.bedtime_rounded,
    this.showLoadingPercentage = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final bool useUniversalLoading;
  final String loadingMessage;
  final double? loadingProgress;
  final IconData loadingIcon;
  final bool showLoadingPercentage;

  @override
  State<AsyncStateView<T>> createState() => _AsyncStateViewState<T>();
}

class _AsyncStateViewState<T> extends State<AsyncStateView<T>> {
  static const Duration _completionHoldDuration = Duration(milliseconds: 250);

  Timer? _completionTimer;
  bool _isCompleting = false;

  @override
  void didUpdateWidget(covariant AsyncStateView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.useUniversalLoading) {
      _cancelCompletionTransition(shouldRebuild: _isCompleting);
      return;
    }

    final wasLoading = oldWidget.value.isLoading;
    final isLoading = widget.value.isLoading;

    if (wasLoading && !isLoading) {
      _startCompletionTransition();
      return;
    }

    if (isLoading && _isCompleting) {
      _cancelCompletionTransition(shouldRebuild: true);
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  void _startCompletionTransition() {
    _completionTimer?.cancel();
    if (!_isCompleting) {
      setState(() {
        _isCompleting = true;
      });
    }
    _completionTimer = Timer(_completionHoldDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompleting = false;
      });
      _completionTimer = null;
    });
  }

  void _cancelCompletionTransition({required bool shouldRebuild}) {
    _completionTimer?.cancel();
    _completionTimer = null;
    if (!shouldRebuild) {
      _isCompleting = false;
      return;
    }
    setState(() {
      _isCompleting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useUniversalLoading &&
        (widget.value.isLoading || _isCompleting)) {
      final progress = widget.value.isLoading ? widget.loadingProgress : 1.0;
      return SizedBox.expand(
        child: UniversalLoadingView(
          message: widget.loadingMessage,
          progress: progress,
          primaryIcon: widget.loadingIcon,
          showPercentage: widget.showLoadingPercentage,
        ),
      );
    }

    return widget.value.when(
      data: widget.builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terjadi kendala: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: widget.onRetry,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
