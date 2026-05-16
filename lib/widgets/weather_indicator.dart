import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';

class WeatherIndicator extends ConsumerWidget {
  const WeatherIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(currentWeatherProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return weather.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      error: (_, stackTrace) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          Icons.cloud_off,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      data: (snapshot) {
        final temp = snapshot.tempC.toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Tooltip(
            message: '${snapshot.locationName}: ${snapshot.conditionText}, $temp°C',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  snapshot.iconUrl,
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.cloud,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$temp°C',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
