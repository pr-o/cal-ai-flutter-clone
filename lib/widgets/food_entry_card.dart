import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A dismissible food log entry card.
///
/// Shows an optional photo thumbnail on the left, food name + macro row
/// in the center/right, and kcal on the far right. Swipe left to delete.
class FoodEntryCard extends StatelessWidget {
  const FoodEntryCard({
    super.key,
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.onDismissed,
    this.imageUrl,
    this.loggedAt,
  });

  final int id;
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final VoidCallback onDismissed;

  /// Optional remote image URL for the food photo.
  final String? imageUrl;

  /// Optional time string (e.g. "12:46 PM").
  final String? loggedAt;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const _ThumbPlaceholder(),
                  errorWidget: (context, url, error) =>
                      const _ThumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              const _ThumbPlaceholder(),
              const SizedBox(width: 12),
            ],
            // Name + macros
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (loggedAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          loggedAt!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MacroChip(
                        label: '${proteinG.round()}g P',
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 6),
                      _MacroChip(
                        label: '${carbsG.round()}g C',
                        color: const Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 6),
                      _MacroChip(
                        label: '${fatG.round()}g F',
                        color: const Color(0xFF4A9EFF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Calories
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: Color(0xFFFF5500)),
                Text(
                  '$calories',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'kcal',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.restaurant_outlined,
        size: 24,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
