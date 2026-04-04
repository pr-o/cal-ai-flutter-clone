import 'package:flutter/material.dart';

/// Wraps onboarding screen content with a back arrow, thin progress bar,
/// and safe-area padding matching the Cal AI onboarding design.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.child,
    this.onBack,
  });

  /// Current step index (1-based).
  final int step;
  final int totalSteps;
  final Widget child;

  /// Override back behaviour; defaults to [Navigator.pop].
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: back button + progress bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _BackButton(onBack: onBack ?? () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back, size: 20, color: cs.onSurface),
      ),
    );
  }
}
