class WeatherSnapshot {
  const WeatherSnapshot({
    required this.locationName,
    required this.tempC,
    required this.conditionText,
    required this.iconUrl,
    required this.fetchedAt,
  });

  final String locationName;
  final num tempC;
  final String conditionText;
  final String iconUrl;
  final DateTime fetchedAt;
}

