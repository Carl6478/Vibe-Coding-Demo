import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/weather_api.dart';
import '../models/weather_snapshot.dart';

final weatherApiProvider = Provider<WeatherApi>((ref) {
  return WeatherApi(supabaseClient: Supabase.instance.client);
});

final currentWeatherProvider = FutureProvider.autoDispose<WeatherSnapshot>((ref) async {
  final api = ref.watch(weatherApiProvider);
  return api.fetchCurrent();
});

