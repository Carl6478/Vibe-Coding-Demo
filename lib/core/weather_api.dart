import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/weather_snapshot.dart';

class WeatherApi {
  WeatherApi({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  static String _locationQuery() {
    final q = dotenv.env['WEATHER_LOCATION']?.trim();
    if (q == null || q.isEmpty) {
      return 'auto:ip';
    }
    return q;
  }

  Future<WeatherSnapshot> fetchCurrent() async {
    final q = _locationQuery();

    final res = await _supabaseClient.functions.invoke(
      'weather',
      body: {'q': q},
    );

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected weather function response.');
    }

    final locationName = (data['locationName'] as String?)?.trim();
    final tempC = data['tempC'] as num?;
    final conditionText = (data['conditionText'] as String?)?.trim();
    final iconUrl = (data['iconUrl'] as String?)?.trim();

    if (locationName == null || locationName.isEmpty) {
      throw const FormatException('Weather response locationName missing.');
    }
    if (tempC == null) {
      throw const FormatException('Weather response tempC missing.');
    }
    if (conditionText == null || conditionText.isEmpty) {
      throw const FormatException('Weather response conditionText missing.');
    }
    if (iconUrl == null || iconUrl.isEmpty) {
      throw const FormatException('Weather response iconUrl missing.');
    }

    return WeatherSnapshot(
      locationName: locationName,
      tempC: tempC,
      conditionText: conditionText,
      iconUrl: iconUrl,
      fetchedAt: DateTime.now(),
    );
  }
}

