import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.color = Colors.amber,
    this.maxRating = 5,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final iconIndex = index + 1;
        IconData icon;
        if (rating >= iconIndex) {
          icon = Icons.star;
        } else if (rating >= iconIndex - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(iconIndex) : null,
          child: Icon(
            icon,
            size: size,
            color: color,
          ),
        );
      }),
    );
  }
}

class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> starCounts;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.starCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: aggregate score
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            StarRatingWidget(rating: averageRating, size: 16),
            const SizedBox(height: 4),
            Text(
              '$totalRatings ratings',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Right column: horizontal bars
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = starCounts[star] ?? 0;
              final pct = totalRatings > 0 ? count / totalRatings : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.amber,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
